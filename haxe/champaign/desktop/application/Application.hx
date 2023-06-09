package champaign.desktop.application;

import champaign.cpp.externs.NativeApplication;

class Application {

    /**
     * Bounces the Dock icon if the app window is not in the foreground.
     * Check `supportsDockBounceIcon()` to determine if icon bounce is supported
     * on the current platform. (Currently only macOS supports it, it doesn't
     * do anything on other platforms)
     * @param isCritical If false, the Dock icon will bounce once, if true,
     * it will bounce until the application is activated
     */
    static public function bounceDockIcon( isCritical:Bool = false ):Void {

        NativeApplication.__bounceDockIcon( isCritical );

    }
    
    /**
     * Returns true if Dock icon bounce is supported on the current platform
     * @return Bool
     */
    static public function supportsBounceDockIcon():Bool {

        return NativeApplication.__isBounceDockIconSupported();

    }
    
}