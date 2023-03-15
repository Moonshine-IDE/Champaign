package prominic.externs;

import cpp.ConstCharStar;

@:buildXml('<include name="${haxelib:champaign}/config/network.xml" />')
@:keep
@:include('CNetwork.h')
@:allow( prominic.sys.network )
@:noDoc
extern class NativeNetwork {

	@:native('NS_Champaign_Network::__getAddrInfo')
	static function __getAddrInfo(host:ConstCharStar):ConstCharStar;

	@:native('NS_Champaign_Network::__getNetworkInterfaces')
	static function __getNetworkInterfaces(ignoreLoopbackInterfaces:Bool):ConstCharStar;

}