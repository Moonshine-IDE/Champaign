import prominic.logging.Logger;
import prominic.logging.targets.SysPrintTarget;
import prominic.sys.network.Network;
import prominic.sys.network.ICMPSocket;

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