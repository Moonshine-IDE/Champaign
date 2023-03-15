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

package champaign.js.logging.targets;

import champaign.core.logging.Logger;
import champaign.core.logging.targets.AbstractLoggerTarget;
import haxe.Json;
#if js
import js.html.Console;
#end

class ConsoleTarget extends AbstractLoggerTarget {
    
    public function new( logLevel:LogLevel = LogLevel.Info, printTime:Bool = false, machineReadable:Bool = false ) {

        #if !js
        //#error "ConsoleTarget is not available on this target (no JavaScript support)"
        #end

        super( logLevel, printTime );

    }

    function loggerFunction( message:FormattedMessage ) {

        #if js

        if ( !enabled ) return;

        if ( message.level > _logLevel ) return;

        if ( _machineReadable ) {

            switch message.level {

                case LogLevel.Fatal:
                    Console.exception( Json.stringify( message ) );

                case LogLevel.Error:
                    Console.error( Json.stringify( message ) );

                case LogLevel.Warning:
                    Console.warn( Json.stringify( message ) );

                case LogLevel.Debug:
                    Console.debug( Json.stringify( message ) );

                case LogLevel.Verbose:
                    Console.debug( Json.stringify( message ) );

                default:
                    Console.info( Json.stringify( message ) );

            }

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

            switch message.level {

                case LogLevel.Fatal:
                    Console.exception( m );

                case LogLevel.Error:
                    Console.error( m );

                case LogLevel.Warning:
                    Console.warn( m );

                case LogLevel.Debug:
                    Console.debug( m );

                case LogLevel.Verbose:
                    Console.debug( m );

                default:
                    Console.info( m );

            }

        }

        #end

    }

}