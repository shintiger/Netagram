package com.gigateam.netagram;
import com.gigateam.util.BytesStream;
import com.gigateam.util.BytesUtil;
import haxe.CallStack;
import haxe.io.Bytes;
import hx.concurrent.lock.RLock;

/**
 * ...
 * @author Tiger
 */
class Payload 
{
	public static inline var MESSAGE_OVERHEAD:Int = 1;
	public static inline var PAYLOAD_HEADER:Int = 7;
	public var sentTime:Float = 0;
	public var payloadId:Int;
	public var length:Int = 0;
	public var ack:Int = -1;
	public var ackInt:Int = 0;
	public var compress:Int = 0;
	private var messages:Array<Message> = [];
	private var bytes:Bytes;
	public var numFragments:UInt = 0;
	private var lastFragmentId:Int = -1;
	private var fragments:Map<Int, Fragment>;
	private var lock:RLock;
	public function new(id:Int) 
	{
		payloadId = id;
		fragments = new Map();
		lock = new RLock();
	}
	public function insert(fragment:Fragment):Bool{
		if (completed() || fragments.exists(fragment.fragmentId)){
			if (completed()){
				trace("completed payload");
			}else{
				trace("fragment exists");
			}
			return false;
		}
		lock.acquire();
		numFragments += 1;
		fragments.set(fragment.fragmentId, fragment);
		if (fragment.isLastFragment){
			lastFragmentId = fragment.fragmentId;
		}
		if (completed()){
			bytes = Bytes.alloc(DuplexStream.MTU * numFragments);
			 
			var pos:Int = 0;
			for (i in 0...numFragments){
				var item:Fragment = fragments.get(i);
				if (item == null){
					for (key in fragments.keys()){
						trace(key, fragments.get(key).fragmentId, fragment.payloadId, fragment.length, fragment.isLastFragment);
					}
					trace("numFragments", numFragments, i, fragment.fragmentId, fragments.exists(i));
					throw "ITEM null??";
				}
				pos += item.writeTo(bytes, pos);
			}
			length = pos;
			
			fragments = null;
		}
		lock.release();
		return true;
	}
	public function completed():Bool{
		return (lastFragmentId >= 0 && numFragments > lastFragmentId);
	}
	public function parseMessages(factory:MessageFactory, baseTime:Float):Array<Message>{
		if (!completed()){
			return [];
		}
		lock.acquire();
		var stream:BytesStream = new BytesStream(bytes, 0);
		//payloadId = stream.readInt16();
		ack = stream.readInt16();
		ackInt = stream.readInt32();
		var readFloat:Float = stream.readDouble();
		sentTime = readFloat + baseTime;
		//trace(readFloat, baseTime);
		var flags:Int = stream.read();
		
		/*
		var payloadBodyAvailable:Int = stream.readInt16();
		var payloadLength:Int = payloadBodyAvailable;
		messages = [];
		while (payloadBodyAvailable > 0){
			//trace("payloadBodyAvailable", payloadBodyAvailable);
			var messageStart:Int = stream.offset();
			
			var messageType:Int = stream.read();
			//var messageLength:Int = stream.readInt16();
			
			var message:Message = factory.decodeMessage(stream, messageType);
			var messageEnd:Int = stream.offset();
			payloadBodyAvailable-= messageEnd-messageStart;
			if (message != null){
				message.sentTime = sentTime;
				messages.push(message);
			}else{
				trace("payloadLength", payloadLength);
				break;
			}
		}
		*/
		messages = MessageUtil.unpackMessages(stream, factory, sentTime);
		
		lock.release();
		return messages;
	}
	public static function create(id:Int, length:Int, localAck:Int, localAckInt:Int, time:Float, messages:Array<Message>):Payload{
		var payload:Payload = new Payload(id);
		//payload.length = PAYLOAD_HEADER + length;
		payload.bytes = Bytes.alloc(length);
		payload.ack = localAck;
		payload.ackInt = localAckInt;
		payload.messages = messages;
		payload.sentTime = time;
		var stream:BytesStream = new BytesStream(payload.bytes, 0);
		var flags:Int = 0;
		//stream.writeInt16(id);
		stream.writeInt16(localAck);
		stream.writeInt32(localAckInt);
		stream.writeDouble(payload.sentTime);
		stream.write(flags);
		/*
		var lengthPos:Int = stream.offset();
		stream.writeInt16(0);
		var posBeforeMessages:Int = stream.offset();
		for (message in messages){
			stream.write(message.type);
			//var anchor:Int = stream.offset();
			//stream.writeInt16(0);
			var posBeforePack:Int = stream.offset();
			message.pack(stream);
			var messageLength:Int = stream.offset() - posBeforePack;
			var expectedLength:Int = message.measureSize();
			if (expectedLength != messageLength){
				trace("Warnning, message not match measuring size", message, expectedLength, messageLength);
			}
			//BytesUtil.writeUnsignedInt16(payload.bytes, anchor, messageLength);
		}
		var messagesLength:Int = stream.offset() - posBeforeMessages;
		BytesUtil.writeUnsignedInt16(payload.bytes, lengthPos, messagesLength);
		*/
		MessageUtil.packMessages(stream, messages);
		
		payload.length = stream.offset();
		return payload;
	}
	public function getBytes():Bytes{
		return bytes;
	}
	public function getPointer():BytesPointer{
		return BytesPointer.create(bytes, 0, length);
	}
}