package example.message;

import haxe.Json;
import com.gigateam.netagram.Message;
import com.gigateam.util.BytesStream;
import haxe.ds.Vector;

typedef DoubleFloat = {
	var doubleFloatX:Float;
	var doubleFloatY:Float;
}

/**
 * ...
 * @author
 */
class JsonMessage extends Message {
	public var data:DoubleFloat;

	public function new() {
		super(244);
	}

	override public function pack(stream:BytesStream):Void {
		super.pack(stream);
		var content:String = Json.stringify(data);
		stream.writeUTF(content);
	}

	override public function unpack(stream:BytesStream, messageType:Int):Void {
		super.unpack(stream, messageType);
		var content:String = stream.readUTF();
		data = Json.parse(content);
	}

	override private function measuringSize():Int {
		var content:String = Json.stringify(data);
		// UTF data always has 2 bytes overhead
		return super.measuringSize() + content.length + 2;
	}

	override public function clone():Message {
		var json:JsonMessage = new JsonMessage();
		json.data = data;
		return json;
	}
}
