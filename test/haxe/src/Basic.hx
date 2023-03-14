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

import prominic.core.primitives.Property;
import prominic.logging.Logger;

#if sys
import prominic.logging.targets.SysPrintTarget;
#elseif js
import prominic.logging.targets.ConsoleTarget;
#end

class Basic {

    static public function main() {

        Logger.init( LogLevel.Debug );
        #if sys
        Logger.addTarget( new SysPrintTarget( LogLevel.Debug, true, false, true ) );
        #elseif js
        Logger.addTarget( new ConsoleTarget( LogLevel.Debug, true, false ) );
        #end

        Logger.info( "Hello, Basic App!" );
        Logger.debug( "It's a perfect day for debugging" );
        Logger.verbose( "I kinda like it here, but it\'s a secret, so don't tell anyone :)" );
        Logger.warning( "You can't see the secret message, can you?" );

        var property = new Property( "SomeValue" );
        Logger.info( 'The value of our property: ${property.value}. Now let\'s change it...' );
        property.onChange.add( _onPropertyChanged );
        property.value = "NewValue";

        Logger.info( "Well, good luck to you using Champaign! " );

    }

    static function _onPropertyChanged<T>( property:Property<T> ) {

        Logger.info( 'Our property\'s value has changed to ${property.value}' );

    }

}