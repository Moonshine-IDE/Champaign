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

package;

import feathers.controls.Application;
import feathers.controls.Button;
import feathers.controls.LayoutGroup;
import feathers.controls.TextArea;
import feathers.controls.TextInput;
import feathers.events.TriggerEvent;
import feathers.layout.HorizontalLayout;
import feathers.layout.HorizontalLayoutData;
import feathers.layout.VerticalAlign;
import feathers.layout.VerticalLayout;
import feathers.layout.VerticalLayoutData;
import prominic.logging.Logger;
import prominic.logging.targets.SysPrintTarget;
import prominic.logging.targets.feathers.TextAreaTarget;
import prominic.sys.SysTools;
import prominic.sys.Process;
import prominic.sys.io.process.AbstractProcess;
import prominic.sys.io.process.CallbackProcess;
import prominic.sys.network.ICMPSocket;
import prominic.sys.network.Network;

class Main extends Application {

    var buttonStartPing:Button;
    var buttonStopPing:Button;
    var icmpSocket:ICMPSocket;
    var inputHost:TextInput;
    var inputProcess:TextInput;
    var textArea:TextArea;

	public function new() {

		super();

	}

    override function initialize() {

        super.initialize();

        var l = new VerticalLayout();
        l.setPadding( 10 );
        l.gap = 10;
        this.layout = l;

        var group = new LayoutGroup();
        group.layoutData = new VerticalLayoutData( 100 );
        var groupLayout = new HorizontalLayout();
        groupLayout.gap = 10;
        groupLayout.verticalAlign = VerticalAlign.MIDDLE;
        group.layout = groupLayout;
        this.addChild( group );

        var buttonNetworkInterfaces = new Button( "Network Interfaces" );
        buttonNetworkInterfaces.addEventListener( TriggerEvent.TRIGGER, _buttonNetworkInterfacesTriggered );
        group.addChild( buttonNetworkInterfaces );

        var buttonHostInfo = new Button( "HostInfo" );
        buttonHostInfo.addEventListener( TriggerEvent.TRIGGER, _buttonHostInfoTriggered );
        group.addChild( buttonHostInfo );

        inputHost = new TextInput( "www.google.com" );
        group.addChild( inputHost );

        buttonStartPing = new Button( "Start Ping" );
        buttonStartPing.addEventListener( TriggerEvent.TRIGGER, _buttonStartPingTriggered );
        group.addChild( buttonStartPing );

        buttonStopPing = new Button( "Stop Ping" );
        buttonStopPing.enabled = false;
        buttonStopPing.addEventListener( TriggerEvent.TRIGGER, _buttonStopPingTriggered );
        group.addChild( buttonStopPing );

        textArea = new TextArea();
        textArea.layoutData = new VerticalLayoutData( 100, 100 );
        textArea.editable = false;
        this.addChild( textArea );

        var buttonProcess = new Button( "Start Process" );
        buttonProcess.addEventListener( TriggerEvent.TRIGGER, _buttonProcessTriggered );
        if ( !SysTools.isIOS() ) group.addChild( buttonProcess );

        inputProcess = new TextInput( "", "eg. ls /" );
        if ( !SysTools.isIOS() ) group.addChild( inputProcess );

        var buttonClear = new Button( "Clear" );
        buttonClear.addEventListener( TriggerEvent.TRIGGER, _buttonClearTriggered );
        group.addChild( buttonClear );

		Logger.init( LogLevel.Debug );
        Logger.addTarget( new SysPrintTarget( LogLevel.Debug, true, false, true ) );
        Logger.addTarget( new TextAreaTarget( LogLevel.Debug, true, false, textArea ) );

        Logger.info( "Hello, Network App!" );
        Logger.info( 'System: ${SysTools.systemName()}' );
        #if cpp
        Logger.info( 'Is current user root?: ${(Process.isUserRoot())? "YES" : "NO"}' );
        #end

    }

    function _buttonNetworkInterfacesTriggered( e:TriggerEvent ) {

        Logger.info( 'Querying Network Interfaces that are enabled and have IPv4 address');
        var networkInterfaces = Network.getNetworkInterfaces( NetworkInterfaceFlag.Enabled | NetworkInterfaceFlag.HasIPv4 );

        for ( i in networkInterfaces.entries ) {

            Logger.info( '---' );
            Logger.info( 'Network Interface: ${i.name}' );
            Logger.info( '\tEnabled: ${i.enabled}' );
            Logger.info( '\tLoopback: ${i.loopback}' );
            Logger.info( '\tIPv4: ${i.ipv4}' );
            Logger.info( '\tIPv6: ${i.ipv6}' );

        }

    }

    function _buttonHostInfoTriggered( e:TriggerEvent ) {

        var hostName = inputHost.text;
        var hostInfo = Network.getHostInfo( hostName );
        Logger.info( 'HostInfo of ${hostName}: ${hostInfo}');

    }

    function _buttonProcessTriggered( e:TriggerEvent ) {

        if ( StringTools.trim( inputProcess.text ) == "" ) return;

        var p = new CallbackProcess( inputProcess.text );
        p.onStdOut = _onProcessStdOut;
        p.onStop = _onProcessStop;
        p.start();

    }

    function _buttonClearTriggered( e:TriggerEvent ) {

        textArea.text = "";

    }

    function _onProcessStdOut( ?process:AbstractProcess ) {

        Logger.info( 'Process standard output:\n${process.stdoutBuffer.getAll()}' );

    }
    
    function _onProcessStop( ?process:AbstractProcess ) {

        Logger.info( "Process stopped" );

    }

    function _buttonStartPingTriggered( e:TriggerEvent ) {

        if ( icmpSocket == null ) {

            icmpSocket = new ICMPSocket( inputHost.text );
            icmpSocket.onHostError= onHostError;
            icmpSocket.onPing = onPing;
            icmpSocket.onPingFinished = onPingFinished;
            icmpSocket.onError = onPingError;
            icmpSocket.onTimeout = onTimeout;
            icmpSocket.ping( 0 );

            buttonStopPing.enabled = true;
            buttonStartPing.enabled = false;

        }

    }

    function _buttonStopPingTriggered( e:TriggerEvent ) {

        if ( icmpSocket != null ) {

            icmpSocket.close();
            icmpSocket = null;

            buttonStopPing.enabled = false;
            buttonStartPing.enabled = true;

        }

    }

    function onHostError( socket:ICMPSocket ) {

        Logger.error( 'Host error on: ${socket.hostname}' );
        
        _buttonStopPingTriggered( null );

    }

    function onPing( socket:ICMPSocket ) {

        Logger.info( 'Ping successful on: ${socket.hostname}, time (ms): ${socket.lastPingTime}' );

    }

    function onPingFinished( socket:ICMPSocket ) {

        Logger.info( 'Ping finished on: ${socket.hostname}' );

        _buttonStopPingTriggered( null );

    }

    function onPingError( socket:ICMPSocket ) {

        Logger.error( 'Ping error on: ${socket.hostname}' );

    }

    function onTimeout( socket:ICMPSocket ) {

        Logger.warning( 'Ping timeout on: ${socket.hostname}' );

    }

}
