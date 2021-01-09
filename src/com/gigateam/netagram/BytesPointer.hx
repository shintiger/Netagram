package com.gigateam.netagram;

import com.gigateam.util.BytesStream;
import com.gigateam.util.BytesUtil;
import haxe.io.Bytes;

/**
 * ...
 * @author Tiger
 */
class BytesPointer {
	public var reference:Bytes;
	public var position:Int = 0;
	public var length:UInt = 0;

	public function new() {}

	public static function create(bytes:Bytes, position:Int, length:UInt):BytesPointer {
		var pointer:BytesPointer = new BytesPointer();
		pointer.reference = bytes;
		pointer.position = position;
		pointer.length = length;
		return pointer;
	}

	public function toStream():BytesStream {
		var stream:BytesStream = new BytesStream(reference, position);
		return stream;
	}

	public function toBytes():Bytes {
		var bytes:Bytes = Bytes.alloc(length);
		BytesUtil.writeBytes(reference, position, bytes, 0, length);
		return bytes;
	}
}
