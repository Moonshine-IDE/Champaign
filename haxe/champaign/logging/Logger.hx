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

package champaign.logging;

import champaign.logging.targets.AbstractLoggerTarget;
import haxe.Log;
import haxe.PosInfos;

class Logger {

    static var _global:LoggerImpl;
    static var _initialized:Bool = false;

    /**
     * Creates a LoggerImpl instance
     * @param logLevel The maximum LogLevel of the LoggerImpl instance
     * @param id The optional id of this specific LoggerImpl instance. If defined, it'll be added to the log messages
     * @return LoggerImpl
     */
    public static function create( logLevel:LogLevel = LogLevel.Info, ?id:String ):LoggerImpl {

        return new LoggerImpl( logLevel, id );

    }

    /**
     * Initializes the Logger.
     * @param logLevel Default log level. Any messages with higher level than this will not be logged in targets
     * @param captureHaxeTrace If true, it captures haxe.Log.trace(), and messages will be logged with LogLevel.Info in all targets
     */
    public static function init( logLevel:LogLevel = LogLevel.Info, captureHaxeTrace:Bool = false ) {

        _global = new LoggerImpl( logLevel );
        if ( captureHaxeTrace ) Log.trace = _global.loggerFunction;
        _initialized = true;

    }

    /**
     * Adds a log target to the Logger
     * @param target The AbstractLoggerTarget implementation
     */
    public static function addTarget( target:AbstractLoggerTarget ) {

        if ( !_initialized ) return -1;

        return _global._targets.push( target );

    }

    /**
     * Disables all targets
     */
    public static function disableAllTargets() {

        if ( !_initialized ) return;

        for ( t in _global._targets ) t.enabled = false;

    }

    /**
     * Enables all targets
     */
    public static function enableAllTargets() {

        if ( !_initialized ) return;

        for ( t in _global._targets ) t.enabled = true;

    }

    /**
     * Returns an array of targets with the given class
     * @param targetClass The class of the requested targets
     * @return Array<AbstractLoggerTarget> The array of targets. Empty if no target was found.
     */
    public static function getTargetsByClass( targetClass:Class<AbstractLoggerTarget> ):Array<AbstractLoggerTarget> {

        if ( !_initialized ) return null;

        var result:Array<AbstractLoggerTarget> = [];

        for ( t in _global._targets ) {

            if ( Type.getClass( t ) == targetClass ) result.push( t );

        }

        return result;

    }

    /**
     * Removes a logger target
     * @param target 
     */
    public static function removeTarget( target:AbstractLoggerTarget ) {

        if ( !_initialized ) return false;

        return _global._targets.remove( target );

    }

    /**
     * Logs a message in all targets with LogLevel.Debug
     * @param v The message to be logged
     * @param pos PosInfos when debug is enabled
     */
    public static function debug( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        if ( !_initialized ) return;

        _global.log( v, LogLevel.Debug, customMessageObject, pos );

    }

    /**
     * Logs a message in all targets with LogLevel.Error
     * @param v The message to be logged
     * @param pos PosInfos when debug is enabled
     */
    public static function error( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        if ( !_initialized ) return;

        _global.log( v, LogLevel.Error, customMessageObject, pos );

    }

    /**
     * Logs a message in all targets with LogLevel.Fatal
     * @param v The message to be logged
     * @param pos PosInfos when debug is enabled
     */
    public static function fatal( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        if ( !_initialized ) return;

        _global.log( v, LogLevel.Fatal, customMessageObject, pos );

    }

    /**
     * Logs a message in all targets with LogLevel.Info
     * @param v The message to be logged
     * @param pos PosInfos when debug is enabled
     */
    public static function info( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        if ( !_initialized ) return;

        _global.log( v, LogLevel.Info, customMessageObject, pos );

    }

    /**
     * Logs a message in all targets with LogLevel.Verbose
     * @param v The message to be logged
     * @param pos PosInfos when debug is enabled
     */
    public static function verbose( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        if ( !_initialized ) return;

        _global.log( v, LogLevel.Verbose, customMessageObject, pos );

    }

    /**
     * Logs a message in all targets with LogLevel.Warning
     * @param v The message to be logged
     * @param pos PosInfos when debug is enabled
     */
    public static function warning( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        if ( !_initialized ) return;

        _global.log( v, LogLevel.Warning, customMessageObject, pos );

    }

}

@:allow( champaign.logging )
class LoggerImpl {

    var _id:String;
    var _logLevel:LogLevel;
    var _targets:Array<AbstractLoggerTarget>;

    function new( logLevel:LogLevel = LogLevel.Info, ?id:String ) {

        _logLevel = logLevel;
        _id = id;
        _targets = [];

    }

    /**
     * Adds a log target
     * @param target The AbstractLoggerTarget implementation
     */
    public function addTarget( target:AbstractLoggerTarget ) {

        return _targets.push( target );

    }

    /**
     * Disables all targets
     */
    public function disableAllTargets() {

        for ( t in _targets ) t.enabled = false;

    }

    /**
     * Enables all targets
     */
    public function enableAllTargets() {

        for ( t in _targets ) t.enabled = true;

    }

    /**
     * Returns an array of targets with the given class
     * @param targetClass The class of the requested targets
     * @return Array<AbstractLoggerTarget> The array of targets. Empty if no target was found.
     */
    public function getTargetsByClass( targetClass:Class<AbstractLoggerTarget> ):Array<AbstractLoggerTarget> {

        var result:Array<AbstractLoggerTarget> = [];

        for ( t in _targets ) {

            if ( Type.getClass( t ) == targetClass ) result.push( t );

        }

        return result;

    }

    /**
     * Removes a logger target
     * @param target 
     */
    public function removeTarget( target:AbstractLoggerTarget ) {

        return _targets.remove( target );

    }

    /**
     * Disposes the LoggerImpl instance
     */
    public function dispose( disposeTargets:Bool = false ) {
        
        if ( disposeTargets && _targets != null ) for ( t in _targets ) t.dispose();
        _targets = null;

    }

    /**
     * Logs a message in all targets with LogLevel.Debug
     * @param v The message to be logged
     * @param customMessageObject An optional message object that will be attached to the formatted message
     * @param pos PosInfos when debug is enabled
     */
    public function debug( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        log( v, LogLevel.Debug, customMessageObject, pos );

    }

    /**
     * Logs a message in all targets with LogLevel.Error
     * @param v The message to be logged
     * @param customMessageObject An optional message object that will be attached to the formatted message
     * @param pos PosInfos when debug is enabled
     */
    public function error( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        log( v, LogLevel.Error, customMessageObject, pos );

    }

    /**
     * Logs a message in all targets with LogLevel.Fatal
     * @param v The message to be logged
     * @param customMessageObject An optional message object that will be attached to the formatted message
     * @param pos PosInfos when debug is enabled
     */
    public function fatal( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        log( v, LogLevel.Fatal, pos );

    }

    /**
     * Logs a message in all targets with LogLevel.Info
     * @param v The message to be logged
     * @param customMessageObject An optional message object that will be attached to the formatted message
     * @param pos PosInfos when debug is enabled
     */
    public function info( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        log( v, LogLevel.Info, customMessageObject, pos );

    }

    /**
     * Logs a message in all targets with LogLevel.Verbose
     * @param v The message to be logged
     * @param customMessageObject An optional message object that will be attached to the formatted message
     * @param pos PosInfos when debug is enabled
     */
    public function verbose( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        log( v, LogLevel.Verbose, customMessageObject, pos );

    }

    /**
     * Logs a message in all targets with LogLevel.Warning
     * @param v The message to be logged
     * @param customMessageObject An optional message object that will be attached to the formatted message
     * @param pos PosInfos when debug is enabled
     */
    public function warning( v:Dynamic, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        log( v, LogLevel.Warning, customMessageObject, pos );

    }

    /**
     * The main log function
     * @param v The message to be logged
     * @param level The level of the log
     * @param customMessageObject An optional message object that will be attached to the formatted message
     * @param pos PosInfos when debug is enabled
     */
    public function log( v:Dynamic, ?level:LogLevel = LogLevel.Info, ?customMessageObject:Dynamic, ?pos:PosInfos ) {

        if ( _targets == null ) throw "This LoggerImpl has been disposed";
        
        if ( level > _logLevel || level == LogLevel.None ) return;
        
        if ( pos.customParams == null ) {

            pos.customParams = [ level ];
            if ( customMessageObject != null ) pos.customParams.push( customMessageObject );

        } else {

            pos.customParams.unshift( level );
            if ( customMessageObject != null ) pos.customParams.push( customMessageObject );

        }

        loggerFunction( v, pos );

    }

    function loggerFunction( v:Dynamic, ?pos:PosInfos ) {

        if ( _logLevel == LogLevel.None ) return;

        var formattedMessage:FormattedMessage = {

            level: LogLevel.Info,
            message: Std.string( v ),
            time: Date.now().getTime(),
            date: Date.now().toString(),
            #if debug
            source: '${pos.fileName}:${pos.lineNumber}',
            #end

        }

        if ( _id != null ) formattedMessage.entity = _id;

        if ( pos.customParams != null ) {
            
            if ( Std.isOfType( pos.customParams[ 0 ], Int ) ) {

                formattedMessage.level = cast( pos.customParams[ 0 ], Int );
                pos.customParams.shift();

            }

            if ( pos.customParams[ 0 ] != null ) {

                formattedMessage.custom = pos.customParams[ 0 ];

            }

        }

        if ( formattedMessage.level > _logLevel ) return;

        for ( target in _targets ) {

            target.loggerFunction( formattedMessage );

        }

    }

}

enum abstract LogLevel( Int ) from Int to Int {

    var None = 0;
    var Fatal = 1;
    var Error = 2;
    var Warning = 3;
    var Info = 4;
    var Debug = 5;
    var Verbose = 6;

    @:op(A > B) private static inline function gt(a:LogLevel, b:LogLevel):Bool {

        return (a : Int) > (b : Int);

    }

    @:op(A >= B) private static inline function gte(a:LogLevel, b:LogLevel):Bool {

        return (a : Int) >= (b : Int);

    }

    @:op(A < B) private static inline function lt(a:LogLevel, b:LogLevel):Bool {

        return (a : Int) < (b : Int);

    }

    @:op(A <= B) private static inline function lte(a:LogLevel, b:LogLevel):Bool {

        return (a : Int) <= (b : Int);

    }

}

typedef FormattedMessage = {

    ?custom:Dynamic,
    ?entity:String,
    ?source:String,
    date:String,
    level:LogLevel,
    message:String,
    time:Float,

}
