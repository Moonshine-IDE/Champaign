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

import champaign.core.ansi.Color;
import champaign.core.logging.Logger;
import champaign.core.logging.targets.AbstractLoggerTarget;
import haxe.Json;
#if ( target.threaded )
import sys.thread.Deque;
import sys.thread.Thread;
#end

/**
 * A log target that prints messages to stdout using Sys.println, and to stderr using Sys.stderr().writeString().
 * Can only be used on targets where the sys package is available
 */
class SysPrintTarget extends AbstractLoggerTarget {

    #if ( target.threaded )
    static var _messageProcessingThread:Thread;
    static var _messageQue:Deque<LoggerFormattedMessage>;
    #end

    var _useColoredOutput:Bool;
    var _useThread:Bool;
    
    /**
     * Creates a log target that prints messages to stdout using Sys.println(), and to stderr using Sys.stderr().writeString()
     * @param logLevel Default log level. Any messages with higher level than this will not be logged
     * @param printTime Prints a time-stamp for every message logged, if true
     * @param machineReadable Prints messages in machine-readable format (Json string)
     * @param useColoredOutput If true, the output is using color ANSI `Color` codes
     * @param useThread If true, log messages will be processed printed in a newly created thread. Note: all instances of
     * SysPrintTarget will use the same thread
     */
    public function new( logLevel:LogLevel = LogLevel.Info, printTime:Bool = false, machineReadable:Bool = false, useColoredOutput:Bool = true, useThread:Bool = false ) {

        #if !sys
        #error "SysPrintTarget is not available on this target (no Sys support)"
        #end

        super( logLevel, printTime, machineReadable );

        _useColoredOutput = useColoredOutput;
        #if ios _useColoredOutput = false; #end
        _useThread = useThread;

        #if ( target.threaded )
        if ( _useThread && _messageProcessingThread == null ) {

            _messageQue = new Deque();
            _messageProcessingThread = Thread.create( _processMessageQue );

        }
        #end

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

            if ( message.level <= LogLevel.Error )
                Sys.stderr().writeString( Json.stringify( message ) + '\n' )
            else
                Sys.println( Json.stringify( message ) );

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

            if ( message.level <= LogLevel.Error ) {
                
                Sys.stderr().writeString( m + '\n' );

            }

            if ( message.custom != null ) m += ' [Custom: ${message.custom}]';

            if ( _useColoredOutput ) {

                switch message.level {

                    case LogLevel.Fatal:
                        m = Std.string( Color.On_IRed ) + Std.string( Color.BIWhite ) + m;

                    case LogLevel.Error:
                        m = Color.BRed + m;

                    case LogLevel.Warning:
                        m = Color.Yellow + m;

                    case LogLevel.Debug:
                        m = Color.Cyan + m;

                    case LogLevel.Verbose:
                        m = Color.Purple + m;

                    default:
                        m = Color.Color_Off + m;

                }

            }

            Sys.println( m );

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

