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
import champaign.cpp.network.ICMPSocket;
import champaign.sys.SysTools;
import haxe.io.Eof;
import sys.net.Address;
import sys.thread.EventLoop;
import sys.thread.Mutex;
import sys.thread.Thread;
#if ( CHAMPAIGN_DEBUG || CHAMPAIGN_VERBOSE )
import champaign.core.logging.Logger;
#end
@:allow( champaign.cpp.network )
@:nullSafety(Strict)
class ICMPSocketManager {

	static var _subPos:Int = 8;
    static var _threads:ICMPSocketThreadList = new ICMPSocketThreadList();

    /**
     * The delay between thread event loops (milliseconds)
     */
    static public var threadEventLoopInterval:Int = 0;

    /**
     * The number of sockets that can be added to a single thread
     */
    static public var threadSocketLimit:Int = 50;

    /**
     * Creates an ICMPSocket with the given hostname
     * @param hostname The hostname
     * @return The ICMPSocket
     */
    static public function create( hostname:String ):ICMPSocket {

        return new ICMPSocket( hostname );

    }

    /**
     * Sets the delay for every available ICMPSockets
     * @param delay The delay in milliseconds
     */
    static public function setDelayForEverySocket( delay:Int ) {

        for ( t in _threads ) {

            t._setDelay( delay );

        }

    }

    static function _addICMPSocket( icmpSocket:ICMPSocket ) {

        if ( SysTools.isMac() ) _subPos = 28;
        if ( SysTools.isWindows() ) _subPos = 28;

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

            selectedThread = new ICMPSocketThread( threadSocketLimit );
            selectedThread._id = _threads.length;
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
private class ICMPSocketThread {

    final _defaultSocketLimit:Int = 50;
    final _eventLoopInterval:Int = 0;

    var _eventHandler:Null<EventHandler>;
    var _icmpSockets:Array<ICMPSocket> = [];
    var _icmpSocketsToRead:Array<ICMPSocket> = [];
    var _icmpSocketsToWrite:Array<ICMPSocket> = [];
    var _id:Int = 0;
    var _limit:Int;
    var _mutex:Mutex;
    var _thread:Thread;

    var length( get, never ):Int;
    function get_length() return ( _icmpSockets != null ) ? _icmpSockets.length : 0;

    function new( ?limit:Int ) {

        _limit = ( limit != null && limit > 0 ) ? limit : _defaultSocketLimit;

        _mutex = new Mutex();
        _thread = Thread.createWithEventLoop( _threadCreate );

    }

    function toString():String {

        return '[ICMPSocketThread:${_id}]';

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

    function _setDelay( delay:Int ) {

        for( s in _icmpSockets ) s._delay = delay;

    }

    function _threadCreate() {

        #if CHAMPAIGN_DEBUG
        Logger.verbose( '${this} Thread created' );
        #end
        _mutex.acquire();
        _eventHandler = Thread.current().events.repeat( _threadLoop, ( ICMPSocketManager.threadEventLoopInterval > 0 ) ? ICMPSocketManager.threadEventLoopInterval : _eventLoopInterval );
        _mutex.release();

    }

    function _threadLoop():Void {

        _mutex.acquire();

        _icmpSocketsToRead = Lambda.filter( _icmpSockets, ( item )->{ return item.readyToRead(); } );
		_icmpSocketsToWrite = Lambda.filter( _icmpSockets, ( item )->{ return item.readyToWrite(); } );
        #if CHAMPAIGN_VERBOSE
        Logger.verbose( '${this} Sockets: ${_icmpSockets}' );
        Logger.verbose( '${this} Sockets to Read: ${_icmpSocketsToRead}' );
        Logger.verbose( '${this} Sockets to Write: ${_icmpSocketsToWrite}' );
        #end
        if ( _icmpSocketsToRead.length == 0 && _icmpSocketsToWrite.length == 0 ) {
            _mutex.release();
            return;
        }

	    var result = ICMPSocket.select( _icmpSocketsToRead, _icmpSocketsToWrite, [], 0 );
		#if CHAMPAIGN_VERBOSE
        Logger.verbose( '${this} Selected Sockets: ${result}' );
        #end

        if ( result.read != null ) for ( i in result.read ) {

			try {

                var a = new Address();
				var len = NativeICMPSocket.socket_recv_from(i.__s, i._readBuffer.getData(), 0, i._readBuffer.length, a);
                #if CHAMPAIGN_DEBUG
                Logger.verbose( '${this} >>> ${i._readBuffer.toHex()}' );
                #end
                var packet = ICMPPacket.fromBytes( i._readBuffer );
                if ( packet == null ) break; // Not our packet

                #if CHAMPAIGN_DEBUG
                Logger.verbose( '${this} >>> ${i}, len: ${len}, ${packet}, type: ${packet.type}, code: ${packet.code}, checksum: ${packet.checksum}, sequenceNumber: ${packet.sequenceNumber}, identifier: ${packet.identifier}, header: ${packet.header}, ipVersion: ${packet.header.ipVersion}, flags: ${packet.header.flags}, headerChecksum: ${packet.header.headerChecksum}, headerLength: ${packet.header.headerLength}, identification: ${packet.header.identification}, protocol: ${packet.header.protocol}, sourceAddress: ${packet.header.getSourceIP()}, destinationAddress: ${packet.header.getDestinationIP()}, timeToLive: ${packet.header.timeToLive}, totalLength: ${packet.header.totalLength}, data: ${packet.data}, data match:${i._data==packet.data.toString()}\n .' );
                #end

                if ( a != null && a.host == i._host.host.ip ) {

                    if ( packet.type == 0 ) {

                        // Ping successful
                        i._readTime = Date.now().getTime();
                        i._written = false;
                        i._read = true;
                        i.onEvent( i, ICMPSocketEvent.Ping( i.get_pingTime() ) );
                        i._pingId++;
                        if ( i._pingId > 0xFFFF ) i._pingId = 0;
                        i._actualPingCount++;
                        i._actualSuccessfulPingCount++;

                        if ( i.count != 0 && i._pingId >= i.count ) {

                            i.onEvent( i, ICMPSocketEvent.PingStop );
                            _removeSocket( i );
            
                        }

                    } else if ( packet.type == 3 ) {

                        // Destination Unreachable
                        #if CHAMPAIGN_DEBUG
                        Logger.error( '${this} ${i} Header Type: ${packet.type} Code: ${packet.code}' );
                        #end
                        i._readTime = Date.now().getTime();
                        i._written = false;
                        i._read = true;
                        i.onEvent( i, ICMPSocketEvent.PingFailed );
                        i._pingId++;
                        if ( i._pingId > 0xFFFF ) i._pingId = 0;
                        i._actualPingCount++;

                        if ( i.count != 0 && i._pingId >= i.count ) {
                
                            i.onEvent( i, ICMPSocketEvent.PingStop );
                            _removeSocket( i );
            
                        } else {

                            i.init();

                        }

                    } else {

                        // Some other error code is returned or the packet is invalid
                        #if CHAMPAIGN_DEBUG
                        Logger.error( '${this} ${i} Header Type: ${packet.type} Code: ${packet.code}' );
                        #end

                    }

                }

			} catch ( e ) {

				#if CHAMPAIGN_DEBUG
                Logger.error( '${this} ${i} Read Error: ${e}' );
                #end
                i.onEvent( i, ICMPSocketEvent.PingError );
				if ( i._stopOnError ) _removeSocket( i );
                i._pingId++;
                if ( i._pingId > 0xFFFF ) i._pingId = 0;
                i._actualPingCount++;

			}

		}

		if ( result.write != null ) for ( i in result.write ) {

			try {

                if ( i._randomizeData ) i.createData();
				i._writeTime = Date.now().getTime();
                i._byteData[6] = i._pingId;
                i._byteData[7] = i._pingId >> 8;
				var checksum = NativeICMPSocket.socket_send_to(i.__s, i._byteData, 0, i._byteData.length, i._address, i._pingId, i._id );
                #if CHAMPAIGN_VERBOSE
                Logger.verbose( '${this} ${i} Data Written to ${i._address.getHost()}, PingId: ${i._pingId}' );
                Logger.verbose( '${this} ${i} Written Data Checksum: ${StringTools.hex(checksum)}' );
                #end
                i._checksum = checksum;
				i._written = true;
				i._read = false;

			} catch ( e:Eof ) {

				#if CHAMPAIGN_DEBUG
                Logger.error( '${this} ${i} Write Error: ${e} ${i.hostname}' );
                #end
                i.onEvent( i, ICMPSocketEvent.PingError );

                if ( i._stopOnError ){

                    _removeSocket( i );

                } else {

                    // Re-initialize the ICMPSocket in case of EOF
                    i.init();

                }

			} catch ( e ) {

				#if CHAMPAIGN_DEBUG
                Logger.error( '${this} ${i} Write Error: ${e} ${i.hostname}' );
                #end
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
                    i._pingId++;
                    i._actualPingCount++;

                    if ( i.count != 0 && i._pingId >= i.count ) {
            
                        i.onEvent( i, ICMPSocketEvent.PingStop );
                        _removeSocket( i );
        
                    } else {

                        i.init();

                    }

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

private typedef ICMPSocketThreadList = List<ICMPSocketThread>;