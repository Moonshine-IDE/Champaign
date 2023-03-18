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

import champaign.cpp.externs.NativeNetwork;
import haxe.Json;

#if !cpp
#error "Network is not supported on this target (no C++ support)"
#end

class Network {

	/**
	 * Returns some of the DNS records of the given host
	 * @param host The name of the host
	 * @return `HostInfo`
	 */
	static public function getHostInfo( hostName:String ):HostInfo {
		
		var c:HostInfo = NativeNetwork.__getAddrInfo( hostName );
		return c;

	}

	/**
	 * Returns the NetworkInterfaces found on the system.
	 * @param flags Use bitwise OR to query network interfaces with multiple flags.
	 * Loopback devices are not part of the result unless `NetworkInterfaceFlag.IsLoopback` is explicitly set
	 * @return The `NetworkInterfaces` object
	 */
	static public function getNetworkInterfaces( flags:NetworkInterfaceFlag = NetworkInterfaceFlag.All ):NetworkInterfaces {

		var data:Dynamic = NativeNetwork.__getNetworkInterfaces( false );
		var result:NetworkInterfaces = { success: false, errorCode: 1 };

		try {

			if ( data.success != true ) {

				result.success = false;
				result.errorCode = data.errorCode;

			} else {

				var entries:Array<Dynamic> = Reflect.field( data, "entries" );

				if ( entries != null ) {

					for ( e in entries ) {

						var name = e.name;
						if ( result.entries == null ) result.entries = new Map();
						var entryData:NetworkInterfaceEntry = ( result.entries.exists( name ) ) ? result.entries.get( name ) : { name: name };
						if ( e.enabled != null ) entryData.enabled = cast e.enabled;
						if ( e.loopback != null ) entryData.loopback = cast e.loopback;
						if ( e.flags != null ) entryData.flags = cast e.flags;
						if ( e.ipv4netmask != null ) entryData.ipv4netmask = cast e.ipv4netmask;
						if ( e.ipv4 != null ) entryData.ipv4 = cast e.ipv4;
						if ( e.ipv6netmask != null ) entryData.ipv6netmask = cast e.ipv6netmask;
						if ( e.ipv6 != null ) entryData.ipv6 = cast e.ipv6;
						if ( e.broadcast != null ) entryData.broadcast = cast e.broadcast;
						if ( e.broadcastAddress != null ) entryData.broadcastAddress = cast e.broadcastAddress;
						if ( e.running != null ) entryData.running = cast e.running;
						result.entries.set( name, entryData );

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
