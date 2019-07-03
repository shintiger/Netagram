package com.gigateam.netagram;
import com.gigateam.util.BytesStream;

/**
 * ...
 * @author Tiger
 */
class ConnectionMessage extends Message
{
	public static inline var CONNECT:Int = 1;
	public static inline var DISCONNECT:Int = 2;
	public static inline var HEART_BEAT:Int = 3;
	
	public var action:Int;
	public function new(action:Int) 
	{
		this.action = action;
		super(255);
	}
	override public function pack(stream:BytesStream):Void{
		super.pack(stream);
		stream.write(action);
		//stream.writeInt16(content.length);
	}
	override public function unpack(stream:BytesStream, messageType:Int):Void{
		//var originPos:Int = stream.offset();
		super.unpack(stream, messageType);
		//var headerLength:Int = stream.offset() - originPos;
		action = stream.read();
	}
	override private function measuringSize():Int{
		return super.measuringSize() + 1;
	}
	override public function clone():Message{
		var message:ConnectionMessage = new ConnectionMessage(action);
		return message;
	}
}