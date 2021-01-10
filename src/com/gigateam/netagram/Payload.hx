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
class Payload {
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

	public function new(id:Int) {
		payloadId = id;
		fragments = new Map();
		lock = new RLock();
	}

	public function insert(fragment:Fragment):Bool {
		if (completed() || fragments.exists(fragment.fragmentId)) {
			if (completed()) {
				trace("completed payload");
			} else {
				trace("fragment exists");
			}
			return false;
		}
		lock.acquire();
		numFragments += 1;
		fragments.set(fragment.fragmentId, fragment);
		if (fragment.isLastFragment) {
			lastFragmentId = fragment.fragmentId;
		}
		if (completed()) {
			bytes = Bytes.alloc(DuplexStream.MTU * numFragments);

			var pos:Int = 0;
			for (i in 0...numFragments) {
				var item:Fragment = fragments.get(i);
				if (item == null) {
					for (key in fragments.keys()) {
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

	public function completed():Bool {
		return (lastFragmentId >= 0 && numFragments > lastFragmentId);
	}

	public function parseMessages(factory:MessageFactory, baseTime:Float):Array<Message> {
		if (!completed()) {
			return [];
		}

		lock.acquire();

		var stream:BytesStream = new BytesStream(bytes, 0);
		ack = stream.readInt16();
		ackInt = stream.readInt32();
		var readFloat:Float = stream.readDouble();
		sentTime = readFloat + baseTime;
		var flags:Int = stream.read();
		messages = MessageUtil.unpackMessages(stream, factory, sentTime);

		lock.release();
		return messages;
	}

	public static function create(id:Int, length:Int, localAck:Int, localAckInt:Int, time:Float, messages:Array<Message>):Payload {
		var payload:Payload = new Payload(id);
		// payload.length = PAYLOAD_HEADER + length;
		payload.bytes = Bytes.alloc(length);
		payload.ack = localAck;
		payload.ackInt = localAckInt;
		payload.messages = messages;
		payload.sentTime = time;
		var stream:BytesStream = new BytesStream(payload.bytes, 0);
		var flags:Int = 0;

		stream.writeInt16(localAck);
		stream.writeInt32(localAckInt);
		stream.writeDouble(payload.sentTime);
		stream.write(flags);

		MessageUtil.packMessages(stream, messages);

		payload.length = stream.offset();
		return payload;
	}

	public function getBytes():Bytes {
		return bytes;
	}

	public function getPointer():BytesPointer {
		return BytesPointer.create(bytes, 0, length);
	}
}
