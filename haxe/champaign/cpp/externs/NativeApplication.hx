package champaign.cpp.externs;

@:buildXml('<include name="${haxelib:champaign}/config/application.xml" />')
@:keep
@:include('CApplication.h')
@:allow( prominic.sys.network )
@:noDoc
extern class NativeApplication {
    
    @:native('NS_Champaign_Application::__isBounceIconSupported')
	static function __isBounceIconSupported():Bool;

    @:native('NS_Champaign_Application::__bounceIcon')
	static function __bounceIcon( isCritical:Bool ):Void;

}