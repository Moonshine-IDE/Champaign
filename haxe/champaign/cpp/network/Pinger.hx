package champaign.cpp.network;

import champaign.core.tools.StrTools;
import champaign.cpp.externs.NativeICMPSocket;
import champaign.sys.SysTools;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.Eof;
import sys.net.Address;
import sys.net.Host;
import sys.thread.Deque;
import sys.thread.EventLoop.EventHandler;
import sys.thread.Mutex;
import sys.thread.Thread;

#if ( CHAMPAIGN_DEBUG || CHAMPAIGN_VERBOSE )
import champaign.core.logging.Logger;
#end

class Pinger {

    static final _defaultPacketSize:Int = 56;

    static public var onPingEvent( default, null ):List<(String, PingEvent)->Void> = new List();
    static public var threadEventLoopInterval:Int = 0;

    static var _deque:Deque<PingSocketEvent>;
    static var _eventProcessigThread:Thread;
    static var _instance:Pinger;
    static var _mixedThread:Thread;
    static var _mixedThreadEventHandler:EventHandler;
    static var _mutex:Mutex;
    static var _pingObjectMap:Map<Int, PingObject> = [];
    static var _port:Int;
    static var _readBuffer:Bytes;
    static var _socket:Dynamic;

    static public function startPing( address:String, count:Int = 1, timeout:Int = 2000, delay:Int = 1000 ) {

        var po = new PingObject( address, count, timeout, delay );
        _pingObjectMap.set( po.address.host, po );

        if ( _socket == null ) {

            _readBuffer = Bytes.alloc( 84 );
			_createSocket();
			_createThreads();

        }

    }

    static public function stopPing( address:String ):Bool {

        for ( po in _pingObjectMap )
            if ( po.hostname == address )
                return _pingObjectMap.remove( po.address.host );

        return false;

    }

    static function _createEventProcessingThread() {

        while( true ) {

            var e:PingSocketEvent = _deque.pop( true );
            if ( e.shutdown ) break;
            for ( f in onPingEvent ) f( e.address, e.event );

        }

		_destroyThreads();
		_destroySocket();

	}

    static function _createMixedThread() {

        _mutex.acquire();
        _mixedThreadEventHandler = Thread.current().events.repeat( _createMixedThreadEventLoop, threadEventLoopInterval );
        _mutex.release();

    }

    static function _createMixedThreadEventLoop() {

        _mutex.acquire();

        if ( Lambda.count( _pingObjectMap ) == 0 ) {
		
			_mutex.release();
			_deque.add( { shutdown: true } );
			return;

		}

        var arr = NativeICMPSocket.socket_select( [ _socket ], [ _socket ], [], 0);

        if ( arr != null ) {

            var toRead:Array<Dynamic> = arr[ 0 ];
            var toWrite:Array<Dynamic> = arr[ 1 ];

            // To read
            
            if ( toRead != null && toRead.length > 0 ) {

                var result:Int = 1;

                while ( result > 0 ) {

                    try {

                        result = NativeICMPSocket.socket_recv2( _socket, _readBuffer.getData() );
                        #if CHAMPAIGN_DEBUG
                        Logger.debug( 'Data ${_readBuffer.length} ${_readBuffer.toHex()}');
                        #end

                        var packet = PingPacket.fromBytes( _readBuffer );
                        if ( packet == null ) break; // Not our packet

                        #if CHAMPAIGN_VERBOSE
                        Logger.verbose( 'Packet ${packet}, type: ${packet.type}, code: ${packet.code}, checksum: ${packet.checksum}, sequenceNumber: ${packet.sequenceNumber}, identifier: ${packet.identifier}, header: ${packet.header}, ipVersion: ${packet.header.ipVersion}, flags: ${packet.header.flags}, headerChecksum: ${packet.header.headerChecksum}, headerLength: ${packet.header.headerLength}, identification: ${packet.header.identification}, protocol: ${packet.header.protocol}, sourceAddress: ${packet.header.getSourceIP()}, destinationAddress: ${packet.header.getDestinationIP()}, timeToLive: ${packet.header.timeToLive}, totalLength: ${packet.header.totalLength}, data: ${packet.data}' );
                        #end

                        var po = _pingObjectMap.get( packet.header.sourceAddress );

                        if ( po != null ) {

                            var e:PingSocketEvent = { address: po.hostname };

                            if ( packet.type == 0 ) {

                                po.readTime = Sys.time() * 1000;
                                e.event = PingEvent.Ping( Std.int( po.readTime - po.writeTime ) );

                            } else if ( packet.type == 3 ) {

                                e.event = PingEvent.PingFailed;

                            } else {

                                // Something else received
                                e.event = PingEvent.PingFailed;

                            }

                            _deque.add( e );
                            po.read = true;
                            po.written = false;
                            po.bumpPingCount();

                        }

                    } catch ( e ) {

                        // Nothing to read from the socket
                        result = 0;

                    }

                }

            }

            // To write
            if ( toWrite != null && toWrite.length > 0 ) {

                for ( po in _pingObjectMap ) {

                    if ( po.readyToWrite() ) {

                        try {

                            po.writeTime = Sys.time() * 1000;
                            NativeICMPSocket.socket_send_to( _socket, po.byteData, po.address, po.pingId, po.id );
                            po.written = true;

                        } catch ( e:Eof ) {

							// Socket EOF

                        } catch ( e ) {

							// Socket blocked, Can't write yet

                        }

                    }

                }
                
            }

        }

        // Checking timed out hosts

		var t = Sys.time() * 1000;

        for ( po in _pingObjectMap ) {

            if ( po.written ) {

                if ( t > po.writeTime + po.timeout ) {

                    var e:PingSocketEvent = { address: po.hostname, event: PingEvent.PingTimeout };
                    _deque.add( e );
                    po.written = false;
                    po.read = true;
                    po.bumpPingCount();

                }

            }

            // No more pings on this host

            if ( po.count != 0 && po.currentCount >= po.count ) {

                var e:PingSocketEvent = { address: po.hostname, event: PingEvent.PingStop };
                _deque.add( e );
                _pingObjectMap.remove( po.address.host );

            }

        }

        _mutex.release();

    }

	static function _createSocket() {

		_socket = NativeICMPSocket.socket_new( true );
		NativeICMPSocket.socket_set_blocking( _socket, false );
		_port = Std.random( 55535 ) + 10000;
		//var localhost = new Host( Host.localhost() );
		//NativeICMPSocket.socket_bind( _socket, localhost.ip, _port );

	}

	static function _createThreads() {

		_mutex = new Mutex();
		_deque = new Deque();
		_eventProcessigThread = Thread.create( _createEventProcessingThread );
		_mixedThread = Thread.createWithEventLoop( _createMixedThread );

	}

	static function _destroySocket() {

		NativeICMPSocket.socket_close( _socket );
		_socket = null;

	}

	static function _destroyThreads() {

		_mutex.acquire();

		if ( _mixedThreadEventHandler != null ) _mixedThread.events.cancel( _mixedThreadEventHandler );
		_mixedThreadEventHandler = null;
		_mixedThread = null;
		_eventProcessigThread = null;

        _mutex.release();

	}

}

@:allow( champaign.cpp.network )
@:noDoc
private class PingObject {

    static final chars = '01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    static final defaultPacketSize:Int = 56;

    var address( default, null ):Address;
    var byteData( default, null ):BytesData;
    var bytes( default, null ):Bytes;
    var count( default, null ):Int;
    var currentCount( default, null ):Int;
    var delay( default, null ):Int;
    var hostname( default, null ):String;
    var id( default, null ):Int;
    var pingId( default, null ):Int;
    var read:Bool = true;
    var readTime:Float;
    var timeout( default, null ):Int;
    var writeTime:Float;
    var written:Bool;

    function new( hostname:String, count:Int, timeout:Int, delay:Int ) {

        this.hostname = hostname;
        var host = new Host( hostname );
        this.address = new Address();
        this.address.host = host.ip;

        this.count = count;
        this.timeout = timeout;
        this.delay = delay;
        this.currentCount = 0;
        this.id = Std.random( 0xFFFF );
        this.pingId = 0;

        var data:String = '';
		for ( i in 0...defaultPacketSize ) data += chars.charAt( Std.random( chars.length ) );
		byteData = Bytes.ofString( "00000000" + data ).getData();
		// Filling in ICMP Header
		byteData[0] = 8;
		byteData[1] = 0;
		byteData[2] = 0;
		byteData[3] = 0;
		byteData[4] = this.id;
		byteData[5] = this.id >> 8;
		byteData[6] = 0;
		byteData[7] = 0;

    }

    function bumpPingCount() {

        currentCount++;
        this.pingId++;
        if ( this.pingId > 0xFFFF ) this.pingId = 0;

    }

    function readyToRead() {

        return !read && written;

    }

    function readyToWrite() {

        return read && !written && ( Sys.time() * 1000 >= ( writeTime + delay ) ) && ( count == 0 || currentCount < count );

    }

}

class PingPacketHeader {

	static public function fromBytes( bytes:Bytes ):PingPacketHeader {

		var p = new PingPacketHeader();

		var versionByte = bytes.get( 0 );
		p.ipVersion = versionByte >> 4;
		p.headerLength = versionByte << 28 >> 26;
		if ( p.headerLength == 0 ) return null;
		p.totalLength = bytes.getUInt16( 2 );
		if ( SysTools.isWindows() ) p.totalLength = p.totalLength >> 8;
		if ( p.totalLength > 84 ) return null;
		p.identification = bytes.getUInt16( 4 );
		p.flags = bytes.get( 6 );
		p.timeToLive = bytes.get( 8 );
		p.protocol = bytes.get( 9 );
		p.headerChecksum = bytes.getUInt16( 10 );
		p.sourceAddress = bytes.getInt32( 12 );
		p.destinationAddress = bytes.getInt32( 16 );
		return p;

	}

	public var destinationAddress( default, null ):Int;
	public var headerChecksum( default, null ):Int;
	public var flags( default, null ):Int;
	public var headerLength( default, null ):Int;
	public var identification( default, null ):Int;
	public var ipVersion( default, null ):Int;
	public var protocol( default, null ):Int;
	public var sourceAddress( default, null ):Int;
	public var timeToLive( default, null ):Int;
	public var totalLength( default, null ):Int;

	function new() { }

	public function getDestinationIP():String {

		return StrTools.intToIPAddress( destinationAddress );

	}

	public function getSourceIP():String {

		return StrTools.intToIPAddress( sourceAddress );

	}

}

class PingPacket {

	static public function fromBytes( bytes:Bytes ):PingPacket {

		if ( bytes.length < 84 ) return null;

		var p = new PingPacket();
		var b = Bytes.alloc( 20 );
		b.blit( 0, bytes, 0, 20 );
		p.header = PingPacketHeader.fromBytes( b );
		if ( p.header == null ) return null;
		p.type = bytes.get( 20 );
		p.code = bytes.get( 21 );
		p.checksum = bytes.getUInt16( 22 );
		p.identifier = bytes.getUInt16( 24 );
		p.sequenceNumber = bytes.getUInt16( 26 );
		p.data = Bytes.alloc( SysTools.isWindows() ? p.header.totalLength - 28 : p.header.totalLength - 8 );
		p.data.blit( 0, bytes, 28, p.data.length );
		return p;

	}

	public var checksum( default, null ):Int;
	public var code( default, null ):Int;
	public var data( default, null ):Bytes;
	public var header( default, null ):PingPacketHeader;
	public var identifier( default, null ):Int;
	public var sequenceNumber( default, null ):Int;
	public var type( default, null ):Int;

	function new() {}

}

enum PingEvent {

	/**
	 * The socket cannot connect to the host
	 */
	HostError;

	/**
	 * Ping (echo) response received in `time` (millisecs)
	 */
	Ping(time:Int);

	/**
	 * Ping error
	 */
	PingError;

	/**
	 * Ping failed
	 */
	PingFailed;

	/**
	 * Ping stopped. This usually occurs after the current ping count reaches the defined value or if the repeat cycle stops on error.
	 */
	PingStop;

	/**
	 * The socket did not receive a response in the given time
	 */
	PingTimeout;

}

private typedef PingSocketEvent = {

    ?event:PingEvent,
    ?shutdown:Bool,
    ?address:String,
    
}
