package example;

import example.message.JsonMessage;
import example.message.PositionMessage;
import com.gigateam.netagram.Message;
import sys.net.Host;
import com.gigateam.netagram.Netagram;
import com.gigateam.netagram.MessageFactory;
import com.gigateam.netagram.MessageRegistry;

/**
 * ...
 * @author
 */
class Client {
	private static var latestFloatX:Float = 0;
	private static var latestFloatY:Float = 0;

	static function main() {
		MessageRegistry.getInstance().register(new PositionMessage());
		MessageRegistry.getInstance().register(new JsonMessage());

		var connected:Bool = false;
		var factory:MessageFactory = new MessageFactory(MessageRegistry.getInstance());
		var client:Netagram = new Netagram(new Host("127.0.0.1"), 12345, factory);

		client.onConnected = function():Void {
			connected = true;
		};

		client.onMessage = function(message:Message):Void {
			if (Std.is(message, JsonMessage)) {
				var jsonMessage:JsonMessage = cast message;

				trace("Incoming message", message, jsonMessage.data.doubleFloatX, jsonMessage.data.doubleFloatY);
				if ((latestFloatX * 2) == jsonMessage.data.doubleFloatX && (latestFloatY * 2) == jsonMessage.data.doubleFloatY) {
					trace("Message is as expected!");
				}
			} else {
				trace("Unknown message", message);
			}
		};

		client.mannualHandleMessage = false;
		client.start();

		#if sys
		while (true) {
			Sys.sleep(3);
			if (connected) {
				var position:PositionMessage = new PositionMessage();
				position.floatX = Math.floor(Math.random() * 1000) / 100;
				position.floatY = Math.floor(Math.random() * 1000) / 100;

				latestFloatX = position.floatX;
				latestFloatY = position.floatY;

				client.sendReliable(position);

				trace("Sending floatX:", position.floatX, "floatY:", position.floatY);
			}
		}
		#end
	}
}
