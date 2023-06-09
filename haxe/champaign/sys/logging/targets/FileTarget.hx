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

package champaign.sys.logging.targets;

import champaign.core.logging.Logger;
import champaign.core.logging.targets.AbstractLoggerTarget;
import haxe.Json;
import haxe.ds.BalancedTree;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#if ( target.threaded )
import sys.thread.Deque;
import sys.thread.Thread;
#end

/**
 * A log target that prints messages to files.
 * Can only be used on target where the sys package is available
 */
class FileTarget extends AbstractLoggerTarget {

    #if windows
    static final _LINE_ENDING:String = '\r\n';
    #else
    static final _LINE_ENDING:String = '\n';
    #end

    #if ( target.threaded )
    static var _messageProcessingThread:Thread;
    static var _messageQue:Deque<LoggerFormattedMessage>;
    #end

    var _clearLogFile:Bool;
    var _currentLogFilePath:String;
    var _directory:String;
    var _filename:String;
    var _numLogFiles:Int;
    var _useThread:Bool;

    public var currentLogFilePath( get, never ):String;
    function get_currentLogFilePath() return _currentLogFilePath;
    
    /**
     * Creates a log target that prints messages to files in a specified directory
     * @param directory The root directory of the log files
     * @param filename The name of the currently used log file. The rest of the files will be generated and named automatically
     * @param numLogFiles The number of log files to keep. If 0, only the log file with the name filename will be kept, the rest of log files will be purged from the directory
     * @param logLevel Default log level. Any messages with higher level than this will not be logged
     * @param printTime Prints a time-stamp for every message logged, if true
     * @param machineReadable Prints messages in machine-readable format (Json string)
     * @param clearLogFile Clears and resets log file, if true. If false, logs will be appended to the existing log file
     * @param useThread If true, log messages will be processed printed in a newly created thread. Note: all instances of
     * FileTarget will use the same thread
     */
    public function new( directory:String, ?filename:String = "current.txt", ?numLogFiles:Int = 9, logLevel:LogLevel = LogLevel.Info, printTime:Bool = false, machineReadable:Bool = false, clearLogFile:Bool = true, useThread:Bool = false ) {

        #if !sys
        #error "FileTarget is not available on this target (no Sys support)"
        #end

        super( logLevel, printTime, machineReadable );

        _directory = Path.addTrailingSlash( Path.normalize( directory ) );
        _filename = filename;
        _numLogFiles = numLogFiles;
        _currentLogFilePath = ( _directory != null && filename != null ) ? _directory + filename : null;
        _clearLogFile = clearLogFile;
        _useThread = useThread;
        directoryMaintenance();

        #if ( target.threaded )
        if ( _useThread && _messageProcessingThread == null ) {

            _messageQue = new Deque();
            _messageProcessingThread = Thread.create( _processMessageQue );

        }
        #end

    }

    /**
     * Clears the current log file
     */
    override function clear() {

        try {

            var o = File.write( _currentLogFilePath );
            o.writeString( '' );
            o.flush();
            o.close();

        } catch ( e ) { }

    }

    function directoryMaintenance() {

        if ( _currentLogFilePath != null ) {

            // Directory maintenance

            try {

                // Creating log directory
                FileSystem.createDirectory( _directory );

                // If current.txt already exists, rename it
                if ( FileSystem.exists( _currentLogFilePath ) ) {

                    var f = FileSystem.stat( _currentLogFilePath );
                    var nn = StringTools.replace( StringTools.replace( Path.withoutExtension( _filename ) + "-" + f.mtime.toString() + ".txt", ":", "-" ), " ", "-" );
                    File.copy( _currentLogFilePath, _directory + nn );
                    if ( _clearLogFile ) FileSystem.deleteFile( _currentLogFilePath );

                }

                // Getting file list
                var a = FileSystem.readDirectory( _directory );
                var b:Array<String> = [];
                var pattern:EReg = new EReg( '^(?:${Path.withoutExtension( _filename )}){1}(?:-){1}(?:[a-zA-Z0-9-]+)(?:.)(?:txt)$', '' );
                for ( f in a ) if ( pattern.match( f ) ) b.push( f );

                // Sorting files by modification date
                var m:BalancedTree<String, String> = new BalancedTree();
                for ( f in b ) m.set( Std.string( FileSystem.stat( _directory + f ).mtime.getTime() ), f );

                var c:Array<String> = [];
                for ( d in m.keys() ) c.push( m.get( d ) );

                // Deleting files
                if ( c.length > _numLogFiles ) {

                    for ( i in 0...c.length-_numLogFiles ) FileSystem.deleteFile( _directory + c[ i ] );
                    c.reverse();
                    c.resize( _numLogFiles );
                    c.reverse();

                }

                // Copying latest entry to last.txt
                File.copy( _directory + c[ c.length-1 ], _directory + "last.txt" );

            } catch ( e ) {}

            if ( _clearLogFile ) File.saveContent( _currentLogFilePath, "" );

        }

    }

    function loggerFunction( message:LoggerFormattedMessage ) {

        if ( !enabled ) return;

        if ( message.level > _logLevel ) return;

        #if ( target.threaded )
        if ( _useThread && _messageProcessingThread != null ) {

            _messageQue.add( message );

        } else {

            _printMessage( message );

        }
        #else
        _printMessage( message );
        #end

    }

    function _printMessage( message:LoggerFormattedMessage ) {

        if ( _machineReadable ) {

            try {

                var o = File.append( _currentLogFilePath );
                for ( f in _filters.keys() ) message.message = StringTools.replace( message.message, f, _filters[ f ] );
                o.writeString( Json.stringify( message ) + _LINE_ENDING );
                o.flush();
                o.close();

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
            for ( f in _filters.keys() ) {
                trace( '!!!! ${f} ${_filters[ f ]}');
                m = StringTools.replace( m, f, _filters[ f ] );
            }

            if ( message.custom != null ) m += ' [Custom: ${message.custom}]';

            try {

                var o = File.append( _currentLogFilePath );
                o.writeString( m + _LINE_ENDING );
                o.flush();
                o.close();

            } catch ( e ) { }

        }

    }

    function _processMessageQue() {

        #if ( target.threaded )

        while( true ) {

            var message = _messageQue.pop( true );
            _printMessage( message );

        }

        #end

    }

}