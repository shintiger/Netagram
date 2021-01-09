package com.gigateam.netagram;

import com.gigateam.util.BytesStream;
import com.gigateam.util.BytesUtil;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import hx.concurrent.lock.RLock;
import sys.net.Address;
import sys.net.UdpSocket;

/**
 * ...
 * @author Tiger
 */
class DuplexStream extends BufferReader implements IMessageSender {
	public static inline var DEFAULT_TIMEOUT:Float = 8;
	public static inline var WINDOW_SIZE:UInt = 32;
	public static inline var MAX_FRAGMENT:UInt = 128;
	public static inline var MTU:UInt = 1024;
	public static inline var FRAGMENT_BUFFFER_SIZE:UInt = MTU + Fragment.HEADER_LENGTH;
	public static inline var BYTES_PER_SECOND:UInt = 128 * 1024 * 1000;

	private var RTT:Float = -1;
	private var SRTT:Float = -1;

	private var sentBaseTime:Float = -1;
	private var receiveBaseTime:Float = -1;

	public var lastReceived:Float = 0;

	private var terminated:Bool = false;

	private var address:Address;
	private var lastSent:Float = 0;
	private var lastAckedMessageTime:Float = -1;
	private var fragmentBuffer:Bytes;
	private var receiveBuffer:Bytes;
	private var receivedPayload:Map<Int, Payload>;
	private var receivedFlags:Int = 0;

	private var ack:Int = 0xffff;
	private var messagesIndexes:Map<Int, Array<Int>>;
	private var blockSentIndex:RollingIndex;
	private var blockReceiveIndex:RollingIndex;

	private var sentIndex:RollingIndex;
	private var receiveIndex:RollingIndex;

	private var sentBlock:Map<Int, Block>;
	private var receiveBlock:Map<Int, Block>;

	private var lock:RLock = new RLock();

	private var messageFactory:MessageFactory;

	private var impl:UdpSocket;

	public function new(bufferSize:Int, addr:Address, socket:UdpSocket) {
		address = addr;
		sentIndex = RollingIndex.fromMax(65535);
		receiveIndex = RollingIndex.fromMax(65535);
		blockSentIndex = RollingIndex.fromMax(128);
		blockReceiveIndex = RollingIndex.fromMax(128);
		receiveIndex.index = 0xffff;
		super(bufferSize);
		receivedFlags = 0;
		receivedPayload = new Map();
		messagesIndexes = new Map();
		sentBlock = new Map();
		receiveBlock = new Map();
		impl = socket;
		sentBaseTime = Sys.time();
		fragmentBuffer = Bytes.alloc(FRAGMENT_BUFFFER_SIZE * MAX_FRAGMENT);

		// receiveBuffer = Bytes.alloc(FRAGMENT_BUFFFER_SIZE * MAX_FRAGMENT * WINDOW_SIZE);
	}

	public function setReceiveBaseTime(time:Float):Void {
		if (receiveBaseTime >= 0) {
			return;
		}
		receiveBaseTime = time;
	}

	public function getReceiveBaseTime():Float {
		return receiveBaseTime;
	}

	public function getSentBaseTime():Float {
		return sentBaseTime;
	}

	public function acquire():Void {
		lock.acquire();
	}

	public function release():Void {
		lock.release();
	}

	public function allocate(factory:MessageFactory, bufferSize:Int):Void {
		resetBuffer(bufferSize);
		messageFactory = factory;
	}

	public function send(message:Message):Int {
		return messageFactory.enqueueMessage(message);
	}

	public function sendReliable(message:Message):Int {
		if (message.measureSize() + 1 > SliceMessage.SLICE_LENGTH) {
			/*var slices:Array<SliceMessage> = SliceMessage.split(message);
				for (slice in slices){
					slice.blockId = blockSentIndex.index;
					sendReliable(slice);
			}*/
			var block:Block = Block.fromMessage(blockSentIndex.index, message);
			sentBlock.set(blockSentIndex.index, block);
			blockSentIndex.add(1);

			var slices:Map<Int, SliceMessage> = block.getSlices();
			for (slice in slices) {
				// trace("send slice", slice.blockId, slice.sliceId);
				_sendReliable(slice);
				// var stream:BytesStream = new BytesStream(slice.bytes, 0);
				// trace(slice.sliceId, stream.toHex(30));
			}
			return -1;
		}
		return _sendReliable(message);
	}

	private function _sendReliable(message:Message):Int {
		return messageFactory.enqueueReliableMessage(message);
	}

	public function sendImportant(message:Message):Int {
		return messageFactory.enqueueImportantMessage(message);
	}

	public function flush(impl:UdpSocket, time:Float):Int {
		acquire();
		var dt:Float = time - lastSent;
		var bandwidthAvailable:UInt = Std.int(BYTES_PER_SECOND * dt);
		lastSent = time;
		var messageIds:Array<Int> = [];
		var messages:Array<Message> = messageFactory.fetchMessages(time, bandwidthAvailable, messageIds);
		/*
			while (true){
				message = messageFactory.fetchMessage(time);
				if (message == null){
					break;
				}
				bandwidthAvailable-= message.measureSize();
				messages.push(message);
				messageIds.push(message.messageId);
			}
			if (bandwidthAvailable > 0){
				var reliable:Message = messageFactory.fetchNonAck(time);
				if(reliable!=null){
					messages.unshift(reliable);
					messageIds.unshift(reliable.messageId);
					bandwidthAvailable-= reliable.measureSize();
				}
			}
		 */
		// var payload:Payload = Payload.create(sentIndex.index, 65535, receiveIndex.index, receivedFlags, time, messages);
		var payload:Payload = Payload.create(sentIndex.index, 65535, receiveIndex.index, receivedFlags, time - sentBaseTime, messages);
		// trace(time, sentBaseTime, time-sentBaseTime);
		sentIndex.add(1);
		messagesIndexes.set(payload.payloadId, messageIds);
		messageFactory.sort();
		sendPayload(payload);
		release();
		return 0;
	}

	///public function sendPayload(impl:UdpSocket, bytes:Bytes, length:UInt):Int{
	public function sendPayload(payload:Payload):Int {
		// trace("sending payload", payload.payloadId, payload.length);
		var payloadPointer:BytesPointer = payload.getPointer();
		var length:Int = payloadPointer.length;
		// trace("Payload length:", length);
		var sentBytes:Int = 0;
		var lastFragmentLength:UInt = length % MTU;
		var numFragments:UInt = Math.ceil(length / MTU);
		if (numFragments > MAX_FRAGMENT) {
			throw "Fragments exceed maximum.";
		}
		for (i in 0...numFragments) {
			// trace("Fragment num:", i);
			var srcPointer:BytesPointer = new BytesPointer();
			var dstPointer:BytesPointer = new BytesPointer();
			var srcPos:UInt = i * MTU;
			var dstPos:UInt = i * FRAGMENT_BUFFFER_SIZE;
			var flags:UInt = i;
			srcPointer.reference = payloadPointer.reference;
			srcPointer.position = srcPos;
			dstPointer.reference = fragmentBuffer;
			dstPointer.position = dstPos;
			if (i == (numFragments - 1)) {
				// is last fragment
				flags |= 0x80;
				srcPointer.length = lastFragmentLength;
			} else {
				srcPointer.length = MTU;
			}

			/*
				dstPos += BytesUtil.writeUnsignedInt16(fragmentBuffer, dstPos, payload.payloadId);
				dstPos += BytesUtil.write(fragmentBuffer, dstPos, flags);
				dstPos += BytesUtil.writeBytes(srcPointer.reference, srcPointer.position, fragmentBuffer, dstPos, srcPointer.length);

				dstPointer.length = dstPos - dstPointer.position;
			 */

			var fragmentBody:Bytes = Bytes.alloc(srcPointer.length);
			BytesUtil.writeBytes(srcPointer.reference, srcPointer.position, fragmentBody, 0, srcPointer.length);
			var crc32:Int = Crc32.make(fragmentBody);

			var fragmentStream:BytesStream = new BytesStream(fragmentBuffer, dstPos);
			fragmentStream.writeInt16(payload.payloadId);
			fragmentStream.write(flags);
			fragmentStream.writeInt32(crc32);
			fragmentStream.writeStream(new BytesStream(srcPointer.reference, srcPointer.position), srcPointer.length);

			dstPointer.length = fragmentStream.offset() - dstPointer.position;

			sentBytes += rawSend(impl, dstPointer);
		}
		return sentBytes;
	}

	public function terminate():Void {
		terminated = true;
	}

	public function rawSend(impl:UdpSocket, pointer:BytesPointer):Int {
		if (terminated) {
			return -1;
		}
		return impl.sendTo(pointer.reference, pointer.position, pointer.length, address);
	}

	public function fetchMessage():Array<Message> {
		acquire();
		var messages:Array<Message> = [];
		var length:Int = bufferPosition;
		bufferPosition = 0;
		// super.readInto(bytes);
		var fragment:Fragment = Fragment.fromBytes(BytesPointer.create(buffer, 0, length));
		var payload:Payload;
		if (fragment == null) {
			release();
			return messages;
		}
		if (fragment.length > MTU) {
			release();
			return messages;
		}
		if (receivedPayload.exists(fragment.payloadId)) {
			payload = receivedPayload.get(fragment.payloadId);
		} else {
			payload = new Payload(fragment.payloadId);
			receivedPayload.set(payload.payloadId, payload);
		}
		if (!payload.insert(fragment)) {
			trace("insert fail");
			release();
			return messages;
		}
		if (payload.completed()) {
			var diff:Int = receiveIndex.greaterThan(payload.payloadId);
			if (receiveIndex.index == 0xffff || diff < 0) {
				if (receiveIndex.index == 0xffff) {
					receivedFlags = 1;
				} else {
					receivedFlags >>= diff;
					receivedFlags |= 1;
				}
				receiveIndex.index = payload.payloadId;
			} else {
				receivedFlags |= 1 >> diff;
			}
			messages = payload.parseMessages(messageFactory, receiveBaseTime);
			//
			var j:Int = 0;
			while (j < messages.length) {
				var message:Message = messages[j];
				if (Std.is(message, SliceMessage)) {
					var slice:SliceMessage = cast message;
					var block:Block;
					if (receiveBlock.exists(slice.blockId)) {
						block = receiveBlock.get(slice.blockId);
					} else {
						block = new Block(slice.blockId);
						receiveBlock.set(block.blockId, block);
					}
					var appendResult:Bool = block.append(slice);
					if (block.completed()) {
						messages[j] = block.getMessage(messageFactory);
						receiveBlock.remove(block.blockId);
						j += 1;
					} else {
						messages.splice(j, 1);
					}
				} else {
					j += 1;
				}
			}
			for (i in 0...32) {
				if ((payload.ackInt & (1 << i)) > 0) {
					ackPayload(payload.ack - i);
				}
			}
			// trace("numFragments", payload.numFragments, "messages", messages.length);
			lastReceived = Sys.time();
			receivedPayload.remove(payload.payloadId);
		}
		release();
		return messages;
	}

	private function getSentBlockFromMessageId(messageId:Int):Block {
		for (block in sentBlock) {
			// trace(block.blockId, messageId);
			if (block.containSlice(messageId)) {
				return block;
			}
		}
		return null;
	}

	public function ackPayload(payloadId:Int):Void {
		var time:Float = Sys.time();
		var indexes:Array<Int>;
		if (!messagesIndexes.exists(payloadId)) {
			return;
		}
		indexes = messagesIndexes.get(payloadId);
		for (index in indexes) {
			var message:Message = messageFactory.ackMessage(index);
			if (message == null) {
				// Acked message
				trace("Warnning: duplicate received, messageId:", index, "Pending reliable messages length:", messageFactory.numReliableMessages());
				continue;
			}
			if (message.sentTime > lastAckedMessageTime) {
				lastAckedMessageTime = message.sentTime;
			}
			RTT = (time - message.sentTime);
			if (SRTT <= 0) {
				SRTT = RTT;
			} else {
				SRTT = SRTT * 7 / 8 + RTT * 1 / 8;
			}
			if (Std.is(message, SliceMessage)) {
				var slice:SliceMessage = cast message;
				var block:Block = getSentBlockFromMessageId(slice.messageId);
				// trace(block);
				if (block != null) {
					// trace(block.numSlices, block.numAcked);
					if (block.ackedSlices(slice.sliceId)) {
						sentBlock.remove(block.blockId);
					}
				}
			}
		}
		messagesIndexes.remove(payloadId);
	}

	public function getSRTT():Int {
		return Math.ceil(SRTT * 1000);
	}

	public function getLastAckedMessageTime():Float {
		return lastAckedMessageTime;
	}
}
