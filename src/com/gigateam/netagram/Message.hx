package com.gigateam.netagram;
import com.gigateam.util.BytesStream;
import haxe.io.Bytes;

/**
 * ...
 * @author ...
 */
class Message 
{
	private var _discarded:Bool = false;
	public var factory:MessageFactory;
	public var acked:Bool = false;
	public var onAcknowledged:Void->Void;
	public var type:Int;
	public var messageId:Int = -1;
	public var sentTime:Float;
	public var payloadIds:Array<Int> = [];
	public function new(messageType:Int) 
	{
		init(messageType);
	}
	public function ship(id:Int):Void{
		if (messageId >= 0){
			throw "This message already shipped";
		}
		messageId = id;
	}
	public function discard():Void{
		_discarded = true;
	}
	public function discarded():Bool{
		return _discarded;
	}
	public function pack(stream:BytesStream):Void{}
	public function unpack(stream:BytesStream, messageType:Int):Void{}
	public function getMessageType():Int{
		return type;
	}
	public function resend(time:Float):Void{
		sentTime = time;
	}
	public function measureSize():Int{
		var size:Int = measuringSize();
		if (size > 0){
			return size;
		}
		var bytes:Bytes = Bytes.alloc(4096);
		var stream:BytesStream = new BytesStream(bytes, 0);
		pack(stream);
		return stream.offset();
	}
	private function measuringSize():Int{
		return 0;
	}
	private function init(messageType:Int):Void{
		type = messageType;
	}
	public function clone():Message{
		return null;
	}
}