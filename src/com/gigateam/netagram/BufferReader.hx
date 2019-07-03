package com.gigateam.netagram;
import haxe.io.Bytes;

/**
 * ...
 * @author Tiger
 */
class BufferReader 
{
	private var maxBufferSize:Int;
	private var bufferPosition:Int = 0;
	private var buffer:Bytes;
	public function new(bufferSize:Int) 
	{
		resetBuffer(bufferSize);
	}
	public function resetBuffer(size:Int):Void{
		maxBufferSize = size;
		buffer = Bytes.alloc(size);
		bufferPosition = 0;
	}
	public function append(bytes:Bytes, length:Int):Int{
		if ((bufferPosition + length) > buffer.length){
			throw "Size overflow";
		}
		buffer.blit(bufferPosition, bytes, 0, length);
		bufferPosition += length;
		return bufferPosition;
	}
	public function readInto(bytes:Bytes):Void{
		bytes.blit(0, buffer, 0, bufferPosition);
		bufferPosition = 0;
	}
}