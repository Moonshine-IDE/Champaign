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

import champaign.core.logging.Logger;
import champaign.cpp.network.ICMPSocket;
import champaign.cpp.network.ICMPSocketManager;
import champaign.cpp.network.Network;
import champaign.sys.logging.targets.SysPrintTarget;

class Net {

    static public function main() {

        Logger.init( LogLevel.Verbose );
        Logger.addTarget( new SysPrintTarget( LogLevel.Verbose, true, false, true ) );

        Logger.info( "Hello, Network App!" );

        var hostInfo = Network.getHostInfo( "www.google.com" );
        Logger.info( 'HostInfo of www.google.com: ${hostInfo}');

        var nonExistentHostInfo = Network.getHostInfo( "www.nonexistent-domainname.org" );
        Logger.info( 'HostInfo of www.nonexistent-domainname.org: ${nonExistentHostInfo}');

        Logger.info( 'Querying Network Interfaces with IPv4 address');
        var networkInterfaces = Network.getNetworkInterfaces( NetworkInterfaceFlag.Enabled | NetworkInterfaceFlag.HasIPv4 );

        for ( i in networkInterfaces.entries ) {

            Logger.info( 'Network Interface: ${i.name}' );
            Logger.info( '\tEnabled: ${i.enabled}' );
            Logger.info( '\tLoopback: ${i.loopback}' );
            Logger.info( '\tIPv4: ${i.ipv4}' );
            Logger.info( '\tIPv6: ${i.ipv6}' );

        }

        var a:Array<String> = [
            'www.moonshine-ide.com',
            'www.google.com',
            /*
            'localhost',
            '127.0.0.2',
            '192.168.0.102',
            'www.cnn.com',
            */
        ];

        #if CHAMPAIGN_DEBUG
        ICMPSocketManager.threadEventLoopInterval = 100;
        #end

        //var a:Array<String> = [];
        //for ( i in 200...203 ) a.push( '192.168.0.${i}' );
        //for ( i in 1...5 ) a.push( '127.0.0.${i}' );

        for ( h in a ) {

            var _socket = ICMPSocketManager.create( h );
            _socket.onEvent = onSocketEvent;
            _socket.ping( 4 );

        }

        ICMPSocketManager.setDelayForEverySocket( 1000 );

        Sys.sleep( 60 );

    }

    static function onSocketEvent( socket:ICMPSocket, event:ICMPSocketEvent ) {

        switch ( event ) {

            case ICMPSocketEvent.HostError:
                Logger.error( 'Host error on: ${socket.hostname}' );

            case ICMPSocketEvent.Ping( t ):
                Logger.info( 'Ping successful on ${socket.hostname}. Time (ms): ${t}' );

            case ICMPSocketEvent.PingError:
                Logger.error( 'Ping error on ${socket.hostname}' );

            case ICMPSocketEvent.PingFailed:
                Logger.warning( 'Destination unreachable on ${socket.hostname}' );

            case ICMPSocketEvent.PingStop:
                Logger.info( 'Ping stopped on ${socket.hostname}' );
                socket.close();

            case ICMPSocketEvent.PingTimeout:
                Logger.warning( 'Ping timeout on ${socket.hostname}' );

            default:

        }

    }

}