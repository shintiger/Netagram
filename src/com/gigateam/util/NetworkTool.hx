package com.gigateam.util;
import haxe.Int64;
import haxe.Int64Helper;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import sys.net.Address;

/**
 * ...
 * @author Tiger
 */
class NetworkTool 
{

	public function new() 
	{
		
	}
	public static function stringToAddress(host:String):Address{
		var arr:Array<String> = host.split(".");
		var addr:Address = new Address();
		var buf:Bytes = Bytes.alloc(4);
		buf.set(0, Std.parseInt(arr[0]));
		buf.set(1, Std.parseInt(arr[1]));
		buf.set(2, Std.parseInt(arr[2]));
		buf.set(3, Std.parseInt(arr[3]));
		addr.host = buf.getInt32(0);
		return addr;
		
	}
	public static function addressToString(addr:Address):String{
		var bytes:Bytes = Bytes.alloc(1024);
		bytes.setInt32(0, addr.host);
		var str:String = "";
		str += Std.string(bytes.get(0)) + ".";
		str += Std.string(bytes.get(1)) + ".";
		str += Std.string(bytes.get(2)) + ".";
		str += Std.string(bytes.get(3));
		return str;
	}
	public static function addressToInt64(address:Address):Int64{
		var bytes:Bytes = Bytes.alloc(6);
		bytes.setInt32(0, address.host);
		bytes.setUInt16(4, address.port);
		return bytes.getInt64(0);
	}
	public static function addressToString6(address:Address):String{
		var bytes:Bytes = Bytes.alloc(6);
		bytes.setInt32(0, address.host);
		bytes.setUInt16(4, address.port);
		return bytes.getString(0, 6);
	}
	public static function addressToFloat(address:Address):Float{
		var bytes:Bytes = Bytes.alloc(8);
		bytes.setInt32(0, address.host);
		bytes.setUInt16(4, address.port);
		return bytes.getDouble(0);
	}
	public static function addressToHash(address:Address):Int{
		var bytes:Bytes = Bytes.alloc(8);
		bytes.setInt32(0, address.host);
		bytes.setUInt16(4, address.port);
		return Crc32.make(bytes);
	}
}