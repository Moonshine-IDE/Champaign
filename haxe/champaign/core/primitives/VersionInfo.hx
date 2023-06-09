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

package champaign.core.primitives;

/**
 * Abstract to handle version info in applications.
 * Converts to and from SemVer strings
 * 
 * #### Usage:
 * 
 * ```haxe
 * var versionInfoA:VersionInfo = "2.3.1";
 * var versionInfoB:VersionInfo = "2.4.0";
 * trace( versionInfoB > versionInfoA ); // true
 * ```
 */
abstract VersionInfo( Int ) {
    
    inline function new( f:Int ) {

        this = f;

    }

    @:from
    static public function fromString( input:String ) {

        var v:Int = 0;

        if ( input == null || input == "" ) new VersionInfo( v );

        var a = input.split( "." );

        if ( a.length == 1 ) {

            v = Std.parseInt( a[ 0 ] ) * 1000000;

        } else if ( a.length == 2 ) {

            v = Std.parseInt( a[ 0 ] ) * 1000000 + Std.parseInt( a[ 1 ] ) * 1000;

        } else if ( a.length == 3 ) {

            v = Std.parseInt( a[ 0 ] ) * 1000000 + Std.parseInt( a[ 1 ] ) * 1000 + Std.parseInt( a[ 2 ] );

        }

        return new VersionInfo( v );

    }

    @:to
    public function toInt():Int {

        return this;

    }

    @:to
    public function toString() {

        if ( this < 1000 ) {

            return '0.0.${this}';

        } else if ( this < 1000000 ) {

            var h = Math.floor( this / 1000 );
            var m = Math.floor( this % 1000 );
            return '0.${h}.${m}';

        } else if ( this < 1000000000 ) {

            //5 003 011;
            var h1 = Math.floor( this / 1000000 ); // 5
            var m1 = Math.floor( this % 1000000 ); // 3 011;
            var h2 = Math.floor( m1 / 1000 ); // 3
            var m2 = Math.floor( m1 % 1000 ); // 11
            return '${h1}.${h2}.${m2}';

        }

        return '0';

    }

    @:op(A > B) private static inline function gt(a:VersionInfo, b:VersionInfo):Bool {
        
        return (a : Int) > (b : Int);
    }

    @:op(A >= B) private static inline function gte(a:VersionInfo, b:VersionInfo):Bool {

        return (a : Int) >= (b : Int);

    }

    @:op(A < B) private static inline function lt(a:VersionInfo, b:VersionInfo):Bool {

        return (a : Int) < (b : Int);

    }

    @:op(A <= B) private static inline function lte(a:VersionInfo, b:VersionInfo):Bool {

        return (a : Int) <= (b : Int);

    }

    @:op(A + B) private inline function addassign(a:Int) {

        var v = new VersionInfo( (this : Int) + a );
        this = v;
        return v;

    }
    @:op(A++) private inline function plusplus() {

        var v = new VersionInfo( (this : Int) + 1 );
        this = v;
        return v;

    }

}