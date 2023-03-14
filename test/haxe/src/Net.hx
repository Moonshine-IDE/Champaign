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

import prominic.logging.Logger;
import prominic.logging.targets.SysPrintTarget;
import prominic.sys.network.ICMPSocket;
import prominic.sys.network.Network;

class Net {

    static public function main() {

        Logger.init( LogLevel.Debug );
        Logger.addTarget( new SysPrintTarget( LogLevel.Debug, true, false, true ) );

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

        var socket = new ICMPSocket( 'www.moonshine-ide.com' );
        socket.onHostError= onHostError;
        socket.onPing = onPing;
        socket.onPingFinished = onPingFinished;
        socket.onError = onPingError;
        socket.onTimeout = onTimeout;
        socket.ping( 4 );

        var socket2 = new ICMPSocket( 'www.google.com' );
        socket2.onHostError= onHostError;
        socket2.onPing = onPing;
        socket2.onPingFinished = onPingFinished;
        socket2.onError = onPingError;
        socket2.onTimeout = onTimeout;
        socket2.ping( 4, 2000, 2000 );

        var socket3 = new ICMPSocket( '127.0.0.2' );
        socket3.onHostError= onHostError;
        socket3.onPing = onPing;
        socket3.onPingFinished = onPingFinished;
        socket3.onError = onPingError;
        socket3.onTimeout = onTimeout;
        socket3.ping( 4 );

        var socket4 = new ICMPSocket( '192.168.0.102' );
        socket4.onHostError= onHostError;
        socket4.onPing = onPing;
        socket4.onPingFinished = onPingFinished;
        socket4.onError = onPingError;
        socket4.onTimeout = onTimeout;
        socket4.ping( 4 );

        var socket5 = new ICMPSocket( 'www.cnn.com' );
        socket5.onHostError= onHostError;
        socket5.onPing = onPing;
        socket5.onPingFinished = onPingFinished;
        socket5.onError = onPingError;
        socket5.onTimeout = onTimeout;
        socket5.ping( 2 );

        Sys.sleep( 6 );
        socket.close();
        socket2.close();
        socket3.close();
        socket4.close();
        socket5.close();

    }

    static function onHostError( socket:ICMPSocket ) {

        Logger.error( 'Host error on: ${socket.hostname}' );

    }

    static function onPing( socket:ICMPSocket ) {

        Logger.info( 'Ping successful on ${socket.hostname}. Time (ms): ${socket.lastPingTime}' );

    }

    static function onPingError( socket:ICMPSocket ) {

        Logger.error( 'Ping error on ${socket.hostname}' );

    }

    static function onPingFinished( socket:ICMPSocket ) {

        Logger.info( 'Ping finished on ${socket.hostname}' );

    }

    static function onTimeout( socket:ICMPSocket ) {

        Logger.warning( 'Ping timeout on ${socket.hostname}' );

    }

}