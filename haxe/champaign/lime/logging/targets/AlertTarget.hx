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

package champaign.lime.logging.targets;

import champaign.core.logging.Logger.LogLevel;
import champaign.core.logging.Logger.LoggerFormattedMessage;
import champaign.core.logging.targets.AbstractLoggerTarget;
import lime.app.Application;

class AlertTarget extends AbstractLoggerTarget {
    
    public function new( loglevel:LogLevel = LogLevel.Info ) {

        super( loglevel, false, false );

    }

    function loggerFunction( message:LoggerFormattedMessage ) {

        if ( !enabled ) return;

        if ( message.level > _logLevel ) return;

        var m:String = '';
        var t:String = '';

        switch message.level {

            case LogLevel.Fatal:
                t += 'Fatal Exception';

            case LogLevel.Error:
                t += 'Error';

            case LogLevel.Warning:
                t += 'Warning';

            case LogLevel.Info:
                t += 'Info';

            case LogLevel.Debug:
                t += 'Debug';

            case LogLevel.Verbose:
                t += 'Verbose';

            default:

        }

        if ( message.source != null ) m += '[${message.source}]';
        m += ' ${message.message}';
        if ( message.custom != null ) m += ' [Custom: ${message.custom}]';

        Application.current.window.alert( m, t );

    }

}