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

import prominic.sys.SysTools;
import prominic.logging.Logger;
import prominic.logging.targets.SysPrintTarget;
import prominic.sys.io.process.AbstractProcess;
import prominic.sys.io.process.CallbackProcess;
#if cpp
import prominic.sys.io.Process;
#end

class Spawn {

    static public function main() {

        #if !sys
        #error "Spawn is not available on this target (no Sys support)"
        #end

        Logger.init( LogLevel.Debug );
        Logger.addTarget( new SysPrintTarget( LogLevel.Debug, true, false, true ) );

        Logger.info( "Hello, Spawn App!" );
        #if cpp
        Logger.info( 'Is current user root?: ${(Process.isUserRoot())? "YES" : "NO"}' );
        #end
        Logger.info( "Now let\'s spawn a process!" );

        var p = new CallbackProcess( SysTools.isWindows() ? "dir C:\\" : "ls /" );
        p.onStdOut = _onProcessStdOut;
        p.onStop = _onProcessStop;
        p.start();

    }

    static function _onProcessStdOut( ?process:AbstractProcess ) {

        Logger.info( 'Process standard output:\n${process.stdoutBuffer.getAll()}' );

    }
    
    static function _onProcessStop( ?process:AbstractProcess ) {

        Logger.info( "Process stopped" );

    }
    
}