package champaign.cpp.externs;

@:buildXml('<include name="${haxelib:champaign}/config/application.xml" />')
@:keep
@:include('CApplication.h')
@:allow( prominic.sys.network )
@:noDoc
extern class NativeApplication {
    
    @:native('NS_Champaign_Application::__isBounceDockIconSupported')
	static function __isBounceDockIconSupported():Bool;

    @:native('NS_Champaign_Application::__bounceDockIcon')
	static function __bounceDockIcon( isCritical:Bool ):Void;

}