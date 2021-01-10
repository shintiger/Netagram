package com.gigateam.netagram;

import com.gigateam.util.BytesStream;
import hx.concurrent.lock.RLock;

/**
 * ...
 * @author ...
 */
class MessageFactory {
	public static inline var MESSAGE_MAX:UInt = 65535;

	private var registry:MessageRegistry;

	public var sentIndex:RollingIndex;

	private var receiveIndex:RollingIndex;

	private var messages:Map<Int, Message> = new Map();
	private var outgoingMessages:Array<Message> = [];
	private var reliableMessages:Array<Message> = [];
	private var importantMessages:Array<Message> = [];

	private var lock:RLock = new RLock();

	public function new(messageRegistry:MessageRegistry) {
		registry = messageRegistry;
		sentIndex = RollingIndex.fromMax(MESSAGE_MAX);
		receiveIndex = RollingIndex.fromMax(MESSAGE_MAX);
	}

	public function enqueueMessage(message:Message):Int {
		lock.acquire();

		if (message == null) {
			throw "Cannot enqueue null message.";
		}
		outgoingMessages.push(message);
		var result:Int = appendMessage(message);

		lock.release();
		return result;
	}

	private function appendMessage(message:Message):Int {
		var messageId:Int = sentIndex.index;
		// message.messageId = messageId;
		message.ship(messageId);
		messages.set(messageId, message);
		sentIndex.add(1);
		return messageId;
	}

	public function sort():Void {
		lock.acquire();

		reliableMessages.sort(function(a:Message, b:Message):Int {
			if (a == null || b == null) {
				return 0;
			}
			if (a.sentTime < b.sentTime) {
				return -1;
			} else if (a.sentTime > b.sentTime) {
				return 1;
			}
			return 0;
		});

		lock.release();
	}

	private function fetchNonAck(time:Float):Message {
		if (reliableMessages.length == 0) {
			return null;
		}

		for (message in reliableMessages) {
			if ((time - message.sentTime) > 0.1) {
				message.resend(time);
				return message;
			}
		}

		return null;
	}

	private function fetchMessage(time:Float):Message {
		if (outgoingMessages.length == 0) {
			return null;
		}

		var message:Message = outgoingMessages.shift();

		if (message == null) {
			trace("Notice: null message appear in list");
			return null;
		}

		message.resend(time);
		return message;
	}

	public function fetchMessages(time:Float, bandwidthAvailable:Int, messageIds:Array<Int>):Array<Message> {
		lock.acquire();

		var message:Message;
		var messages:Array<Message> = [];
		var j:Int = 0;
		while (j < importantMessages.length) {
			var important:Message = importantMessages[j];
			if (important.discarded()) {
				importantMessages.splice(j, 1);
				continue;
			}
			bandwidthAvailable -= important.measureSize();
			messageIds.push(important.messageId);
			messages.push(important);
			j += 1;
		}

		var reliable:Message = fetchNonAck(time);

		if (reliable != null) {
			messages.push(reliable);
			messageIds.push(reliable.messageId);
			bandwidthAvailable -= reliable.measureSize();
		}

		while (bandwidthAvailable > 0) {
			message = fetchMessage(time);
			if (message == null) {
				break;
			}

			bandwidthAvailable -= message.measureSize();
			messages.push(message);
			messageIds.push(message.messageId);
		}

		lock.release();
		return messages;
	}

	public function enqueueImportantMessage(message:Message):Int {
		lock.acquire();

		importantMessages.push(message);
		var result:Int = appendMessage(message);

		lock.release();
		return result;
	}

	public function enqueueReliableMessage(message:Message):Int {
		lock.acquire();

		reliableMessages.push(message);
		var result:Int = appendMessage(message);

		lock.release();
		return result;
	}

	public function decodeMessage(stream:BytesStream, messageType:Int):Message {
		var message:Message = null;

		try {
			message = registry.createMessage(messageType);
			afterCreated(stream, message, messageType);
		} catch (e:Dynamic) {
			return null;
		}
		return message;
	}

	private function afterCreated(stream:BytesStream, message:Message, messageType:Int):Void {
		if (message != null) {
			if (message.type != messageType) {
				throw "Message type not match.";
			}

			message.factory = this;
			message.unpack(stream, messageType);
		}
	}

	public function ackMessage(id:Int):Message {
		lock.acquire();

		var message:Message;
		message = getReliableMessageById(id);
		if (message != null) {
			var index:Int = reliableMessages.indexOf(message);
			if (index >= 0) {
				reliableMessages.splice(index, 1);
			} else {
				index = importantMessages.indexOf(message);
				if (index >= 0) {
					importantMessages.splice(index, 1);
				} else {
					throw "Logic error.";
				}
			}
		}
		if (messages.exists(id)) {
			message = messages.get(id);
			messages.remove(id);
			message.acked = true;
			if (message.onAcknowledged != null) {
				message.onAcknowledged();
			}
			lock.release();
			return message;
		}

		lock.release();
		return null;
	}

	private function getMessageById(id:Int):Message {
		if (messages.exists(id)) {
			return messages.get(id);
		}

		return null;
	}

	private function getReliableMessageById(id:Int):Message {
		for (message in reliableMessages) {
			if (message.messageId == id) {
				return message;
			}
		}

		for (message in importantMessages) {
			if (message.messageId == id) {
				return message;
			}
		}
		return null;
	}

	public function numReliableMessages():Int {
		return reliableMessages.length;
	}
}
