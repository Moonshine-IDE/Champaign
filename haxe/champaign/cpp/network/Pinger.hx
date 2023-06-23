package champaign.cpp.network;

import haxe.Exception;
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

using Lambda;
#if ( CHAMPAIGN_DEBUG || CHAMPAIGN_VERBOSE || LOG_CHAMPAIGN_EXCEPTION)
import champaign.core.logging.Logger;
#end


@:allow( champaign.cpp.network )
class Pinger {

	static final _defaultPacketSize:Int = 56;
	static final _defaultSettings:PingerSettings = {

		keepThreadsAlive: false,
		period: 1000,
		threadEventLoopInterval: 1,
		useBlockingSockets: false,
		useEventLoops: true,

	};

	static public var onPingEvent( default, null ):List<(String, PingEvent)->Void> = new List();
	static public var onStop( default, null ):List<Void->Void> = new List();

	static var _canWrite:Bool = true;
	static var _eventProcessigThread:Thread;
	static var _eventProcessigThreadFinished:Bool;
	static var _events:Deque<PingSocketEvent>;
	static var _instance:Pinger;
	static var _limboPingObjects:List<PingObject> = new List();
	static var _limboThread:Thread;
	static var _limboThreadFinished:Bool;
	static var _mutex:Mutex;
	static var _paused:Bool = false;
	static var _pingObjectMap:Map<Int, PingObject> = [];
	static var _port:Int;
	static var _readBuffer:Bytes;
	static var _readMutex:Mutex = new Mutex();
	static var _readThread:Thread;
	static var _readThreadFinished:Bool;
	static var _readyPingObjects:Deque<PingObject> = new Deque();
	static var _socket:Dynamic;
	static var _useSingleSocketForWriting:Bool = true;
	static var _writeMutex:Mutex = new Mutex();
	static var _writeThread:Thread;
	static var _writeThreadFinished:Bool;
	static var _writtenPingObjects:Map<Int, PingObject> = [];

	static var _limboThreadEventHandler:EventHandler;
	static var _readThreadEventHandler:EventHandler;
	static var _canLoopLimboThread:Bool = true;
	static var _canLoopReadThread:Bool = true;
	static var _initialized:Bool = false;

	static public function init( settings:PingerSettings ) {

		if ( _initialized ) return;

		if ( settings.keepThreadsAlive != null ) _defaultSettings.keepThreadsAlive = settings.keepThreadsAlive;
		if ( settings.period != null && settings.period > 0 ) _defaultSettings.period = settings.period;
		if ( settings.threadEventLoopInterval != null && settings.threadEventLoopInterval > 0 ) _defaultSettings.threadEventLoopInterval = settings.threadEventLoopInterval;
		if ( settings.useBlockingSockets != null ) _defaultSettings.useBlockingSockets = settings.useBlockingSockets;
		if ( settings.useEventLoops != null ) _defaultSettings.useEventLoops = settings.useEventLoops;

		_initialized = true;

	}

	static public function setDelay( delay:Int ) {

		try
		{
			for ( po in _pingObjectMap ) po.setDelay( delay );
		}
		catch (e)
		{
			_logException(e);
		}
	}

	static public function logFakeExecption()
	{
		#if LOG_CHAMPAIGN_EXCEPTION
		Logger.fatal('test log nothing to do');
		#end
	}

	static public function startPing( address:String, count:Int = 1, timeout:Int = 2000, delay:Int = 1000 ) {

		try
		{
			if ( _events == null ) _events = new Deque();
			if ( _mutex == null ) _mutex = new Mutex();

			if ( _socket == null ) {

				_readBuffer = Bytes.alloc( 84 );
				_createSocket();

			}

			_mutex.acquire();
			var po = new PingObject( address, count, timeout, delay, ( _useSingleSocketForWriting ) ? _socket : null );

			if ( !_pingObjectMap.exists( po.id ) ) {

				_pingObjectMap.set( po.id, po );
				_readyPingObjects.add( po );

			}
			
			_mutex.release();

			if ( _eventProcessigThread == null ) {

				_createThreads();

			}
		}
		catch (e)
		{
			_logException(e);
		}
	}

	static public function startPings( addresses:Array<String>, count:Int = 1, timeout:Int = 2000, delay:Int = 1000 ) {

		try
		{
			if ( _mutex == null ) _mutex = new Mutex();
			_mutex.acquire();

			if ( _events == null ) _events = new Deque();

			_paused = true;

			if ( _socket == null ) {

				_readBuffer = Bytes.alloc( 84 );
				_createSocket();

			}

			for ( a in addresses ) {

				var po = new PingObject( a, count, timeout, delay, ( _useSingleSocketForWriting ) ? _socket : null  );

				if ( !_pingObjectMap.exists( po.id ) ) {

					_pingObjectMap.set( po.id, po );
					_readyPingObjects.add( po );

				}

			}

			_paused = false;
			_mutex.release();

			if ( _eventProcessigThread == null ) {

				_createThreads();

			}			
		}
		catch (e)
		{
			_logException(e);
		}
	}

	static public function stopAllPings() {

		try
		{
			_mutex.acquire();
			for ( po in _pingObjectMap ) po.shutdown = true;
			_pingObjectMap.clear();
			_mutex.release();
		}	
		catch (e)
		{
			_logException(e);
		}
	}

	static public function stopPing( address:String ):Bool {

		for ( po in _pingObjectMap )

			if ( po.hostname == address ) {

				try
				{
					_mutex.acquire();
					po.shutdown = true;
					var b = _pingObjectMap.remove( po.id );
					_mutex.release();
					return b;
				}	
				catch (e)
				{
					_logException(e);
				}
			}

		return false;

	}

	static function _createEventProcessingThread() {

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Event processing thread created' );
		#end

		try
		{
			while ( true ) {

				var e:PingSocketEvent = null;
	
				// TODO
				// Deque.pop( true ) fails on Raspberry Pi Arm64 with 'Bus error'
				e = _events.pop( !SysTools.isRaspberryPi() );
				
				if ( e == null ) {
	
					Sys.sleep( _defaultSettings.threadEventLoopInterval / 1000 );
					continue;
	
				}
				
				if ( e.shutdown ) break;
				for ( f in onPingEvent ) f( e.address, e.event );
	
			}
	
			_destroyThreads();
	
			#if CHAMPAIGN_DEBUG
			Logger.debug( 'Event processing thread shutting down' );
			#end
	
			_threadFinished( Thread.current() );
		}
		catch (e)
		{
			_logException(e);
		}
	}

	static function _createLimboThread() {

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Limbo thread created' );
		#end
		
		_mutex.acquire();
		_limboThreadEventHandler = Thread.current().events.repeat( _createLimboThreadEventLoop, 1000 );
		_mutex.release();

	}

	static function _createLimboThreadEventLoop() {

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Limbo thread event loop created' );
		#end

		try
		{
			while( ( _defaultSettings.useEventLoops && _limboThreadEventHandler != null ) || ( !_defaultSettings.useEventLoops && _canLoopLimboThread ) ) {

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
						_writtenPingObjects.remove( po.id );
	
						if ( po.pingFinished() ) {
	
							// No more pings needed
							_events.add( { address: po.hostname, event: PingEvent.PingStop } );
							_pingObjectMap.remove( po.id );
	
							if ( _pingObjectMap.count() == 0 && !_defaultSettings.keepThreadsAlive ) {
	
								_events.add( { shutdown: true } );
	
							}
	
							#if CHAMPAIGN_VERBOSE
							Logger.verbose( '[LimboThread] Remaining PingObjects: ${_pingObjectMap.count()}' );
							#end
	
						} else {
	
							_limboPingObjects.add( po );
	
						}
	
						_mutex.release();
	
					}
	
				}
	
				for ( po in _limboPingObjects ) {
	
					// Shut down thread?
					if ( po.hostname == null ) {
					
						if ( _limboThreadEventHandler != null ) Thread.current().events.cancel( _limboThreadEventHandler );
						_limboThreadEventHandler = null;
						_canLoopLimboThread = false;
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
	
				Sys.sleep( _defaultSettings.period / 1000 );
	
			}
	
			_mutex.acquire();
			_limboPingObjects.clear();
			_mutex.release();
	
			#if CHAMPAIGN_DEBUG
			Logger.debug( 'Limbo thread shutting down' );
			#end
	
			_threadFinished( Thread.current() );
		}
		catch (e)
		{
			_logException(e);
		}
	}

	static function _createReadThread() {

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Reading thread created' );
		#end

		_mutex.acquire();
		_readThreadEventHandler = Thread.current().events.repeat( _createReadThreadEventLoop, ( _defaultSettings.useBlockingSockets ) ? 0 : _defaultSettings.threadEventLoopInterval );
		_mutex.release();

	}

	static function _createReadThreadEventLoop() {

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Reading thread event loop created' );
		#end

		try
		{
			while( ( _defaultSettings.useEventLoops && _readThreadEventHandler != null ) || ( !_defaultSettings.useEventLoops && _canLoopReadThread ) ) {

				var arr = NativeICMPSocket.socket_select( [ _socket ], [], [], 5);
	
				if( arr != null || arr[ 0 ] != null || arr[ 0 ].length > 0 ) {
	
					try {
	
						#if CHAMPAIGN_VERBOSE
						Logger.verbose( 'Reading socket...');
						#end
						var result = NativeICMPSocket.socket_recv2( _socket, _readBuffer.getData() );
						#if CHAMPAIGN_VERBOSE
						Logger.verbose( 'Data ${_readBuffer.length} ${_readBuffer.toHex()}');
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
						Logger.verbose( 'Packet ${packet}, type: ${packet.type}, code: ${packet.code}, checksum: ${packet.checksum}, sequenceNumber: ${packet.sequenceNumber}, identifier: ${packet.identifier}, header: ${packet.header}, ipVersion: ${packet.header.ipVersion}, flags: ${packet.header.flags}, headerChecksum: ${packet.header.headerChecksum}, headerLength: ${packet.header.headerLength}, identification: ${packet.header.identification}, protocol: ${packet.header.protocol}, sourceAddress: ${packet.header.getSourceIP()}, destinationAddress: ${packet.header.getDestinationIP()}, timeToLive: ${packet.header.timeToLive}, totalLength: ${packet.header.totalLength}, data: ${packet.data}, embeddedId: ${packet.embeddedId}' );
						#end
	
						var po = _writtenPingObjects.get( SysTools.isLinux() ? packet.embeddedId : packet.identifier );
	
						#if CHAMPAIGN_VERBOSE
						Logger.verbose( 'Matching PingObject: ${po}' );
						#end
	
						if ( po != null ) {
	
							_mutex.acquire();
							_writtenPingObjects.remove( po.id );
	
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
								_pingObjectMap.remove( po.id );
								var c = _pingObjectMap.count();
	
								#if CHAMPAIGN_VERBOSE
								Logger.verbose( '[ReadingThread] Remaining PingObjects: ${c}' );
								#end
	
								if ( c == 0 && !_defaultSettings.keepThreadsAlive ) {
	
									if ( _readThreadEventHandler != null ) Thread.current().events.cancel( _readThreadEventHandler );
									_readThreadEventHandler = null;
									_canLoopReadThread = false;
									_events.add( { shutdown: true } );
	
								}
	
							} else {
	
								// Put the PingObject in Limbo, waiting for the next write cycle
								_limboPingObjects.add( po );
	
							}
	
							_mutex.release();
	
						}
	
					} catch ( e ) {
	
						// Nothing to read from the socket
						if ( _pingObjectMap.count() == 0 && !_defaultSettings.keepThreadsAlive ) {
	
							if ( _readThreadEventHandler != null ) Thread.current().events.cancel( _readThreadEventHandler );
							_readThreadEventHandler = null;
							_canLoopReadThread = false;
							_events.add( { shutdown: true } );
	
						}
						_mutex.release();
	
					}
	
					if ( !_defaultSettings.useBlockingSockets ) Sys.sleep( _defaultSettings.threadEventLoopInterval / 1000 );
	
				} else {
	
					if ( ( _pingObjectMap == null || _pingObjectMap.count() == 0 ) && !_defaultSettings.keepThreadsAlive ) {
	
						if ( _readThreadEventHandler != null ) Thread.current().events.cancel( _readThreadEventHandler );
						_readThreadEventHandler = null;
						_canLoopReadThread = false;
						_events.add( { shutdown: true } );
	
					}
	
				}
	
			}
	
			#if CHAMPAIGN_DEBUG
			Logger.debug( 'Reading thread shutting down' );
			#end
	
			_threadFinished( Thread.current() );
		}
		catch (e)
		{
			_logException(e);
		}
	}

	static function _createWriteThread() {

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Writing thread created' );
		#end

		try
		{
			while( true ) {

				var po:PingObject = null;
	
				// TODO
				// Deque.pop( true ) fails on Raspberry Pi Arm64 with 'Bus error'
				po = _readyPingObjects.pop( !SysTools.isRaspberryPi() );
	
				if ( po == null ) {
	
					Sys.sleep( _defaultSettings.threadEventLoopInterval / 1000 );
					continue;
	
				}
	
				_mutex.acquire();
	
				// Shut down thread?
				if ( po.hostname == null ) {
	
					_mutex.release();
					break;
	
				}
	
				// See if socket is awailable to write
				var arr = NativeICMPSocket.socket_select( [], [ po.socket ], [], 10);
	
				if ( arr != null && arr[ 1 ] != null && arr[ 1 ][ 0 ] == po.socket ) {
	
					// Let's start writing
					try {
	
						#if CHAMPAIGN_VERBOSE
						Logger.verbose( 'Sending packet to ${po.hostname} ${po.address} ${po.pingId} ${po.id}...' );
						#end
						NativeICMPSocket.socket_send_to( po.socket, po.byteData, po.address, po.pingId, po.id );
						#if CHAMPAIGN_VERBOSE
						Logger.verbose( '...sent' );
						#end
						po.writeTime = Sys.time() * 1000;
						po.written = true;
						if ( !po.shutdown ) _writtenPingObjects.set( po.id, po );
	
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
	
				if ( !_defaultSettings.useBlockingSockets && _defaultSettings.threadEventLoopInterval > 0 ) Sys.sleep( _defaultSettings.threadEventLoopInterval / 1000 );
	
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
	
			_threadFinished( Thread.current() );	
		}
		catch (e)
		{
			_logException(e);
		}
	}

	static function _createSocket() {

		try
		{
			_socket = NativeICMPSocket.socket_new( true );
			NativeICMPSocket.socket_set_blocking( _socket, _defaultSettings.useBlockingSockets );
			_port = Std.random( 55535 ) + 10000;
			//var localhost = new Host( Host.localhost() );
			//NativeICMPSocket.socket_bind( _socket, localhost.ip, _port );	
		}
		catch (e)
		{
			_logException(e);
		}
	}

	static function _createThreads() {

		try
		{
			_eventProcessigThreadFinished = _writeThreadFinished = _readThreadFinished = _limboThreadFinished = false;
			_canLoopLimboThread = _canLoopReadThread = true;

			_eventProcessigThread = Thread.createWithEventLoop( _createEventProcessingThread );
			_writeThread = Thread.createWithEventLoop( _createWriteThread );

			if ( _defaultSettings.useEventLoops ) {

				_readThread = Thread.createWithEventLoop( _createReadThread );
				_limboThread = Thread.createWithEventLoop( _createLimboThread );

			} else {

				_readThread = Thread.create( _createReadThreadEventLoop );
				_limboThread = Thread.create( _createLimboThreadEventLoop );
			}
		}
		catch (e)
		{
			_logException(e);
		}		
	}

	static function _destroySocket() {

		if ( _socket != null ) NativeICMPSocket.socket_close( _socket );
		_socket = null;
	}

	static function _destroyThreads() {

		try
		{
			_mutex.acquire();

			var nullObject = new PingObject( null, 0, 0, 0 );
			_limboPingObjects.add( nullObject );
			_readyPingObjects.add( nullObject );

			_mutex.release();	
		}
		catch (e)
		{
			_logException(e);
		}
	}

	static function _threadFinished( thread:Thread ) {

		#if CHAMPAIGN_DEBUG
		Logger.debug( 'Thread ${thread} finished' );
		#end

		try
		{
			if ( thread == _eventProcessigThread ) _eventProcessigThreadFinished = true;
			if ( thread == _writeThread ) _writeThreadFinished = true;
			if ( thread == _readThread ) _readThreadFinished = true;
			if ( thread == _limboThread ) _limboThreadFinished = true;

			if ( _eventProcessigThreadFinished && _writeThreadFinished && _readThreadFinished && _limboThreadFinished ) {

				_eventProcessigThread = _writeThread = _readThread = _limboThread = null;
				for ( f in onStop ) f();
				_destroySocket();

			}
		}
		catch (e)
		{
			_logException(e);
		}
	}

	static function _logException(e:Dynamic):Void
	{
		if (Std.isOfType(e, Exception)) 
		{
			#if LOG_CHAMPAIGN_EXCEPTION
			Logger.fatal('Fatal exception : ${e}\nDetails : ${e.details()}\nNative : ${e.native}\nStack : ${e.stack}');
			#end
		} 
		else 
		{
			#if LOG_CHAMPAIGN_EXCEPTION
			Logger.fatal('Fatal error: ${e}');
			#end
		}   
	}

}

typedef PingerSettings = {

	?keepThreadsAlive:Bool,
	?period:Int,
	?threadEventLoopInterval:Int,
	?useBlockingSockets:Bool,
	?useEventLoops:Bool,

}

@:allow( champaign.cpp.network )
@:noDoc
private class PingObject {

	static final chars = '01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
	static final defaultPacketSize:Int = 56;

	static var currentPingObjectId:Int = 0;

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
		if ( currentPingObjectId > 0xFFFF ) currentPingObjectId = 0;
		this.id = currentPingObjectId;
		currentPingObjectId++;

		// Notify threads and event loops that they should be shut down
		if ( hostname == null ) return;

		var host = new Host( hostname );
		this.address = new Address();
		this.address.host = host.ip;

		this.count = count;
		this.timeout = timeout;
		this.delay = delay;
		this.currentCount = 0;
		this.pingId = 0;

		try
		{
			var data:String = StringTools.hex( this.id, 4 ) + "|";
			for ( i in 0...defaultPacketSize - 5 ) data += chars.charAt( Std.random( chars.length ) );
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
				NativeICMPSocket.socket_set_blocking( this.socket, Pinger._defaultSettings.useBlockingSockets );

			} else {

				this.socket = socket;

			}
		}
		catch (e)
		{
			logException(e);
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

	function logException(e:Dynamic):Void
	{
		if (Std.isOfType(e, Exception)) 
		{
			#if LOG_CHAMPAIGN_EXCEPTION
			Logger.fatal('Fatal exception : ${e}\nDetails : ${e.details()}\nNative : ${e.native}\nStack : ${e.stack}');
			#end
		} 
		else 
		{
			#if LOG_CHAMPAIGN_EXCEPTION
			Logger.fatal('Fatal error: ${e}');
			#end
		}   
	}
}

class PingPacketHeader {

	static public function createEmpty():PingPacketHeader {

		var p = new PingPacketHeader();
		return p;

	}

	static public function fromBytes( bytes:Bytes ):PingPacketHeader {

		var p = new PingPacketHeader();

		try 
		{
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
		}
		catch (e)
		{
			if (Std.isOfType(e, Exception)) 
			{
				#if LOG_CHAMPAIGN_EXCEPTION
				Logger.fatal('Fatal exception : ${e}\nDetails : ${e.details()}\nNative : ${e.native}\nStack : ${e.stack}');
				#end
			} 
			else 
			{
				#if LOG_CHAMPAIGN_EXCEPTION
				Logger.fatal('Fatal error: ${e}');
				#end
			}   	
		}
		
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

		try
		{
			var hlength = 20;
			if ( !SysTools.isLinux() ) {
				var b = Bytes.alloc( hlength );
				b.blit( 0, bytes, 0, hlength );
				p.header = PingPacketHeader.fromBytes( b );
				if ( p.header == null ) return null;
			} else {
				p.header = PingPacketHeader.createEmpty();
				hlength = 0;
			}
			p.type = bytes.get( hlength );
			p.code = bytes.get( hlength + 1 );
			p.checksum = bytes.getUInt16( hlength + 2 );
			p.identifier = bytes.getUInt16( hlength + 4 );
			p.sequenceNumber = bytes.getUInt16( hlength + 6 );
			p.data = Bytes.alloc( SysTools.isWindows() ? 64 - 28 : 64 - 8 );
			p.data.blit( 0, bytes, hlength + 8, p.data.length );
			var a = p.data.toString().split( '|' );
			if ( a != null && a.length > 0 ) p.embeddedId = Std.parseInt( '0x${a[ 0 ]}' );
		}
		catch (e)
		{
			if (Std.isOfType(e, Exception)) 
			{
				#if LOG_CHAMPAIGN_EXCEPTION
				Logger.fatal('Fatal exception : ${e}\nDetails : ${e.details()}\nNative : ${e.native}\nStack : ${e.stack}');
				#end
			} 
			else 
			{
				#if LOG_CHAMPAIGN_EXCEPTION
				Logger.fatal('Fatal error: ${e}');
				#end
			}   
		}
		
		return p;

	}

	public var checksum( default, null ):Int;
	public var code( default, null ):Int;
	public var data( default, null ):Bytes;
	public var embeddedId( default, null ):Int;
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