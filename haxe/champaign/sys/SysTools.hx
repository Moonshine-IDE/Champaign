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

package champaign.sys;

import haxe.io.Bytes;
import sys.FileSystem;

class SysTools {

    static var _isLittleEndian:Null<Bool>;
    static var _isRaspberryPi:Null<Bool>;
    
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

    static public function isRaspberryPi():Bool {

        if ( _isRaspberryPi != null ) return _isRaspberryPi;

        var modelFile = '/sys/firmware/devicetree/base/model';

        if( !FileSystem.exists( modelFile ) )

            _isRaspberryPi = false;

        try {

            var model = sys.io.File.getContent( modelFile );
            _isRaspberryPi = ~/Raspberry/.match( model );

        } catch(e:Dynamic) {}

        _isRaspberryPi = false;

        return _isRaspberryPi;

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

    static public function isLittleEndian():Bool {

        if ( _isLittleEndian != null ) return _isLittleEndian;

        var b = Bytes.alloc( 4 );
        b.set( 0, 1 );
        b.set( 1, 0 );
        b.set( 2, 0 );
        b.set( 3, 0 );
        _isLittleEndian = b.getInt32( 0 ) == 1;

        return _isLittleEndian;

    }

}