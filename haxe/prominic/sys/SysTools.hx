package prominic.sys;

class SysTools {
    
    static public function isBSD():Bool {

        #if !sys
        #error "SysTools is not available on this target (no Sys support)"
        #end

        return Sys.systemName().toLowerCase().indexOf( 'bsd') == 0;

    }

    static public function isIOS():Bool {

        #if !sys
        #error "SysTools is not available on this target (no Sys support)"
        #end

        #if ( iphoneos || ios )

        return true;

        #else

        return false;

        #end

    }

    static public function isIOSSimulator():Bool {

        #if !sys
        #error "SysTools is not available on this target (no Sys support)"
        #end

        #if ( iphonesim || simulator )

        return true;

        #else

        return false;

        #end

    }

    static public function isLinux():Bool {

        #if !sys
        #error "SysTools is not available on this target (no Sys support)"
        #end

        return Sys.systemName().toLowerCase().indexOf( 'linux') == 0;

    }

    static public function isMac():Bool {

        #if !sys
        #error "SysTools is not available on this target (no Sys support)"
        #end

        return Sys.systemName().toLowerCase().indexOf( 'mac') == 0;

    }

    static public function isWindows():Bool {

        #if !sys
        #error "SysTools is not available on this target (no Sys support)"
        #end

        return Sys.systemName().toLowerCase().indexOf( 'windows') == 0;

    }

    static public function systemName():String {

        #if ( iphoneos || ios )
        return "iOS";
        #end

        #if ( iphonesim || simulator )
        return "iOS Simulator";
        #end

        #if ( android )
        return "Android";
        #end
        
        return Sys.systemName();

    }

}