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

package champaign.sys.io.process.data;

import sys.thread.Mutex;

class StringBuffer {

    var _mutex:Mutex;
    var _value:String;

    public var length( get, never ):Int;
    function get_length() return _value.length;
    
    public function new( ?value:String ) {

        _value = ( value != null ) ? value : "";
        _mutex = new Mutex();

    }

    public function add( value:String ) {

        _mutex.acquire();
        _value += value;
        _mutex.release();

    }

    public function clear() {

        _mutex.acquire();
        _value = "";
        _mutex.release();

    }

    public function get( pos:Int, ?len:Int ):String {
        
        _mutex.acquire();
        var s = _value.substr( pos, len );
        _value = StringTools.replace( _value, s, "" );
        _mutex.release();
        return s;

    }

    public function getAll():String {
        
        return this.get( 0 );

    }

}