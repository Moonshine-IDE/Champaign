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
import sys.thread.Mutex;
import sys.thread.Thread;

#if ( CHAMPAIGN_DEBUG || CHAMPAIGN_VERBOSE )
import champaign.core.logging.Logger;
#end

using Lambda;

@:allow( champaign.cpp.network )
class Pinger {

	static final _defaultPacketSize:Int = 56;

	static public var onPingEvent( default, null ):List<(String, PingEvent)->Void> = new List();
	static public var threadEventLoopInterval:Int = 1;

	static var _canLimbo:Bool = true;
	static var _canRead:Bool;
	static var _canWrite:Bool = true;
	static var _delay:Int = 1000;
	static var _eventProcessigThread:Thread;
	static var _events:Deque<PingSocketEvent>;
	static var _instance:Pinger;
	static var _limboPingObjects:List<PingObject> = new List();
	static var _limboThread:Thread;
	static var _mutex:Mutex;
	static var _paused:Bool = false;
	static var _pingObjectMap:Map<Int, PingObject> = [];
	static var _port:Int;
	static var _readBuffer:Bytes;
	static var _readMutex:Mutex = new Mutex();
	static var _readThread:Thread;
	static var _readyPingObjects:Deque<PingObject> = new Deque();
	static var _socket:Dynamic;
	static var _useBlockingSockets:Bool = true;
	static var _useSingleSocketForWriting:Bool = true;
	static var _writeMutex:Mutex = new Mutex();
	static var _writeThread:Thread;
	static var _writtenPingObjects:Map<Int, PingObject> = [];

	static public function setDelay( delay:Int ) {

		for ( po in _pingObjectMap ) po.setDelay( delay );

	}

	static public function startPing( address:String, count:Int = 1, timeout:Int = 2000, delay:Int = 1000 ) {

		if ( _events == null ) _events = new Deque();
		if ( _mutex == null ) _mutex = new Mutex();

		if ( _socket == null ) {

			_readBuffer = Bytes.alloc( 84 );
			_createSocket();

		}

		_mutex.acquire();
		var po = new PingObject( address, count, timeout, delay, ( _useSingleSocketForWriting ) ? _socket : null );
		_pingObjectMap.set( po.address.host, po );
		_readyPingObjects.add( po );
		_mutex.release();

		if ( _eventProcessigThread == null ) {

			_createThreads();

		}

	}

	static public function startPings( addresses:Array<String>, count:Int = 1, timeout:Int = 2000, delay:Int = 1000 ) {

		if ( _events == null ) _events = new Deque();
		if ( _mutex == null ) _mutex = new Mutex();

		_mutex.acquire();
		_paused = true;

		if ( _socket == null ) {

			_readBuffer = Bytes.alloc( 84 );
			_createSocket();

		}

		for ( a in addresses ) {

			var po = new PingObject( a, count, timeout, delay, ( _useSingleSocketForWriting ) ? _socket : null  );
			_pingObjectMap.set( po.address.host, po );
			_readyPingObjects.add( po );

		}

		_paused = false;
		_mutex.release();

		if ( _eventProcessigThread == null ) {

			_createThreads();

		}

	}

	static public function stopAllPings() {

		for ( po in _pingObjectMap ) po.shutdown = true;
		_pingObjectMap.clear();

	}

	static public function stopPing( address:String ):Bool {

		for ( po in _pingObjectMap )

			if ( po.hostname == address ) {

				po.shutdown = true;
				return _pingObjectMap.remove( po.address.host );

			}

		return false;

	}

	static function _createEventProcessingThread() {

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Event processing thread created' );
		#end

		while( true ) {

			var e:PingSocketEvent = _events.pop( true );
			if ( e.shutdown ) break;
			for ( f in onPingEvent ) f( e.address, e.event );

		}

		_destroyThreads();
		_destroySocket();

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Event processing thread shutting down' );
		#end

	}

	static function _createLimboThread() {

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Limbo thread created' );
		#end

		while( _canLimbo ) {

			var t = Sys.time() * 1000;

			#if CHAMPAIGN_VERBOSE
			Logger.verbose( '[LimboThread] Processing... LimboPingObjects: ${_limboPingObjects.length}, WrittenPingObjects: ${_writtenPingObjects.count()}, TotalPingObjects: ${_pingObjectMap.count()}' );
			#end

			// Checking timed out PingObjects
			
			if ( _writtenPingObjects != null ) for ( po in _writtenPingObjects ) {

				if ( po.isTimedOut( t ) ) {

					_events.add( { address: po.hostname, event: PingEvent.PingTimeout } );

					_mutex.acquire();
					po.written = false;
					po.bumpPingCount();
					_writtenPingObjects.remove( po.address.host );

					if ( po.pingFinished() ) {

						// No more pings needed
						_events.add( { address: po.hostname, event: PingEvent.PingStop } );
						_pingObjectMap.remove( po.address.host );
						_limboPingObjects.remove( po );

						if ( _pingObjectMap.count() == 0 ) {

							_events.add( { shutdown: true } );
							_canLimbo = false;

						}

						#if CHAMPAIGN_VERBOSE
						Logger.verbose( '[LimboThread] Remaining PingObjects: ${_pingObjectMap.count()}' );
						#end

					} else {

						_readyPingObjects.add( po );

					}

					_mutex.release();

				}

			}

			for ( po in _limboPingObjects ) {

				// Shut down thread?
				if ( po.hostname == null ) {
				
					_canLimbo = false;
					break;

				}

				if ( po.canPing( t ) ) {
					
					_mutex.acquire();
					_limboPingObjects.remove( po );
					_readyPingObjects.add( po );
					_mutex.release();

				}

				if ( po.shutdown ) {

					_mutex.acquire();
					_limboPingObjects.remove( po );
					_mutex.release();

				}

			}

			Sys.sleep( _delay / 1000 );

		}

		_mutex.acquire();
		_limboPingObjects.clear();
		_mutex.release();

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Limbo thread shutting down' );
		#end

	}

	static function _createReadThread() {

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Reading thread created' );
		#end

		while( _canRead ) {

			try {

				#if CHAMPAIGN_VERBOSE
				Logger.verbose( 'Reading socket...');
				#end
				var result = NativeICMPSocket.socket_recv2( _socket, _readBuffer.getData() );
				#if CHAMPAIGN_VERBOSE
				Logger.verbose( 'Data ${_readBuffer.length} ${_readBuffer.toHex()}');
				#end

				#if CHAMPAIGN_VERBOSE
				#end
				var packet = PingPacket.fromBytes( _readBuffer );

				if ( packet == null ) {

					// Not our packet
					#if CHAMPAIGN_VERBOSE
					Logger.warning( 'Invalid packet');
					#end
					break;

				}

				#if CHAMPAIGN_VERBOSE
				Logger.verbose( 'Packet ${packet}, type: ${packet.type}, code: ${packet.code}, checksum: ${packet.checksum}, sequenceNumber: ${packet.sequenceNumber}, identifier: ${packet.identifier}, header: ${packet.header}, ipVersion: ${packet.header.ipVersion}, flags: ${packet.header.flags}, headerChecksum: ${packet.header.headerChecksum}, headerLength: ${packet.header.headerLength}, identification: ${packet.header.identification}, protocol: ${packet.header.protocol}, sourceAddress: ${packet.header.getSourceIP()}, destinationAddress: ${packet.header.getDestinationIP()}, timeToLive: ${packet.header.timeToLive}, totalLength: ${packet.header.totalLength}, data: ${packet.data}' );
				#end

				var po = _writtenPingObjects.get( packet.header.sourceAddress );

				#if CHAMPAIGN_VERBOSE
				Logger.verbose( 'Matching PingObject: ${po}' );
				#end

				if ( po != null ) {

					_mutex.acquire();
					_writtenPingObjects.remove( packet.header.sourceAddress );

					var e:PingSocketEvent = { address: po.hostname };
					po.written = false;

					if ( packet.type == 0 ) {

						po.readTime = Sys.time() * 1000;
						e.event = PingEvent.Ping( Std.int( po.readTime - po.writeTime ) );

					} else if ( packet.type == 3 ) {

						e.event = PingEvent.PingFailed;

					} else {

						// Something else received
						e.event = PingEvent.PingFailed;

					}

					_events.add( e );
					po.bumpPingCount();

					if ( po.pingFinished() ) {

						// No more pings needed
						_events.add( { address: po.hostname, event: PingEvent.PingStop } );
						_pingObjectMap.remove( packet.header.sourceAddress );
						var c = _pingObjectMap.count();

						#if CHAMPAIGN_VERBOSE
						Logger.verbose( '[ReadingThread] Remaining PingObjects: ${c}' );
						#end

						if ( c == 0 ) {

							_events.add( { shutdown: true } );
							_canRead = false;

						}

					} else {

						// Put the PingObject in Limbo, waiting for the next write cycle
						_limboPingObjects.add( po );

					}

					_mutex.release();

				}

			} catch ( e ) {

				// Nothing to read from the socket
				_mutex.release();

			}

			// It's useful to slow it down a little
			if ( !_useBlockingSockets ) Sys.sleep( threadEventLoopInterval / 1000 );

		}

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Reading thread shutting down' );
		#end

	}

	static function _createWriteThread() {

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Writing thread created' );
		#end

		while( true ) {

			var po = _readyPingObjects.pop( true );

			// Shut down thread?
			if ( po.hostname == null ) break;

			_mutex.acquire();

			// See if socket is awailable to write
			var arr = NativeICMPSocket.socket_select( [], [ po.socket ], [], 10);

			if ( arr != null && arr[ 1 ] != null && arr[ 1 ][ 0 ] == po.socket ) {

				// Let's start writing
				try {

					#if CHAMPAIGN_VERBOSE
					Logger.verbose( 'Sending packet to ${po.hostname}...' );
					#end
					NativeICMPSocket.socket_send_to( po.socket, po.byteData, po.address, po.pingId, po.id );
					#if CHAMPAIGN_VERBOSE
					Logger.verbose( '...sent' );
					#end
					po.writeTime = Sys.time() * 1000;
					po.written = true;
					if ( !po.shutdown ) _writtenPingObjects.set( po.address.host, po );

				} catch ( e:Eof ) {

					// Socket EOF
					#if CHAMPAIGN_DEBUG
					Logger.warning( 'Socket EOF' );
					#end
					// Put the PingObject back to deque
					if ( !po.shutdown ) _readyPingObjects.push( po );

				} catch ( e ) {
	
					// Socket blocked, can't send data
					#if CHAMPAIGN_DEBUG
					Logger.warning( 'Socket blocked on address ${po.hostname}' );
					#end
					_events.add( { address: po.hostname, event: PingEvent.PingError } );
					po.writeTime = Sys.time() * 1000;
					if ( !po.shutdown ) _limboPingObjects.add( po );

				}

			} else {

				// Socket is not available yet, put the PingObject back to deque
				if ( !po.shutdown ) _readyPingObjects.push( po );

			}

			_mutex.release();

			// It's useful to slow it down a little
			//Sys.sleep( threadEventLoopInterval / 1000 );

		}

		// Removing all remaining PingObjects from deque
		while ( true ) {

			var po = _readyPingObjects.pop( false );
			if ( po == null ) break;

		}

		_readyPingObjects = null;

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Writing thread shutting down' );
		#end

	}

	static function _createSocket() {

		_socket = NativeICMPSocket.socket_new( true );
		NativeICMPSocket.socket_set_blocking( _socket, _useBlockingSockets );
		_port = Std.random( 55535 ) + 10000;
		//var localhost = new Host( Host.localhost() );
		//NativeICMPSocket.socket_bind( _socket, localhost.ip, _port );

	}

	static function _createThreads() {

		_eventProcessigThread = Thread.create( _createEventProcessingThread );
		_canRead = true;
		_writeThread = Thread.create( _createWriteThread );
		_readThread = Thread.create( _createReadThread );
		_limboThread = Thread.create( _createLimboThread );

	}

	static function _destroySocket() {

		NativeICMPSocket.socket_close( _socket );
		_socket = null;

	}

	static function _destroyThreads() {

		_mutex.acquire();

		_canRead = false;
		_canLimbo = false;
		_eventProcessigThread = null;

		_mutex.release();

		var nullObject = new PingObject( null, 0, 0, 0 );
		_limboPingObjects.add( nullObject );
		_readyPingObjects.add( nullObject );

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
	var readTime:Float;
	var shutdown:Bool;
	var socket( default, null ):Dynamic;
	var stopped( default, null ):Bool;
	var timeout( default, null ):Int;
	var writeTime:Null<Float> = 0;
	var written:Bool;

	function new( hostname:String, count:Int, timeout:Int, delay:Int, ?socket:Dynamic ) {

		this.hostname = hostname;

		// Notify threads and event loops that they should be shut down
		if ( hostname == null ) return;

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

		if ( socket == null ) {

			this.socket = NativeICMPSocket.socket_new( true );
			NativeICMPSocket.socket_set_blocking( this.socket, Pinger._useBlockingSockets );

		} else {

			this.socket = socket;

		}

	}

	function bumpPingCount() {

		currentCount++;
		this.pingId++;
		if ( this.pingId > 0xFFFF ) this.pingId = 0;

	}

	inline function canPing( time:Float ):Bool {

		return !written && !shutdown && time > this.writeTime + this.delay;

	}

	function destroy() {

		if ( socket != null ) NativeICMPSocket.socket_close( socket );
		socket = null;

	}

	inline function isTimedOut( time:Float ):Bool {

		return this.written && time > this.writeTime + this.timeout;

	}

	inline function pingFinished():Bool {

		if ( this.shutdown ) return true;
		if ( this.count == 0 ) return false;
		return this.currentCount >= this.count;

	}

	function setDelay( delay:Int ) {

		this.delay = delay;

	}

	function stop() {

		stopped = true;

	}

	function toString() {

		return '[PingObject:${hostname}]';

	}

}

class PingPacketHeader {

	static public function fromBytes( bytes:Bytes ):PingPacketHeader {

		var p = new PingPacketHeader();

		var versionByte:Int = bytes.get( 0 );
		p.ipVersion = versionByte >> 4;
		p.headerLength = versionByte << 28 >> 24;
		if ( p.headerLength == 0 ) return null;
		p.totalLength = bytes.getUInt16( 2 );
		if ( SysTools.isWindows() ) p.totalLength = p.totalLength >> 8;
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
		p.data = Bytes.alloc( SysTools.isWindows() ? 64 - 28 : 64 - 8 );
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
