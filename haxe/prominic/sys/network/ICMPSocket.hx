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

package prominic.sys.network;

import haxe.io.Bytes;
import haxe.io.Error;
import prominic.sys.network.NativeICMPSocket;
import sys.net.Address;
import sys.net.Host;
import sys.thread.EventLoop.EventHandler;
import sys.thread.Mutex;
import sys.thread.Thread;

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
    static final _eventLoopDelay:Int = 0;

	static var _icmpSockets( default, null ):Array<ICMPSocket> = [];
	static var _icmpSocketsToRead( default, null ):Array<ICMPSocket> = [];
	static var _icmpSocketsToWrite( default, null ):Array<ICMPSocket> = [];
	static var _pingerHandler:EventHandler;
	static var _pingerMutex:Mutex;
	static var _pingerThread:Thread;
	static var _subPos:Int = 8;

	static function _addICMPSocket( icmpSocket:ICMPSocket ) {

		var i = _icmpSockets.push( icmpSocket );
		_initThread();
		return i;

	}

	static function _initThread():Void {

		if ( _pingerThread == null ) {

			_pingerMutex = new Mutex();
			_pingerThread = Thread.createWithEventLoop( _pinger );
			if ( SysTools.isMac() ) _subPos = 28;

		}

	}

	static function _pingLoop():Void {

		_pingerMutex.acquire();

		_icmpSocketsToRead = Lambda.filter( _icmpSockets, (item)->{ return cast( item, ICMPSocket ).readyToRead(); } );
		_icmpSocketsToWrite = Lambda.filter( _icmpSockets, (item)->{ return cast( item, ICMPSocket ).readyToWrite(); } );
		var result = ICMPSocket.select( _icmpSocketsToRead, _icmpSocketsToWrite, null, 0 );
		//trace( result );

		for ( i in result.read ) {

			try {

				var buf = Bytes.alloc( 100 );
				var len = NativeICMPSocket.socket_recv_from(i.__s, buf.getData(), 0, buf.length, i._address);
				var res = buf.sub( _subPos, 56 );

				if ( res.toString() == i._data ) {

					i._readTime = Date.now().getTime();
					i._written = false;
					i._read = true;
					i.onPing( i );

					i._pingCount++;

					if ( i.count != 0 && i._pingCount >= i.count ) {
		
						_removeICMPSocket( i );
						i.onPingFinished( i );
		
					}
					
				}

			} catch ( e ) {

				i.onError( i );
				if ( i._stopOnError ) _removeICMPSocket( i );

			}

		}

		for ( i in result.write ) {

			try {

				i._writeTime = Date.now().getTime();
				// Adding 8 bytes of padding
				var b = Bytes.ofString( "00000000" + i._data );
				var len = NativeICMPSocket.socket_send_to(i.__s, b.getData(), 0, b.length, i._address, i._pingNumber, i._id );
				i._written = true;
				i._read = false;
				i._pingNumber++;

			} catch ( e ) {

				i.onError( i );
				if ( i._stopOnError ) _removeICMPSocket( i );

			}

		}

		// Checking timed-out sockets
		for ( s in _icmpSocketsToRead ) {

			var i:ICMPSocket = cast s;

			if ( Date.now().getTime() > i._writeTime + i.timeout ) {

				if ( i._stopOnError ) _removeICMPSocket( i );

				if ( !i._timedOut ) {

					i.onTimeout( i );
					i._timedOut = true;

				}

			}

		}

		_pingerMutex.release();

	}
	
	static function _pinger():Void {
		
		_pingerMutex.acquire();
		_pingerHandler = Thread.current().events.repeat( _pingLoop, _eventLoopDelay );
		_pingerMutex.release();

	}

	static function _removeICMPSocket( icmpSocket:ICMPSocket ) {

		var b = _icmpSockets.remove( icmpSocket );

		// Canceling event loop if there's no more ICMP sockets
		if ( _icmpSockets.length == 0 ) {

			if ( _pingerThread != null ) _pingerThread.events.cancel( _pingerHandler );
			_pingerThread = null;
			_pingerHandler = null;

		}

		return b;

	}

	final _defaultPacketSize:Int = 56;
	final _maximumPacketSize:Int = 508;

	var _address:Address;
	var _closed:Bool;
	var _data:String;
	var _host:{host:Host, port:Int};
	var _id:Int;
	var _output(default, null):haxe.io.Output;
	var _pingCount:Int;
	var _pingNumber:Int;
	var _read:Bool;
	var _readTime:Float;
	var _stopOnError:Bool;
	var _timedOut:Bool;
	var _writeTime:Null<Float>;
	var _written:Bool;
    var _input(default, null):haxe.io.Input;

    var __s:Dynamic;
    var __timeout:Float = 0.0;
	var __blocking:Bool = true;
	var __fastSend:Bool = false;

	public var count( default, null ):Int;
	public var delay( default, null ):Int;
	public var hostname( default, null ):String;
	public var packetSize( default, null ):Int;
	public var timeout( default, null ):Int;

	public var lastPingTime( get, never ):Int;
	function get_lastPingTime():Int { return Std.int( _readTime - _writeTime ); }

	public function new( hostname:String ) {

		this.hostname = hostname;
        init();

	}

	public function close():Void {

		_removeICMPSocket( this );

		NativeICMPSocket.socket_close(__s);

		untyped {

			var input:ICMPSocketInput = cast _input;
			var output:ICMPSocketOutput = cast _output;
			input.__s = null;
			output.__s = null;

		}

		_input.close();
		_output.close();

		_address = null;
		_closed = true;

	}

	function createData():Void {

		this._data = '';
		for ( i in 0...56 ) this._data += _chars.charAt( Std.random( _chars.length ) );

	}

	function init():Void {

		if (__s == null)
			__s = NativeICMPSocket.socket_new(false);
		// Restore these values if they changed. This can happen
		// in connect() and bind() if using an ipv6 address.
		setTimeout( __timeout );
		setBlocking( __blocking );
		setFastSend( __fastSend );
		_input = new ICMPSocketInput( __s );
		_output = new ICMPSocketOutput( __s );
		_id = Std.random( 0xFFFFFFFF );
		createData();

	}

	public dynamic function onError( socket:ICMPSocket ):Void {}

	public dynamic function onHostError( socket:ICMPSocket ):Void {}

	public dynamic function onPing( socket:ICMPSocket ):Void {}

	public dynamic function onPingFinished( socket:ICMPSocket ):Void {}

	public dynamic function onTimeout( socket:ICMPSocket ):Void {}

	public function ping( count:Int = 1, timeout:Int = 2000, delay:Int = 1000, stopOnError:Bool = false ):Void {

		if ( _closed ) {

			throw "This ICMPSocket is closed, create a new one to ping a host";

		}

		this.count = count;
		this.packetSize = _defaultPacketSize;
		this.timeout = timeout;
		this.delay = delay;
		this._stopOnError = stopOnError;

		try {

			var h = new Host( hostname );
			_host = { host:h, port:Std.random( 55535 ) + 10000 };
			//_host = { host:h, port:80 };

		} catch ( e ) {

			onHostError( this );
			return;

		}

		if ( _address != null ) return;

		_address = new Address();
        _address.host = new Host( _host.host.host ).ip;
        _address.port = _host.port;

		_pingCount = 0;
		_pingNumber = 0;
		_addICMPSocket( this );

	}

	function readyToRead():Bool {

		return !_read && !_timedOut;

	}

	function readyToWrite():Bool {

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

	public function toString():String {

		return 'ICMPSocket:${hostname}';

	}

}

private class ICMPSocketInput extends haxe.io.Input {
	var __s:Dynamic;

	public function new(s:Dynamic) {
		__s = s;
	}

	public override function readByte() {
		return try {
			NativeICMPSocket.socket_recv_char(__s);
		} catch (e:Dynamic) {
			if (e == "Blocking")
				throw Blocked;
			else if (__s == null)
				throw Custom(e);
			else
				throw new haxe.io.Eof();
		}
	}

	public override function readBytes(buf:haxe.io.Bytes, pos:Int, len:Int):Int {
		var r;
		if (__s == null)
			throw "Invalid handle";
		try {
			r = NativeICMPSocket.socket_recv(__s, buf.getData(), pos, len);
		} catch (e:Dynamic) {
			if (e == "Blocking")
				throw Blocked;
			else
				throw Custom(e);
		}
		if (r == 0)
			throw new haxe.io.Eof();
		return r;
	}

	public override function close() {
		super.close();
		if (__s != null)
			NativeICMPSocket.socket_close(__s);
	}
}

private class ICMPSocketOutput extends haxe.io.Output {
	var __s:Dynamic;

	public function new(s:Dynamic) {
		__s = s;
	}

	public override function writeByte(c:Int) {
		if (__s == null)
			throw "Invalid handle";
		try {
			NativeICMPSocket.socket_send_char(__s, c);
		} catch (e:Dynamic) {
			if (e == "Blocking")
				throw Blocked;
			else
				throw Custom(e);
		}
	}

	public override function writeBytes(buf:haxe.io.Bytes, pos:Int, len:Int):Int {
		return try {
			NativeICMPSocket.socket_send(__s, buf.getData(), pos, len);
		} catch (e:Dynamic) {
			if (e == "Blocking")
				throw Blocked;
			else if (e == "EOF")
				throw new haxe.io.Eof();
			else
				throw Custom(e);
		}
	}

	public override function close() {
		super.close();
		if (__s != null)
			NativeICMPSocket.socket_close(__s);
	}
}
