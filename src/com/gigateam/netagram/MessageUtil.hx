package com.gigateam.netagram;
import com.gigateam.util.BytesStream;
import com.gigateam.util.BytesUtil;

/**
 * ...
 * @author 
 */
class MessageUtil 
{

	public function new() 
	{
		
	}
	public static function packMessages(stream:BytesStream, messages:Array<Message>):Int{
		var lengthPos:Int = stream.offset();
		stream.writeInt16(0);
		var posBeforeMessages:Int = stream.offset();
		for (message in messages){
			if (!MessageRegistry.getInstance().messageTypeExists(message.type)){
				var className:String = Type.getClassName(Type.getClass(message));
				throw "Message type '"+Std.string(message.type)+"' ("+className+") not found in MessageRegistry.";
			}
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
		BytesUtil.writeUnsignedInt16(stream.bytes(), lengthPos, messagesLength);
		
		return messagesLength;
	}
	public static function unpackMessages(stream:BytesStream, factory:MessageFactory, sentTime:Float):Array<Message>{
		var bodyAvailable:Int = stream.readInt16();
		var messages:Array<Message> = [];
		while (bodyAvailable > 0){
			//trace("payloadBodyAvailable", payloadBodyAvailable);
			var messageStart:Int = stream.offset();
			
			var messageType:Int = stream.read();
			//var messageLength:Int = stream.readInt16();
			
			var message:Message = factory.decodeMessage(stream, messageType);
			var messageEnd:Int = stream.offset();
			bodyAvailable-= messageEnd-messageStart;
			if (message != null){
				message.sentTime = sentTime;
				messages.push(message);
			}else{
				throw "Unknown message type:" + Std.string(message.type);
			}
		}
		return messages;
	}
	
	public static function measureSizes(messages:Array<Message>):Int{
		var sumSize:Int = 2;
		for (i in 0...messages.length){
			//1byte for message type
			sumSize += messages[i].measureSize() + 1;
		}
		return sumSize;
	}
}