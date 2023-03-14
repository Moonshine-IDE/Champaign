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