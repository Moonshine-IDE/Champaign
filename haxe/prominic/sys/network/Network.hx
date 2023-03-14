package prominic.sys.network;

import cpp.ConstCharStar;
import haxe.Json;

#if !cpp
#error "Network is not supported on this target (no C++ support)"
#end

@:buildXml('<include name="${haxelib:champaign}/config/network.xml" />')
@:keep
@:include('CNetwork.h')
private extern class Champaign_Network {

	@:native('NS_Champaign_Network::__getAddrInfo')
	static function __getAddrInfo(host:ConstCharStar):ConstCharStar;

	@:native('NS_Champaign_Network::__getNetworkInterfaces')
	static function __getNetworkInterfaces(ignoreLoopbackInterfaces:Bool):ConstCharStar;

}

class Network {

	/**
	 * Returns some of the DNS records of the given host
	 * @param host The name of the host
	 * @return `HostInfo`
	 */
	static public function getHostInfo( hostName:String ):HostInfo {
		
		var c:ConstCharStar = Champaign_Network.__getAddrInfo( ConstCharStar.fromString( hostName ) );
		var s = c.toString();
		var r:HostInfo = { success: false, errorCode: 1 };

		try {

			r = Json.parse( s );

		} catch( e ) {}

		if ( r != null ) return r;

		return null;

	}

	/**
	 * Returns the NetworkInterfaces found on the system.
	 * @param flags Use bitwise OR to query network interfaces with multiple flags.
	 * Loopback devices are not part of the result unless `NetworkInterfaceFlag.IsLoopback` is explicitly set
	 * @return The `NetworkInterfaces` object
	 */
	static public function getNetworkInterfaces( flags:NetworkInterfaceFlag = NetworkInterfaceFlag.All ):NetworkInterfaces {

		var c:ConstCharStar = Champaign_Network.__getNetworkInterfaces( false );
		var s = c.toString();
		var result:NetworkInterfaces = { success: false, errorCode: 1 };

		try {

			var data = Json.parse( s );

			if ( data.success != true ) {

				result.success = false;
				result.errorCode = data.errorCode;

			} else {

				var entry = Reflect.field( data, "entries" );

				if ( entry != null ) {

					var fields = Reflect.fields( entry );

					for ( field in fields ) {

						if ( result.entries == null ) result.entries = new Map(); 
						var entryData:NetworkInterfaceEntry = cast Reflect.field( entry, field );
						result.entries.set( field, entryData );

					}

				}

				for ( key in result.entries.keys() ) {

					if ( flags & NetworkInterfaceFlag.All == NetworkInterfaceFlag.All ) {} // Do Nothing

					if ( ( flags & NetworkInterfaceFlag.Enabled == NetworkInterfaceFlag.Enabled ) && !result.entries.get( key ).enabled ) {

						result.entries.remove( key );
						continue;

					}

					if ( ( flags & NetworkInterfaceFlag.HasIPv4 == NetworkInterfaceFlag.HasIPv4 ) && ( result.entries.get( key ).ipv4 == null ) ) {

						result.entries.remove( key );
						continue;

					}

					if ( ( flags & NetworkInterfaceFlag.HasIPv6 == NetworkInterfaceFlag.HasIPv6 ) && ( result.entries.get( key ).ipv6 == null ) ) {

						result.entries.remove( key );
						continue;

					}

					if ( ( flags & NetworkInterfaceFlag.IsLoopback == NetworkInterfaceFlag.IsLoopback ) && !result.entries.get( key ).loopback ) {

						result.entries.remove( key );
						continue;

					}

					if ( ( flags & NetworkInterfaceFlag.IsLoopback != NetworkInterfaceFlag.IsLoopback ) && result.entries.get( key ).loopback ) {

						result.entries.remove( key );
						continue;

					}

				}

			}

		} catch( e ) {}

		return result;

	}

}

typedef HostInfo = {

	?entries:Array<HostInfoEntry>,
	?errorCode:Int,
	?success:Bool,
    ?host:String,

}

typedef HostInfoEntry = {

	?canonicalName:String,
    ?ipv4:Array<String>,
    ?ipv6:Array<String>,

}

typedef NetworkInterfaces = {

	?entries:Map<String, NetworkInterfaceEntry>,
	?errorCode:Int,
	?success:Bool,

}

typedef NetworkInterfaceEntry = {

	?broadcast:Bool,
	?broadcastAddress:String,
	?enabled:Bool,
	?flags:Int,
	?ipv4:String,
	?ipv4netmask:String,
	?ipv6:String,
	?ipv6netmask:String,
	?loopback:Bool,
	?name:String,
	?running:Bool,

}

enum abstract NetworkInterfaceFlag( Int ) from Int to Int {

	var All = 0x01;
	var Enabled = 0x02;
	var HasIPv4 = 0x04;
	var HasIPv6 = 0x08;
	var IsLoopback = 0x10;

}
