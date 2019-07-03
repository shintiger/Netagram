package com.gigateam.util;
import com.gigateam.util.BytesUtil;
import haxe.io.Bytes;

/**
 * ...
 * @author Tiger
 */
class BytesStream 
{
	private var _bytes:Bytes;
	private var _offset:Int = 0;
	private var _bitOffset:Int = 0;
	public function new(bytes:Bytes, offset:Int) 
	{
		_bytes = bytes;
		_offset = offset;
	}
	public function setOffset(offset:UInt):Void{
		_offset = offset;
	}
	public function bytes():Bytes{
		return _bytes;
	}
	public function offset():Int{
		return _offset;
	}
	public function length():Int{
		return _bytes.length;
	}
	public function writeInt32(int:Int):Void{
		_bytes.setInt32(_offset, int);
		_offset += 4;
	}
	public function writeInt24(int:Int):Void{
		_offset += BytesUtil.writeUnsignedInt24(_bytes, _offset, int);
	}
	public function writeInt16(int:Int):Void{
		_offset += BytesUtil.writeUnsignedInt16(_bytes, _offset, int);
	}
	public function write(int:Int):Void{
		_bytes.set(_offset, int);
		_offset += 1;
	}
	public function writeFloat(float:Float):Void{
		_bytes.setDouble(_offset, float);
		_offset += 4;
	}
	public function writeDouble(double:Float):Void{
		_bytes.setDouble(_offset, double);
		_offset += 8;
	}
	public function writeUTF(str:String):Void{
		_offset += BytesUtil.writeUTF(_bytes, _offset, str);
	}
	public function readInt32():Int{
		var result:Int = _bytes.getInt32(_offset);
		_offset += 4;
		return result;
	}
	public function readInt24():Int{
		var result:Int = BytesUtil.readUnsignedInt24(_bytes, _offset);
		_offset += 3;
		return result;
	}
	public function readInt16():Int{
		var result:Int = BytesUtil.readUnsignedInt16(_bytes, _offset);
		_offset += 2;
		return result;
	}
	public function read():Int{
		var result:Int = _bytes.get(_offset);
		_offset += 1;
		return result;
	}
	public function readFloat():Float{
		var result:Float = _bytes.getFloat(_offset);
		_offset += 4;
		return result;
	}
	public function readDouble():Float{
		var result:Float = _bytes.getDouble(_offset);
		_offset += 8;
		return result;
	}
	public function readUTF():String{
		var len:UInt = readInt16();
		var str:String = BytesUtil.readUTF(_bytes, _offset, len);
		_offset += len;
		return str;
	}
	public function writeStream(stream:BytesStream, len:Int=-1):Void{
		if (len < 0){
			len = stream._bytes.length;
		}
		_bytes.blit(_offset, stream.bytes(), stream.offset(), len);
		stream.setOffset(stream.offset() + len);
		_offset += len;
		/*
		for (pos in 0...len){
			write(stream.read());
		}
		*/
		//_offset += stream._bytes.length;
	}
	public function readStream(dst:BytesStream, len:UInt):Void{
		var pos:Int;
		for (pos in 0...len){
			dst.write(read());
		}
	}
	public function toHex(bytesLength:Int):String{
		var pos:Int;
		var str:String = "";
		for (pos in 0...bytesLength){
			str += StringTools.hex(read());
		}
		return str;
	}
}