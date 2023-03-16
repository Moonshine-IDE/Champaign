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

import champaign.cpp.externs.NativeICMPSocket;
import sys.net.Address;
import sys.net.Host;

/**
 * A specially formatted and coded socket class for ICMP communication (to ping a host)
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
	static final _defaultPacketSize:Int = 56;

	var _address:Address;
	var _checksum:Int;
	var _closed:Bool;
	var _data:String;
	var _host:{host:Host, port:Int};
	var _id:Int;
	var _pingCount:Int;
	var _read:Bool;
	var _readTime:Float;
	var _stopOnError:Bool;
	var _timedOut:Bool;
	var _writeTime:Null<Float>;
	var _written:Bool;

    var __s:Dynamic;
    var __timeout:Float = 0.0;
	var __blocking:Bool = true;
	var __fastSend:Bool = false;

	/**
	 * The total number of pings 
	 */
	public var count( default, null ):Int;

	/**
	 * The delay between the pings (in milliseconds)
	 */
	public var delay( default, null ):Int;

	/**
	 * The hostname
	 */
	public var hostname( default, null ):String;

	/**
	 * The timeout, in milliseconds
	 */
	public var timeout( default, null ):Int;

	/**
	 * Response time of the last ping
	 */
	public var lastPingTime( get, never ):Int;
	function get_lastPingTime():Int { return Std.int( _readTime - _writeTime ); }

	/**
	 * Creates a new ICMPSocket instance with the given hostname
	 * @param hostname Name of the host where the ICMPSocket should connect to
	 */
	public function new( hostname:String ) {

		this.hostname = hostname;
        init();

	}

	/**
	 * Close and dispose the ICMPSocket. After calling close() the socket cannot be used anymore.
	 */
	public function close():Void {

		ICMPSocketManager._removeICMPSocket( this );

		NativeICMPSocket.socket_close(__s);

		_address = null;
		_closed = true;

	}

	function createData():Void {

		this._data = '';
		for ( i in 0..._defaultPacketSize ) this._data += _chars.charAt( Std.random( _chars.length ) );

	}

	function init():Void {

		__s = NativeICMPSocket.socket_new(false);
		setTimeout( __timeout );
		setBlocking( __blocking );
		setFastSend( __fastSend );
		_id = Std.random( 0xFFFFFFFF );
		if ( _data == null ) createData();

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
	 */
	public function ping( count:Int = 1, timeout:Int = 2000, delay:Int = 1000, stopOnError:Bool = false ):Void {

		if ( _closed ) {

			throw "This ICMPSocket is closed, create a new one to ping a host";

		}

		this.count = count;
		this.timeout = timeout;
		this.delay = delay;
		this._stopOnError = stopOnError;

		try {

			var h = new Host( hostname );
			_host = { host:h, port:Std.random( 55535 ) + 10000 };
			//_host = { host:h, port:80 };

		} catch ( e ) {

			onEvent( this, ICMPSocketEvent.HostError );
			return;

		}

		if ( _address != null ) return;

		_address = new Address();
        _address.host = new Host( _host.host.host ).ip;
        _address.port = _host.port;

		_pingCount = 0;
		ICMPSocketManager._addICMPSocket( this );

	}

	inline function readyToRead():Bool {

		return !_read && !_timedOut;

	}

	inline function readyToWrite():Bool {

		return !_written && ( Date.now().getTime() >= ( _writeTime + delay ) );

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

	HostError;
	Ping;
	PingError;
	PingFailed;
	PingStop;
	PingTimeout;

}
