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
import champaign.cpp.network.ICMPSocket.ICMPSocketEvent;
import champaign.sys.SysTools;
import haxe.io.Bytes;
import haxe.io.Eof;
import sys.thread.EventLoop;
import sys.thread.Mutex;
import sys.thread.Thread;

@:allow( champaign.cpp.network )
@:noDoc
@:nullSafety(Strict)
class ICMPSocketManager {

	static var _subPos:Int = 8;
    static var _threads:ICMPSocketThreadList = new ICMPSocketThreadList();

    static function _addICMPSocket( icmpSocket:ICMPSocket ) {

        if ( SysTools.isMac() ) _subPos = 28;

        var selectedThread:Null<ICMPSocketThread> = null;

        // ICMPSocket is alread added in one of the threads
        for ( thread in _threads )
            if ( thread._contains( icmpSocket ) ) return -1;

        for ( thread in _threads ) {

            if ( thread._hasSocketSlot() ) {

                selectedThread = thread;
                break;

            }

        }

        if ( selectedThread == null ) {

            selectedThread = new ICMPSocketThread();
            _threads.add( selectedThread );

        }

        return selectedThread._addSocket( icmpSocket );

	}
    
	static function _removeICMPSocket( icmpSocket:ICMPSocket ) {

        for ( thread in _threads ) {

            if ( thread._contains( icmpSocket ) ) {
             
                var b = thread._removeSocket( icmpSocket );
                if ( thread.length == 0 ) _threads.remove( thread );
                return b;

            }

        }

        return false;

	}

}

@:allow( champaign.cpp.network )
@:noDoc
@:nullSafety(Loose)
class ICMPSocketThread {

    final _defaultSocketLimit:Int = 50;
    final _eventLoopInterval:Int = 100;

    var _eventHandler:Null<EventHandler>;
    var _icmpSockets:Array<ICMPSocket> = [];
    var _icmpSocketsToRead:Array<ICMPSocket> = [];
    var _icmpSocketsToWrite:Array<ICMPSocket> = [];
    var _limit:Int;
    var _mutex:Mutex;
    var _thread:Thread;

    var length( get, never ):Int;
    function get_length() return ( _icmpSockets != null ) ? _icmpSockets.length : 0;

    function new( ?limit:Int ) {

        _limit = ( limit != null ) ? limit : _defaultSocketLimit;

        _mutex = new Mutex();
        _thread = Thread.createWithEventLoop( _threadCreate );

    }

    function _addSocket( socket:ICMPSocket ) {

        return _icmpSockets.push( socket );

    }

    function _contains( socket:ICMPSocket ) {

        return _icmpSockets.contains( socket );

    }

    function _hasSocketSlot() {

        return _icmpSockets.length < _limit;

    }

    function _threadCreate() {

        _mutex.acquire();
        _eventHandler = Thread.current().events.repeat( _threadLoop, _eventLoopInterval );
        _mutex.release();

    }

    function _threadLoop():Void {

        _mutex.acquire();

        _icmpSocketsToRead = Lambda.filter( _icmpSockets, ( item )->{ return item.readyToRead(); } );
		_icmpSocketsToWrite = Lambda.filter( _icmpSockets, ( item )->{ return item.readyToWrite(); } );
		var result = ICMPSocket.select( _icmpSocketsToRead, _icmpSocketsToWrite, [], 0 );
		#if CHAMPAIGN_DEBUG trace( result.read.length, result.write.length ); #end

        for ( i in result.read ) {

			try {

				var buf = Bytes.alloc( 100 );
				var len = NativeICMPSocket.socket_recv_from(i.__s, buf.getData(), 0, buf.length, i._address);
                var full = buf.sub( 0, buf.length );
                #if CHAMPAIGN_DEBUG trace( '${i} Read data length: ${len}' ); #end
                #if CHAMPAIGN_DEBUG trace( 'Full response: ${full.toHex()}' ); #end
                var icmpHeader = buf.sub( ICMPSocketManager._subPos - 8, 8 );
                var icmpHeaderControlByte = icmpHeader.get( 0 );
                #if CHAMPAIGN_DEBUG trace( '${i} ICMP Header: ${icmpHeader.toHex()}' ); #end

                if ( icmpHeaderControlByte == 0 ) {

                    // Ping successful
                    var res = buf.sub( ICMPSocketManager._subPos, 56 );

                    if ( res.toString() == i._data ) {

                        i._readTime = Date.now().getTime();
                        i._written = false;
                        i._read = true;
                        i.onEvent( i, ICMPSocketEvent.Ping );
                        i._pingCount++;

                        if ( i.count != 0 && i._pingCount >= i.count ) {
            
                            i.onEvent( i, ICMPSocketEvent.PingStop );
                            _removeSocket( i );
            
                        }
                        
                    }

                } else {

                    // Destination Unreachable
                    i._readTime = Date.now().getTime();
                    i._written = false;
                    i._read = true;
                    i.onEvent( i, ICMPSocketEvent.PingFailed );
                    i._pingCount++;

                    if ( i.count != 0 && i._pingCount >= i.count ) {
            
                        i.onEvent( i, ICMPSocketEvent.PingStop );
                        _removeSocket( i );
        
                    }

                }

			} catch ( e ) {

				#if CHAMPAIGN_DEBUG trace( 'ICMPSocket Read Error: ${e} ${i.hostname}' ); #end
                i.onEvent( i, ICMPSocketEvent.PingError );
				if ( i._stopOnError ) _removeSocket( i );
                i._pingCount++;

			}

		}

		for ( i in result.write ) {

			try {

				i._writeTime = Date.now().getTime();
				// Adding 8 bytes of padding
				var b = Bytes.ofString( "00000000" + i._data );
				var checksum = NativeICMPSocket.socket_send_to(i.__s, b.getData(), 0, b.length, i._address, i._pingCount, i._id );
                #if CHAMPAIGN_DEBUG trace( '${i} Checksum: ${checksum} ${StringTools.hex(checksum)}' ); #end
                i._checksum = checksum;
				i._written = true;
				i._read = false;

			} catch ( e:Eof ) {

				#if CHAMPAIGN_DEBUG trace( 'ICMPSocket Write EOF' ); #end
                i.onEvent( i, ICMPSocketEvent.PingError );

                if ( i._stopOnError ){

                    _removeSocket( i );

                } else {

                    // Re-initialize the ICMPSocket in case of EOF
                    i.init();

                }

			} catch ( e ) {

				#if CHAMPAIGN_DEBUG trace( 'ICMPSocket Write error: ${e}' ); #end
                i.onEvent( i, ICMPSocketEvent.PingError );

				if ( i._stopOnError ){

                    _removeSocket( i );

                } else {

                    // Re-initialize the ICMPSocket in case of EOF
                    i.init();

                }

			}

		}

		// Checking timed-out sockets
		for ( i in _icmpSockets ) {

			if ( i._read == false && i._written == true && i._writeTime != null && Date.now().getTime() > i._writeTime + i.timeout ) {

				if ( i._stopOnError ) _removeSocket( i );

				if ( !i._timedOut ) {

					i._readTime = Date.now().getTime();
					i._written = false;
					i._read = false;
                    i.onEvent( i, ICMPSocketEvent.PingTimeout );
					//i._timedOut = true;

				}

			}

		}

        _mutex.release();

    }

    function _removeSocket( socket:ICMPSocket ) {

        var b = ( _icmpSockets != null ) ? _icmpSockets.remove( socket ) : false;

        if ( _icmpSockets != null && _icmpSockets.length == 0 ) {

            if ( _eventHandler != null ) _thread.events.cancel( _eventHandler );
            _eventHandler = null;

        }

        return b;

    }

}

typedef ICMPSocketThreadList = List<ICMPSocketThread>;