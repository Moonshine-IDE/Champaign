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
import champaign.sys.SysTools;
import haxe.io.Bytes;
import haxe.io.Eof;
import sys.thread.EventLoop;
import sys.thread.Mutex;
import sys.thread.Thread;

@:allow( champaign.cpp.network )
class ICMPSocketManager {

    static final _eventLoopDelay:Int = 100;
    
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
		trace( result.read.length, result.write.length );

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

				trace( 'read: ${e}' );
				i.onError( i );
				if ( i._stopOnError ) _removeICMPSocket( i );

			}

		}

		for ( i in result.write ) {

			try {

				i._writeTime = Date.now().getTime();
				// Adding 8 bytes of padding
				var b = Bytes.ofString( "00000000" + i._data );
				var len = NativeICMPSocket.socket_send_to(i.__s, b.getData(), 0, b.length, i._address, 0, i._id );
				trace( 'write result: ${len}' );
				i._written = true;
				i._read = false;
				i._pingNumber++;

			} catch ( e:Eof ) {

				trace( 'write EOF' );
				i.onError( i );

			} catch ( e ) {

				trace( 'write: ${e}' );
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

					i._readTime = Date.now().getTime();
					i._written = true;
					i._read = false;
					i.onTimeout( i );
					//i._timedOut = true;

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

}