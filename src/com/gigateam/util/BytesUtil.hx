package com.gigateam.util;
import haxe.io.Bytes;

/**
 * ...
 * @author Tiger
 */
class BytesUtil 
{

	public function new() 
	{
		
	}
	public static function copyBytes(bytes:Bytes, offset:Int, length:Int):Array<Int>{
		var i:Int = 0;
		var arr:Array<Int> = [];
		for (i in offset...length + offset){
			arr.push(bytes.get(i));
		}
		return arr;
	}
	public static function writeBytes(srcBytes:Bytes, srcPos:Int, dstBytes:Bytes, dstPos:Int, length:Int):UInt{
		/*
		for (i in 0...length){
			dstBytes.set(dstPos + i, srcBytes.get(srcPos + i));
		}
		*/
		dstBytes.blit(dstPos, srcBytes, srcPos, length);
		return length;
	}
	public static function writeUnsignedInt24(bytes:Bytes, pos:UInt, num:Int):UInt{
		bytes.set(pos, (num >> 16) & 0xff);
		pos++;
		bytes.set(pos, (num >> 8) & 0xff);
		pos++;
		bytes.set(pos, num & 0xff);
		return 3;
	}
	public static function readUnsignedInt24(bytes:Bytes, pos:UInt):UInt{
		var num:Int = 0;
		num |= bytes.get(pos)<<16;
		pos++;
		num |= bytes.get(pos)<<8;
		pos++;
		num |= bytes.get(pos) & 0xff;
		return num;
	}
	public static function writeUnsignedInt16(bytes:Bytes, pos:UInt, num:Int):UInt{
		bytes.set(pos, (num >> 8) & 0xff);
		pos++;
		bytes.set(pos, num & 0xff);
		return 2;
	}
	public static function readUnsignedInt16(bytes:Bytes, pos:UInt):UInt{
		var num:UInt = 0;
		num |= bytes.get(pos)<<8;
		pos++;
		num |= bytes.get(pos) & 0xff;
		return num;
	}
	public static function write(bytes:Bytes, pos:UInt, num:Int):UInt{
		bytes.set(pos, num);
		return 1;
	}
	public static function readUnsigned(bytes:Bytes, pos:UInt):Int{
		return bytes.get(pos);
	}
	public static function writeUTF(bytes:Bytes, pos:UInt, str:String):UInt{
		var data:Bytes = Bytes.ofString(str);
		pos += writeUnsignedInt16(bytes, pos, data.length);
		bytes.blit(pos, data, 0, data.length);
		return data.length+2;
	}
	public static function readUTF(bytes:Bytes, pos:UInt, len:UInt):String{
		var data:Bytes = bytes.sub(pos, len);
		return data.toString();
	}
	public static function writeDouble(bytes:Bytes, pos:UInt, double:Float):UInt{
		bytes.setDouble(pos, double);
		return 8;
	}
	public static function readDouble(bytes:Bytes, pos:UInt):Float{
		return bytes.getDouble(pos);
	}
	#if cpp
	public static function stringFromChar(raw:cpp.Pointer<cpp.UInt8>, length:UInt):String{
		var array:Array<cpp.UInt8> = raw.toUnmanagedArray(length);
		var str:String = "";
		var bytes:Bytes = Bytes.ofData(array);
		var str:String = bytes.toString();
		return str;
	}
	public static function charFromString(raw:cpp.Pointer<cpp.UInt8>, str:String, length:UInt=1024):Void{
		var array:Array<cpp.UInt8> = raw.toUnmanagedArray(length);
		var bytes:Bytes = Bytes.ofData(array);
		var strBytes:Bytes = Bytes.ofString(str);
		bytes.blit(0, strBytes, 0, strBytes.length);
	}
	#end
}