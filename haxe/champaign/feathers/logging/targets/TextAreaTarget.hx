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

package champaign.feathers.logging.targets;

#if feathersui
import feathers.controls.TextArea;
#end
import champaign.core.logging.Logger;
import champaign.core.logging.targets.AbstractLoggerTarget;
import haxe.Json;

class TextAreaTarget extends AbstractLoggerTarget {

    #if feathersui
    var _textArea:TextArea;
    #else
    var _textArea:Dynamic;
    #end

    public function new( logLevel:LogLevel = LogLevel.Info, printTime:Bool = false, machineReadable:Bool = false, textArea: #if feathersui TextArea #else Dynamic #end ) {

        super( logLevel, printTime, machineReadable );

        _textArea = textArea;

    }

    function loggerFunction( message:LoggerFormattedMessage ) {

        if ( !enabled ) return;

        if ( message.level > _logLevel ) return;

        if ( _machineReadable ) {

            for ( f in _filters.keys() ) message.message = StringTools.replace( message.message, f, _filters[ f ] );
            if ( _textArea != null ) _textArea.text += Json.stringify( message ) + '\n';

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
            for ( f in _filters.keys() ) m = StringTools.replace( m, f, _filters[ f ] );

            if ( message.custom != null ) m += ' [Custom: ${message.custom}]';

            if ( _textArea != null ) _textArea.text += m + '\n';

        }

    }
    
}