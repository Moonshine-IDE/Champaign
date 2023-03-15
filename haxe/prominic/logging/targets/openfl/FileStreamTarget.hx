package prominic.logging.targets.openfl;

import haxe.Json;
import haxe.ds.BalancedTree;
import haxe.io.Path;
import openfl.filesystem.File;
import openfl.filesystem.FileMode;
import openfl.filesystem.FileStream;
import prominic.logging.Logger.FormattedMessage;
import prominic.logging.Logger.LogLevel;

class FileStreamTarget extends FileTarget {

    static final _FILE_NAME_PATTERN:EReg = ~/^(?:log){1}(?:-){1}(?:[a-zA-Z0-9-]+)(?:.)(?:txt)$/;
    #if windows
    static final _LINE_ENDING:String = '\r\n';
    #else
    static final _LINE_ENDING:String = '\n';
    #end

    public function new( directory:String, ?filename:String = "current.txt", ?numLogFiles:Int = 9, logLevel:LogLevel = LogLevel.Info, printTime:Bool = false, machineReadable:Bool = false, clearLogFile:Bool = true ) {

        super( directory, filename, numLogFiles, logLevel, printTime, machineReadable, clearLogFile );

    }

    override function directoryMaintenance() {

        if ( _currentLogFilePath != null ) {

            // Directory maintenance

            try {

                // Creating log directory
                var dir = new File( _directory );
                dir.createDirectory();

                var clf = new File( _currentLogFilePath );

                // If current.txt already exists, rename it
                if ( clf.exists ) {

                    var nn = StringTools.replace( StringTools.replace( "log-" + clf.modificationDate.toString() + ".txt", ":", "-" ), " ", "-" );
                    clf.copyTo( new File( _directory + nn ), true );
                    if ( _clearLogFile ) clf.deleteFile();

                }

                // Getting file list
                var a = dir.getDirectoryListing();
                var b:Array<File> = [];
                for ( f in a ) if ( _FILE_NAME_PATTERN.match( f.name ) ) b.push( f );

                // Sorting files by modification date
                var m:BalancedTree<String, File> = new BalancedTree();
                for ( f in b ) m.set( Std.string( f.modificationDate.getTime() ), f );

                var c:Array<File> = [];
                for ( d in m.keys() ) c.push( m.get( d ) );

                // Deleting files
                if ( c.length > _numLogFiles ) {

                    for ( i in 0...c.length-_numLogFiles ) c[ i ].deleteFile();
                    c.reverse();
                    c.resize( _numLogFiles );
                    c.reverse();

                }

                // Copying latest entry to last.txt
                c[ c.length-1 ].copyTo( new File( _directory + "last.txt" ), true );

            } catch ( e ) {}

        }

    }

    override function loggerFunction( message:FormattedMessage ) {

        if ( !enabled ) return;

        if ( message.level > _logLevel ) return;

        if ( _machineReadable ) {

            try {

                var f = new File( _currentLogFilePath );
                var fs = new FileStream();
                fs.open( f, FileMode.APPEND );
                fs.writeUTFBytes( Json.stringify( message ) + _LINE_ENDING );
                fs.close();

            } catch ( e ) { }

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

            try {

                var f = new File( _currentLogFilePath );
                var fs = new FileStream();
                fs.open( f, FileMode.APPEND );
                fs.writeUTFBytes( m + _LINE_ENDING );
                fs.close();

            } catch ( e ) { }

        }

    }


}