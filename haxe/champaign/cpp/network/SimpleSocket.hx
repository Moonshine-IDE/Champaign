package champaign.cpp.network;

import champaign.cpp.externs.NativeICMPSocket;
import haxe.io.Bytes;
import haxe.io.BytesData;
import sys.net.Address;
import sys.net.Host;

class SimpleSocket {
    
    var _byteData:BytesData;
    var _data:String;
    var _id:UInt;
    var _sequenceId:Int;
    var _socketHandle:Int;

    public function new() {

        _socketHandle = NativeICMPSocket.create_simple_socket();
        _sequenceId = 0;
        //_id = Std.random( 0xFFFF );
        _id = 0;
        _createData();
        trace( '!!!!!!!!!!! ${_socketHandle}' );

    }

    public function ping( address:String ) {

        var h = new Host( address );
        var addr = new Address();
        addr.host = h.ip;
        addr.port = Std.random( 64511 ) + 1024;

        var r = NativeICMPSocket.simple_socket_send( _socketHandle, this._byteData, addr, _sequenceId, _id );
        _sequenceId++;
        _id++;
        return r;

    }

    function _createData():Void {

		this._data = "";
		for ( i in 0...56 ) this._data += "!";
		this._byteData = Bytes.ofString( "00000000" + this._data ).getData();
		// Filling in ICMP Header
		_byteData[0] = 8;
		_byteData[1] = 0;
		_byteData[2] = 0;
		_byteData[3] = 0;
		_byteData[4] = this._id;
		_byteData[5] = this._id >> 8;
		_byteData[6] = 0;
		_byteData[7] = 0;

	}

}