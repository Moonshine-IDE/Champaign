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

import champaign.cpp.process.Process;
import champaign.core.logging.Logger;
import champaign.cpp.network.Network;
import champaign.cpp.network.Pinger;
import champaign.desktop.application.Application;
import champaign.sys.logging.targets.SysPrintTarget;

class Net {

    static var numPings:Int = 0;
    static var failedPings:Map<String, Int> = [];
    static var successfulPings:Map<String, Int> = [];
    static var timeoutPings:Map<String, Int> = [];

    static public function main() {

        Logger.init( LogLevel.Verbose );
        Logger.addTarget( new SysPrintTarget( LogLevel.Verbose, true, false, true ) );

        Logger.info( "Hello, Network App!" );

        Logger.info( 'supportsBounceDockIcon: ${Application.supportsBounceDockIcon()}' );

        var hostInfo = Network.getHostInfo( "www.google.com" );
        Logger.info( 'HostInfo of www.google.com: ${hostInfo}');

        var nonExistentHostInfo = Network.getHostInfo( "www.nonexistent-domainname.org" );
        Logger.info( 'HostInfo of www.nonexistent-domainname.org: ${nonExistentHostInfo}');

        Logger.info( 'Querying Network Interfaces with IPv4 address');
        var networkInterfaces = Network.getNetworkInterfaces( NetworkInterfaceFlag.Enabled | NetworkInterfaceFlag.HasIPv4 );

        Logger.info( 'Setting resource limit to 4096... ${Process.setFileResourceLimit( 4096 )}');

        for ( i in networkInterfaces.entries ) {

            Logger.info( 'Network Interface: ${i.name}' );
            Logger.info( '\tEnabled: ${i.enabled}' );
            Logger.info( '\tLoopback: ${i.loopback}' );
            Logger.info( '\tIPv4: ${i.ipv4}' );
            Logger.info( '\tIPv6: ${i.ipv6}' );

        }

        //for ( i in 1...255 ) Sys.println( '192.168.0.${i}' );
        //for ( i in 1...255 ) Sys.println( '192.168.0.${i}' );
        //for ( i in 1...255 ) Sys.println( '142.251.39.${i}' );

        pinger();

        Sys.sleep( 600 );

    }

    static function pinger() {

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

        var a:Array<String> = [];
        //for ( i in 1...100 ) a.push( '192.168.0.${i}' );
        //for ( i in 100...110 ) a.push( '192.168.0.${i}' );
        for ( i in 0...256 ) a.push( '142.251.39.${i}' );

        /*
        for ( i in 0...1 ) {

            a.push( '199.103.3.49' );
            a.push( '199.103.6.35' );
            a.push( '199.103.5.15' );
            a.push( '199.103.7.50' );
            a.push( '199.103.5.64' );
            a.push( '199.103.2.101' );

        }
        */

        Pinger.init( { useBlockingSockets: false, useEventLoops:false, keepThreadsAlive: false, threadEventLoopInterval: 0 } );
        Pinger.onPingEvent.add( onPingEvent );
        Pinger.onStop.add( onPingStopped );

        Pinger.startPings( a, 10, 2000 );
        //for ( h in a ) Pinger.startPing( h, 5 );

    }

    static function onPingEvent( address:String, event:PingEvent ) {

        numPings++;

        if ( !failedPings.exists( address ) ) failedPings.set( address, 0 );
        if ( !successfulPings.exists( address ) ) successfulPings.set( address, 0 );
        if ( !timeoutPings.exists( address ) ) timeoutPings.set( address, 0 );

        switch ( event ) {

            case PingEvent.HostError:
                Logger.error( 'Host error on: ${address}' );
                failedPings.set( address, failedPings.get( address ) + 1 );

            case PingEvent.Ping( t ):
                Logger.info( 'Ping successful on ${address}. Time (ms): ${t}' );
                successfulPings.set( address, successfulPings.get( address ) + 1 );

            case PingEvent.PingError:
                Logger.error( 'Ping error on ${address}' );
                failedPings.set( address, failedPings.get( address ) + 1 );
                //Pinger.stopPing( address );

            case PingEvent.PingFailed:
                Logger.warning( 'Destination unreachable on ${address}' );
                failedPings.set( address, failedPings.get( address ) + 1 );

            case PingEvent.PingStop:
                Logger.info( 'Ping stopped on ${address}' );

            case PingEvent.PingTimeout:
                Logger.warning( 'Ping timeout on ${address}' );
                timeoutPings.set( address, timeoutPings.get( address ) + 1 );


            default:

        }

        Logger.debug( 'Ping info on ${address}: Success: ${successfulPings.get( address )}, Timeout: ${timeoutPings.get( address )}, Failed: ${failedPings.get( address )}' );

        //if ( numPings > 800 ) Pinger.stopAllPings();

    }

    static function onPingStopped() {

        Logger.info( 'All pings have stopped' );

        var ts = 0;
        var tt = 0;
        var tf = 0;

        var sp:Array<String> = [];
        var tp:Array<String> = [];
        var fp:Array<String> = [];
        var pp:Array<String> = [];
        
        for ( address in successfulPings.keys() ) {

            var s = successfulPings.get( address );
            var t = timeoutPings.get( address );
            var f = failedPings.get( address );
            var pf = ( t + f ) / ( s + t + f );
            var p = Std.int( pf  * 100 );

            ts += s;
            tt += t;
            tf += f;

            if ( pf == 0 ) sp.push( address );
            if ( t > 0 ) tp.push( address );
            if ( f > 0 ) fp.push( address );

            if ( s > 0 && t > 0 ) {

                if ( f > 0 ) {

                    Logger.error( 'Ping results for ${address}: Success: ${s}, Timeout: ${t}, Failed: ${f}, Packet loss: ${p}%' );

                } else {

                    Logger.warning( 'Ping results for ${address}: Success: ${s}, Timeout: ${t}, Failed: ${f}, Packet loss: ${p}%' );

                }

            } else {

                Logger.debug( 'Ping results for ${address}: Success: ${s}, Timeout: ${t}, Failed: ${f}, Packet loss: ${p}%' );

            }

        }

        var tpp = Std.int( ( ( tt + tf ) / ( ts + tt + tf ) ) * 100 );
        Logger.debug( 'Total Pings: ${ts + tt + tf}, Success: ${ts}, Timeout: ${tt}, Failed: ${tf}, Packet loss: ${tpp}%' );
        Logger.debug( 'Total Stats: Successful hosts: ${sp.length}, Timeout hosts: ${tp.length}, Failed hosts: ${fp.length}' );

        Sys.exit( 0 );

    }

}