package com.gigateam.netagram;
import com.gigateam.util.BytesStream;
import haxe.io.Bytes;

/**
 * ...
 * @author Tiger
 */
class BytesMessage extends Message
{
	private var content:BytesPointer;
	public function new() 
	{
		super(254);
	}
	override public function pack(stream:BytesStream):Void{
		super.pack(stream);
		//stream.writeInt16(content.length);
		var inStream:BytesStream = new BytesStream(content.reference, content.position);
		stream.writeInt16(content.length);
		stream.writeStream(inStream, content.length);
	}
	override public function unpack(stream:BytesStream, messageType:Int):Void{
		var originPos:Int = stream.offset();
		super.unpack(stream, messageType);
		//var headerLength:Int = stream.offset() - originPos;
		//var bodyLength:Int = length - headerLength;
		var bodyLength:Int = stream.readInt16();
		var bytes:Bytes = Bytes.alloc(bodyLength);
		var dstStream:BytesStream = new BytesStream(bytes, 0);
		stream.readStream(dstStream, bodyLength);
		content = BytesPointer.create(bytes, 0, bodyLength);
	}
	override private function measuringSize():Int{
		return super.measuringSize() + 2 + content.length;
	}
	public static function fromBytes(pointer:BytesPointer):BytesMessage{
		var message:BytesMessage = new BytesMessage();
		message.content = pointer;
		return message;
	}
	public static function fromUTF(str:String):BytesMessage{
		var bytes:Bytes = Bytes.alloc(str.length + 3);
		var stream:BytesStream = new BytesStream(bytes, 0);
		stream.writeUTF(str);
		var pointer:BytesPointer = BytesPointer.create(bytes, 0, stream.offset());
		var message:BytesMessage = BytesMessage.fromBytes(pointer);
		return message;
	}
	public function readUTF():String{
		var stream:BytesStream = new BytesStream(content.reference, content.position);
		return stream.readUTF();
	}
	public function getPointer():BytesPointer{
		return content;
	}
	override public function clone():Message{
		var message:BytesMessage = new BytesMessage();
		message.content = content;
		return message;
	}
}