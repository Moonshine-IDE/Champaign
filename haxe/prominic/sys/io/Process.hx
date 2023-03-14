package prominic.sys.io;

#if !cpp
#error "Process is not supported on this target (no C++ support)"
#end

@:buildXml('<include name="${haxelib:champaign}/config/process.xml" />')
@:keep
@:include('CProcess.h')
private extern class Champaign_Process {

	@:native('NS_Champaign_Process::__isUserRoot')
	static function __isUserRoot():Bool;

}

/**
 * Functions related to currently running or manually spawned processes
 */
class Process {

    /**
     * Checks if the current user has root/admin privileges
     * @return Bool
     */
    static public function isUserRoot():Bool {

        return Champaign_Process.__isUserRoot();

    }
    
}