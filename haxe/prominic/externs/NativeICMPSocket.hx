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

package prominic.externs;

import sys.net.Socket;

@:noDoc
@:buildXml('<include name="${haxelib:champaign}/config/network.xml" />')
@:include('ICMPSocket.h')
@:noDoc
extern class NativeICMPSocket {
	@:native("_icmp_socket_init")
	static function socket_init():Void;

	@:native("_icmp_socket_new")
	static function socket_new(udp:Bool):Dynamic;

	@:native("_icmp_socket_new")
	static function socket_new_ip(udp:Bool, ipv6:Bool):Dynamic;

	@:native("_icmp_socket_close")
	static function socket_close(handle:Dynamic):Void;

	@:native("_icmp_socket_bind")
	static function socket_bind(o:Dynamic, host:Int, port:Int):Void;

	@:native("_icmp_socket_bind_ipv6")
	static function socket_bind_ipv6(o:Dynamic, host:haxe.io.BytesData, port:Int):Void;

	@:native("_icmp_socket_send_char")
	static function socket_send_char(o:Dynamic, c:Int):Void;

	@:native("_icmp_socket_send")
	static function socket_send(o:Dynamic, buf:haxe.io.BytesData, p:Int, l:Int):Int;

	@:native("_icmp_socket_recv")
	static function socket_recv(o:Dynamic, buf:haxe.io.BytesData, p:Int, l:Int):Int;

	@:native("_icmp_socket_recv_char")
	static function socket_recv_char(o:Dynamic):Int;

	@:native("_icmp_socket_write")
	static function socket_write(o:Dynamic, buf:haxe.io.BytesData):Void;

	@:native("_icmp_socket_read")
	static function socket_read(o:Dynamic):haxe.io.BytesData;

	@:native("_icmp_host_resolve_ipv6")
	static function host_resolve_ipv6(host:String):haxe.io.BytesData;

	@:native("_icmp_host_resolve")
	static function host_resolve(host:String):Int;

	@:native("_icmp_host_to_string")
	static function host_to_string(ip:Int):String;

	@:native("_icmp_host_to_string_ipv6")
	static function host_to_string_ipv6(ipv6:haxe.io.BytesData):String;

	@:native("_icmp_host_reverse")
	static function host_reverse(host:Int):String;

	@:native("_icmp_host_reverse_ipv6")
	static function host_reverse_ipv6(ipv6:haxe.io.BytesData):String;

	@:native("_icmp_host_local")
	static function host_local():String;

	inline static function host_local_ipv6():String
		return "::1";

	@:native("_icmp_socket_connect")
	static function socket_connect(o:Dynamic, host:Int, port:Int):Void;

	@:native("_icmp_socket_connect_ipv6")
	static function socket_connect_ipv6(o:Dynamic, host:haxe.io.BytesData, port:Int):Void;

	@:native("_icmp_socket_listen")
	static function socket_listen(o:Dynamic, n:Int):Void;

	@:native("_icmp_socket_select")
	static function socket_select(rs:Array<Dynamic>, ws:Array<Dynamic>, es:Array<Dynamic>, timeout:Dynamic):Array<Dynamic>;

	@:native("_icmp_socket_fast_select")
	static function socket_fast_select(rs:Array<Dynamic>, ws:Array<Dynamic>, es:Array<Dynamic>, timeout:Dynamic):Void;

	@:native("_icmp_socket_accept")
	static function socket_accept(o:Dynamic):Dynamic;

	@:native("_icmp_socket_peer")
	static function socket_peer(o:Dynamic):Array<Int>;

	@:native("_icmp_socket_host")
	static function socket_host(o:Dynamic):Array<Int>;

	@:native("_icmp_socket_set_timeout")
	static function socket_set_timeout(o:Dynamic, t:Dynamic):Void;

	@:native("_icmp_socket_shutdown")
	static function socket_shutdown(o:Dynamic, r:Bool, w:Bool):Void;

	@:native("_icmp_socket_set_blocking")
	static function socket_set_blocking(o:Dynamic, b:Bool):Void;

	@:native("_icmp_socket_set_fast_send")
	static function socket_set_fast_send(o:Dynamic, b:Bool):Void;

	@:native("_icmp_socket_set_broadcast")
	static function socket_set_broadcast(o:Dynamic, b:Bool):Void;

	@:native("_icmp_socket_poll_alloc")
	static function socket_poll_alloc(nsocks:Int):Dynamic;

	@:native("_icmp_socket_poll_prepare")
	static function socket_poll_prepare(pdata:Dynamic, rsocks:Array<Socket>, wsocks:Array<Socket>):Array<Array<Int>>;

	@:native("_icmp_socket_poll_events")
	static function socket_poll_events(pdata:Dynamic, timeout:Float):Void;

	@:native("_icmp_socket_poll")
	static function socket_poll(socks:Array<Socket>, pdata:Dynamic, timeout:Float):Array<Socket>;

	@:native("_icmp_socket_send_to")
	static function socket_send_to(o:Dynamic, buf:haxe.io.BytesData, p:Int, l:Int, inAddr:Dynamic, seqNr:Int, idNr:Int ):Int;

	@:native("_icmp_socket_recv_from")
	static function socket_recv_from(o:Dynamic, buf:haxe.io.BytesData, p:Int, l:Int, outAddr:Dynamic):Int;
}
