package example;

import com.gigateam.netagram.Message;
import com.gigateam.util.BytesStream;
import haxe.ds.Vector;

/**
 * ...
 * @author
 */
class PositionMessage extends Message {
	public var floatX:Float = 0;
	public var floatY:Float = 0;

	public function new() {
		super(245);
	}

	override public function pack(stream:BytesStream):Void {
		super.pack(stream);
		stream.writeDouble(floatX);
		stream.writeDouble(floatY);
	}

	override public function unpack(stream:BytesStream, messageType:Int):Void {
		super.unpack(stream, messageType);
		floatX = stream.readDouble();
		floatY = stream.readDouble();
	}

	override private function measuringSize():Int {
		return super.measuringSize();
	}

	override public function clone():Message {
		var message:PositionMessage = new PositionMessage();
		return message;
	}
}
