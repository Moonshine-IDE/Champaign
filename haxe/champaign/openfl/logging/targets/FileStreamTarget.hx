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

package champaign.openfl.logging.targets;

import champaign.core.logging.Logger;
import champaign.sys.logging.targets.FileTarget;
import haxe.Json;
import haxe.ds.BalancedTree;
import haxe.io.Path;
import openfl.filesystem.File;
import openfl.filesystem.FileMode;
import openfl.filesystem.FileStream;

class FileStreamTarget extends FileTarget {

    #if windows
    static final _LINE_ENDING:String = '\r\n';
    #else
    static final _LINE_ENDING:String = '\n';
    #end

    public function new( directory:String, ?filename:String = "current.txt", ?numLogFiles:Int = 9, logLevel:LogLevel = LogLevel.Info, printTime:Bool = false, machineReadable:Bool = false, clearLogFile:Bool = true ) {

        super( directory, filename, numLogFiles, logLevel, printTime, machineReadable, clearLogFile );

    }

    override function directoryMaintenance() {

        if ( _currentLogFilePath != null ) {

            // Directory maintenance

            try {

                // Creating log directory
                var dir = new File( _directory );
                dir.createDirectory();

                var clf = new File( _currentLogFilePath );

                // If current.txt already exists, rename it
                if ( clf.exists ) {

                    var nn = StringTools.replace( StringTools.replace( Path.withoutExtension( _filename ) + "-" + clf.modificationDate.toString() + ".txt", ":", "-" ), " ", "-" );
                    clf.copyTo( new File( _directory + nn ), true );
                    if ( _clearLogFile ) clf.deleteFile();

                }

                // Getting file list
                var a = dir.getDirectoryListing();
                var b:Array<File> = [];
                var pattern:EReg = new EReg( '^(?:${Path.withoutExtension( _filename )}){1}(?:-){1}(?:[a-zA-Z0-9-]+)(?:.)(?:txt)$', '' );
                for ( f in a ) if ( pattern.match( f.name ) ) b.push( f );

                // Sorting files by modification date
                var m:BalancedTree<String, File> = new BalancedTree();
                for ( f in b ) m.set( Std.string( f.modificationDate.getTime() ), f );

                var c:Array<File> = [];
                for ( d in m.keys() ) c.push( m.get( d ) );

                // Deleting files
                if ( c.length > _numLogFiles ) {

                    for ( i in 0...c.length-_numLogFiles ) c[ i ].deleteFile();
                    c.reverse();
                    c.resize( _numLogFiles );
                    c.reverse();

                }

                // Copying latest entry to last.txt
                c[ c.length-1 ].copyTo( new File( _directory + "last.txt" ), true );

            } catch ( e ) {}

        }

    }

    override function loggerFunction( message:LoggerFormattedMessage ) {

        if ( !enabled ) return;

        if ( message.level > _logLevel ) return;

        if ( _machineReadable ) {

            try {

                var f = new File( _currentLogFilePath );
                var fs = new FileStream();
                fs.open( f, FileMode.APPEND );
                fs.writeUTFBytes( Json.stringify( message ) + _LINE_ENDING );
                fs.close();

            } catch ( e ) { }

        } else {

            var m:String = '';

            if ( _printTime ) m = '[${message.date}]';
            if ( message.entity != null ) m += '[${message.entity}]';

            // Level
            switch message.level {

                case LogLevel.Fatal:
                    m += '[FATAL]';

                case LogLevel.Error:
                    m += '[ERROR]';

                case LogLevel.Warning:
                    m += '[WARNING]';

                case LogLevel.Info:
                    m += '[INFO]';

                case LogLevel.Debug:
                    m += '[DEBUG]';

                case LogLevel.Verbose:
                    m += '[VERBOSE]';

                default:

            }

            if ( message.source != null ) m += '[${message.source}]';

            m += ' ${message.message}';

            if ( message.custom != null ) m += ' [Custom: ${message.custom}]';

            try {

                var f = new File( _currentLogFilePath );
                var fs = new FileStream();
                fs.open( f, FileMode.APPEND );
                fs.writeUTFBytes( m + _LINE_ENDING );
                fs.close();

            } catch ( e ) { }

        }

    }


}