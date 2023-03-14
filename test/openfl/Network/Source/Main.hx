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
import prominic.sys.io.Process;
import prominic.sys.io.process.AbstractProcess;
import prominic.sys.io.process.CallbackProcess;
import prominic.sys.network.Network;

class Main extends Application {

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

}
