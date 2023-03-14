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