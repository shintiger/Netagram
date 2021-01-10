package com.gigateam.netagram;

import com.gigateam.util.BytesStream;
import com.gigateam.util.BytesUtil;
import haxe.crypto.Crc32;
import haxe.io.Bytes;

/**
 * ...
 * @author Tiger
 */
class Fragment {
	public static inline var HEADER_LENGTH:Int = 7;

	public var payloadId:Int;
	public var fragmentId:Int;
	public var isLastFragment:Bool = false;
	public var pointer:BytesPointer;
	public var length:Int;
	public var checksum:Int;

	private var bytes:Bytes;

	public function new() {}

	public static function fromBytes(pointer:BytesPointer):Fragment {
		var fragment:Fragment = new Fragment();
		fragment.pointer = pointer;
		// var stream:InputStream = new InputStream(pointer.reference);
		var stream:BytesStream = new BytesStream(pointer.reference, pointer.position);
		fragment.payloadId = stream.readInt16();
		var flags:Int = stream.read();

		// First bit of first firt byte
		fragment.isLastFragment = (flags & 0x80) > 0;

		// The rest of first byte
		fragment.fragmentId = flags & 0x7f;

		fragment.checksum = stream.readInt32();
		fragment.length = pointer.length - stream.offset();

		fragment.bytes = Bytes.alloc(fragment.length);
		var myStream:BytesStream = new BytesStream(fragment.bytes, 0);
		myStream.writeStream(new BytesStream(pointer.reference, pointer.position + HEADER_LENGTH), fragment.length);
		var crc32:Int = Crc32.make(fragment.bytes);
		if (fragment.checksum != crc32) {
			trace("invalid checksum", crc32, fragment.checksum);
			return null;
		}

		// trace(stream.toHex(10));
		return fragment;
	}

	public function writeTo(dst:Bytes, position:Int):Int {
		// var length:Int = pointer.length - HEADER_LENGTH;
		BytesUtil.writeBytes(bytes, 0, dst, position, length);
		return length;
	}
}
