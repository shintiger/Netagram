package com.gigateam.netagram;
import com.gigateam.util.BytesStream;
import com.gigateam.util.BytesUtil;
import haxe.io.Bytes;

/**
 * ...
 * @author Tiger
 */
class SliceMessage extends Message
{
	public static inline var SLICE_LENGTH:Int = 512;
	public var last:Bool = false;
	public var sliceId:Int = -1;
	public var blockId:Int = -1;
	public var bytes:Bytes;
	public function new() 
	{
		super(253);
		bytes = Bytes.alloc(SLICE_LENGTH);
	}
	override public function pack(stream:BytesStream):Void{
		super.pack(stream);
		stream.write(blockId);
		stream.write(last ? (0x80 | sliceId) : (sliceId));
		stream.writeStream(new BytesStream(bytes, 0), bytes.length);
		//stream.write(action);
		//stream.writeInt16(content.length);
	}
	override public function unpack(stream:BytesStream, messageType:Int):Void{
		//var originPos:Int = stream.offset();
		super.unpack(stream, messageType);
		blockId = stream.read();
		sliceId = stream.read();
		last = (sliceId & 0x80) > 0;
		sliceId &= 0x7f;
		var dst:BytesStream = new BytesStream(bytes, 0);
		stream.readStream(dst, bytes.length);
		//var headerLength:Int = stream.offset() - originPos;
		//action = stream.read();
	}
	override private function measuringSize():Int{
		return super.measuringSize() + 2 + bytes.length;
	}
	public function writeTo(dst:Bytes, position:Int):Int{
		//var length:Int = pointer.length - HEADER_LENGTH;
		BytesUtil.writeBytes(bytes, 0, dst, position, SLICE_LENGTH);
		return SLICE_LENGTH;
	}
	override public function clone():Message{
		var message:SliceMessage = new SliceMessage();
		message.last = last;
		message.sliceId = sliceId;
		message.blockId = blockId;
		message.bytes = bytes;
		return message;
	}
}