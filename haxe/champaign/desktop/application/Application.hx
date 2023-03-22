package champaign.desktop.application;

import champaign.cpp.externs.NativeApplication;

class Application {

    static public function bounceIcon( isCritical:Bool = false ):Void {

        NativeApplication.__bounceIcon( isCritical );

    }
    
    static public function supportsBounceIcon():Bool {

        return NativeApplication.__isBounceIconSupported();

    }
    
}