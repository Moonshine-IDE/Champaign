package prominic.native;

#if cpp
import cpp.ConstCharStar;
#end
import haxe.Json;

#if PNL_FILESYSTEM
@:keep
#if windows
@:buildXml('<compiler><flag value="/std:c++17"/><cppflag value="-std=c++11" if="HXCPP_CPP11"/></compiler>')
#else
@:buildXml('<set name="MACOSX_DEPLOYMENT_TARGET" value="10.12" /><compiler><flag value="-std=c++17" /><cppflag value="-std=c++17" if="HXCPP_CPP11"/></compiler>')
#end
@:include('./../../../cpp/FileSystem.h')
@:sourceFile('./../../../cpp/FileSystem.cpp')
private extern class FileSystem {

	@:native('NSFileSystem::__makeLink')
	static function __makeLink(path1:ConstCharStar, path2:ConstCharStar):ConstCharStar;

}
#end

@:noDoc
class NativeLibrary {

	/**
	 * Creates a symlink for sourcePath to targetPath.
	 * Important: On Windows only processes with elevated permission can create symlinks!
	 * @param sourcePath The source path
	 * @param targetPath The target path
	 * @return Int Returns 0 if the operation was successful, the error code otherwise
	 */
	static public function makeLink( sourcePath:String, targetPath:String ):Int {

		#if PNL_FILESYSTEM
		var c:ConstCharStar = FileSystem.__makeLink( ConstCharStar.fromString( sourcePath ), ConstCharStar.fromString( targetPath ) );
		var s = c.toString();
		var r:NativeLibraryResult = { success: false };

		try {

			r = Json.parse( s );

		} catch( e ) {}

		if ( r.success ) return 0;
		if ( r.errorCode != null ) return r.errorCode;
		return 1;
		#else
		return 1;
		#end

	}

}

private typedef NativeLibraryResult = {

	?errorCode:Int,
	?success:Bool,
	?hostInfo:HostInfo,

}

private typedef HostInfo = {

	?canonicalNames:Array<String>,
    ?host:String,
    ?ipv4:Array<String>,
    ?ipv6:Array<String>,

}
