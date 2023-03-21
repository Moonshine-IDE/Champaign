/*
 *  Copyright (C) 2016-present Prominic.NET, Inc.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the Server Side Public License, version 1,
 *  as published by MongoDB, Inc.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  Server Side Public License for more details.
 *
 *  You should have received a copy of the Server Side Public License
 *  along with this program. If not, see
 *
 *  http://www.mongodb.com/licensing/server-side-public-license
 *
 *  As a special exception, the copyright holders give permission to link the
 *  code of portions of this program with the OpenSSL library under certain
 *  conditions as described in each individual source file and distribute
 *  linked combinations including the program with the OpenSSL library. You
 *  must comply with the Server Side Public License in all respects for
 *  all of the code used other than as permitted herein. If you modify file(s)
 *  with this exception, you may extend this exception to your version of the
 *  file(s), but you are not obligated to do so. If you do not wish to do so,
 *  delete this exception statement from your version. If you delete this
 *  exception statement from all source files in the program, then also delete
 *  it in the license file.
 */

package champaign.cpp.network;

import champaign.core.tools.StrTools;
import champaign.cpp.externs.NativeICMPSocket;
import champaign.sys.SysTools;
import haxe.io.Bytes;
import haxe.io.BytesData;
import sys.net.Address;
import sys.net.Host;

/**
 * A specially formatted and coded socket class for ICMP communication (to ping a host). Create an ICMPSocket with `ICMPSocketManager.create()`
 */
@:allow( champaign.cpp.network )
class ICMPSocket {

    static function select(read:Array<ICMPSocket>, write:Array<ICMPSocket>, others:Array<ICMPSocket>, ?timeout:Float):{read:Array<ICMPSocket>, write:Array<ICMPSocket>, others:Array<ICMPSocket>} {

        var neko_array = NativeICMPSocket.socket_select(read, write, others, timeout);

        if (neko_array == null)
            throw "Select error";
        return @:fixed {
            read:neko_array[0], write:neko_array[1], others:neko_array[2]
        };

    }

	static final _chars = '01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
	static final _defaultDelay = 1000;
	static final _defaultPacketSize:Int = 56;

	var _actualPingCount:Int;
	var _actualSuccessfulPingCount:Int;
	var _address:Address;
	var _byteData:BytesData;
	var _checksum:Int;
	var _data:String;
	var _delay:Int;
	var _host:{host:Host, port:Int};
	var _id:Int = -1;
	var _pingId:Int;
	var _randomizeData:Bool;
	var _read:Bool;
	var _readBuffer:Bytes;
	var _readTime:Float;
	var _stopOnError:Bool;
	var _timedOut:Bool;
	var _writeTime:Null<Float>;
	var _written:Bool;

    var __s:Dynamic;
    var __timeout:Float = 0.0;
	var __blocking:Bool = false;
	var __fastSend:Bool = false;

	/**
	 * 
	 */
	public var closed( default, null ):Bool;
	
	/**
	 * The total number of pings
	 */
	public var count( default, null ):Int;

	/**
	 * The delay between the pings (in milliseconds)
	 */
	public var delay( get, set ):Int;
	function get_delay() return _delay;
	function set_delay( value ) { _delay = ( value < 0 ) ? _defaultDelay : value; return _delay; }

	/**
	 * The hostname
	 */
	public var hostname( default, null ):String;

	/**
	 * Response time of the last ping
	 */
	public var pingTime( get, never ):Int;
	function get_pingTime():Int { return Std.int( _readTime - _writeTime ); }
 
	/**
	 * The number of successful pings
	 */
	public var successfulPings( get, never ):Int;
	function get_successfulPings():Int return _actualSuccessfulPingCount;
  
	/**
	 * The timeout, in milliseconds
	 */
	public var timeout( default, null ):Int;

	/**
	 * The number of total pings
	 */
	public var totalPings( get, never ):Int;
	function get_totalPings():Int return _actualPingCount;
   
	 /**
	 * Creates a new ICMPSocket instance with the given hostname
	 * @param hostname Name of the host where the ICMPSocket should connect to
	 */
	function new( hostname:String ) {

		this.hostname = hostname;
        init();

	}

	/**
	 * Close and dispose the ICMPSocket. After calling close() the socket cannot be used anymore.
	 */
	public function close():Void {

		if ( closed || __s == null ) return;

		closed = true;

		ICMPSocketManager._removeICMPSocket( this );

		if ( __s != null ) {

			NativeICMPSocket.socket_close(__s);
			__s = null;

		}

	}

	function createData():Void {

		this._data = '[' + this.hostname;
		for ( i in 0..._defaultPacketSize - 2 - this.hostname.length ) this._data += _chars.charAt( Std.random( _chars.length ) );
		this._data += ']';
		this._byteData = Bytes.ofString( "00000000" + this._data ).getData();
		// Filling in ICMP Header
		_byteData[0] = 8;
		_byteData[1] = 0;
		_byteData[2] = 0;
		_byteData[3] = 0;
		_byteData[4] = this._id;
		_byteData[5] = this._id >> 8;
		_byteData[6] = 0;
		_byteData[7] = 0;

	}

	function init():Void {

		if ( __s != null ) {

			//NativeICMPSocket.socket_shutdown( __s, true, true );
			NativeICMPSocket.socket_close( __s );

		}

		if ( SysTools.isWindows() ) NativeICMPSocket.socket_init();
		__s = NativeICMPSocket.socket_new(false);
		setTimeout( __timeout );
		setBlocking( __blocking );
		setFastSend( __fastSend );
		// Must be a short int
		_id = Std.random( 0xFFFF );
		if ( _data == null ) createData();
		_readBuffer = Bytes.alloc( 84 );

	}

	/**
	 * Bind a function to catch socket events
	 * @param socket The ICMPSocket the event occured on (*this* object)
	 */
	public dynamic function onEvent( socket:ICMPSocket, event:ICMPSocketEvent ):Void {}

	/**
	 * Send ping (ICMP Echo message) to the given host
	 * @param count Number of retries
	 * @param timeout Time, in milliseconds, after it stops waiting for the response from the host
	 * @param delay Delay between pings (in milliseconds)
	 * @param stopOnError True if ping should stop if an error occurs
	 * @param randomizeData Randomize the data being sent over the socket at every ping (echo) request
	 */
	public function ping( count:Int = 1, timeout:Int = 2000, delay:Int = 1000, stopOnError:Bool = false, randomizeData:Bool = false ):Void {

		if ( closed ) {

			throw "This ICMPSocket is closed, create a new one to ping a host";

		}

		this.count = count;
		this.timeout = timeout;
		this._delay = delay;
		this._stopOnError = stopOnError;
		this._randomizeData = randomizeData;

		try {

			var h = new Host( hostname );
			//_host = { host:h, port:Std.random( 55535 ) + 10000 };
			_host = { host:h, port:0 };
			//_host = { host:h, port:80 };

		} catch ( e ) {

			onEvent( this, ICMPSocketEvent.HostError );
			return;

		}

		if ( _address != null ) return;

		_address = new Address();
        _address.host = new Host( _host.host.host ).ip;
        _address.port = _host.port;

		_pingId = 0;
		_actualPingCount = 0;
		_actualSuccessfulPingCount = 0;
		ICMPSocketManager._addICMPSocket( this );

	}

	function readyToRead():Bool {

		return !_read && !_timedOut;

	}

	function readyToWrite():Bool {

		return !_written && ( Date.now().getTime() >= ( _writeTime + _delay ) );

	}

    function setBlocking(b:Bool):Void {
		__blocking = b;
		NativeICMPSocket.socket_set_blocking(__s, b);
	}

    function setFastSend(b:Bool):Void {
		__fastSend = b;
		NativeICMPSocket.socket_set_fast_send(__s, b);
	}

    function setTimeout(timeout:Float):Void {
		__timeout = timeout;
		NativeICMPSocket.socket_set_timeout(__s, timeout);
	}

	@:noDoc
	public function toString():String {

		return 'ICMPSocket:${hostname}';

	}

}

enum ICMPSocketEvent {

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

class ICMPPacketHeader {

	static public function fromBytes( bytes:Bytes ):ICMPPacketHeader {

		var p = new ICMPPacketHeader();

		var versionByte = bytes.get( 0 );
		p.ipVersion = versionByte >> 4;
		p.headerLength = versionByte << 28 >> 26;
		if ( p.headerLength == 0 ) return null;
		p.totalLength = bytes.getUInt16( 2 );
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

	public var destinationAddress( default, null ):UInt;
	public var headerChecksum( default, null ):Int;
	public var flags( default, null ):Int;
	public var headerLength( default, null ):Int;
	public var identification( default, null ):Int;
	public var ipVersion( default, null ):IPVersion;
	public var protocol( default, null ):Int;
	public var sourceAddress( default, null ):UInt;
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

class ICMPPacket {

	static public function fromBytes( bytes:Bytes ):ICMPPacket {

		if ( bytes.length < 84 ) return null;

		var p = new ICMPPacket();
		var b = Bytes.alloc( 20 );
		b.blit( 0, bytes, 0, 20 );
		p.header = ICMPPacketHeader.fromBytes( b );
		if ( p.header == null ) return null;
		p.type = bytes.get( 20 );
		p.code = bytes.get( 21 );
		p.checksum = bytes.getUInt16( 22 );
		p.identifier = bytes.getUInt16( 24 );
		p.sequenceNumber = bytes.getUInt16( 26 );
		p.data = Bytes.alloc( p.header.totalLength - 8 );
		p.data.blit( 0, bytes, 28, p.data.length );
		return p;

	}

	public var checksum( default, null ):Int;
	public var code( default, null ):Int;
	public var data( default, null ):Bytes;
	public var header( default, null ):ICMPPacketHeader;
	public var identifier( default, null ):Int;
	public var sequenceNumber( default, null ):Int;
	public var type( default, null ):Int;

	function new() {}

}

@:noDoc
enum abstract ICMPCode( Int ) from Int to Int {

	var DestinationNetworkUnreachable = 0;
	var DestinationHostUnreachable = 1;
	var DestinationProtocolUnreachable = 2;
	var DestinationPortUnreachable = 3;
	var FragmentationRequired = 4;
	var SourceRouteFailed = 5;
	var DestinationNetworkUnknown = 6;
	var DestinationHostUnknown = 7;
	var SourceHostIsolated = 8;
	var NetworkAdministrativelyProhibited = 9;
	var HostAdministrativelyProhibited = 10;
	var NetworkUnreachableForTOS = 11;
	var HostUnreachableForTOS = 12;
	var CommunicationAdministrativelyProhibited = 13;
	var HostPrecenenceViolation = 14;
	var PrecedenceCutoffInEffect = 15;

}

@:noDoc
enum abstract ICMPType( Int ) from Int to Int {

	var Echo = 0;
	var DestinationUnreachable = 3;

}

@:noDoc
enum abstract IPVersion( Int ) from Int to Int {

	var IPv4 = 4;
	var IPv6 = 6;

}
