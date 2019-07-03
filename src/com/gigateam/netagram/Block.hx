package com.gigateam.netagram;
import com.gigateam.util.BytesStream;
import haxe.io.Bytes;

/**
 * ...
 * @author Tiger
 */
class Block 
{
	public var lastSliceId:Int = -1;
	public var numAcked:Int = 0;
	public var numSlices:Int = 0;
	public var blockId:Int = -1;
	private var slices:Map<Int, SliceMessage>;
	private var message:Message;
	public function new(id:Int) 
	{
		blockId = id;
		slices = new Map();
	}
	public function append(slice:SliceMessage):Bool{
		if (completed() || slices.exists(slice.sliceId)){
			return false;
		}
		numSlices += 1;
		if (slice.last && slice.sliceId>lastSliceId){
			lastSliceId = slice.sliceId;
		}
		slices.set(slice.sliceId, slice);
		return true;
	}
	public function completed():Bool{
		return lastSliceId>=0 && numSlices > lastSliceId;
	}
	public static function fromMessage(id:Int, message:Message):Block{
		var expectedLength:Int = message.measureSize() + 1;
		var bytes:Bytes = Bytes.alloc(expectedLength); 
		var stream:BytesStream = new BytesStream(bytes, 0);
		stream.write(message.type);
		message.pack(stream);
		var length:Int = stream.offset();
		var block:Block = new Block(id);
		block.numSlices = Math.ceil(length / SliceMessage.SLICE_LENGTH);
		stream.setOffset(0);
		
		for (i in 0...block.numSlices){
			var slice:SliceMessage = new SliceMessage();
			var sliceLength:Int = SliceMessage.SLICE_LENGTH;
			if (length < sliceLength){
				sliceLength = length;
				slice.last = true;
			}
			var sliceStream:BytesStream = new BytesStream(slice.bytes, 0);
			slice.blockId = id;
			slice.sliceId = i;
			sliceStream.writeStream(stream, sliceLength);
			length -= sliceLength;
			//slices.push(slice);
			block.slices.set(i, slice);
		}
		block.message = message;
		return block;
	}
	public function getMessage(factory:MessageFactory):Message{
		if (!completed()){
			return null;
		}
		var bytes:Bytes = Bytes.alloc(numSlices * SliceMessage.SLICE_LENGTH);
		var pos:Int = 0;
		for (i in 0...numSlices){
			var slice:SliceMessage = slices.get(i);
			pos += slice.writeTo(bytes, pos);
			var sliceStream:BytesStream = new BytesStream(slice.bytes, 0);
		}
		var stream:BytesStream = new BytesStream(bytes, 0);
		var messageType:Int = stream.read();
		var message:Message = factory.decodeMessage(stream, messageType);
		return message;
	}
	public function containSlice(messageId:Int):Bool{
		for (slice in slices){
			if (slice.messageId==messageId){
				return true;
			}
		}
		return false;
	}
	public function getSlices():Map<Int, SliceMessage>{
		return slices;
	}
	public function ackedSlices(sliceId:Int):Bool{
		if (!slices.exists(sliceId)){
			return false;
		}
		//var slice:SliceMessage = slices.get(sliceId);
		numAcked += 1;
		if (numAcked == numSlices){
			if (message.onAcknowledged != null){
				message.onAcknowledged();
			}
			return true;
		}
		return false;
	}
}