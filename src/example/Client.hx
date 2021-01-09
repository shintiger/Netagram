package example;

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
	static function main() {
		MessageRegistry.getInstance().register(new PositionMessage());

		var connected:Bool = false;
		var factory:MessageFactory = new MessageFactory(MessageRegistry.getInstance());
		var client:Netagram = new Netagram(new Host("127.0.0.1"), 12345, factory);

		client.onConnected = function():Void {
			connected = true;
		};

		client.onMessage = function(message:Message):Void {
			trace("Unknow message", message);
		};

		client.mannualHandleMessage = false;
		client.start();
		var position:PositionMessage = new PositionMessage();
		position.floatX = 1;
		position.floatY = 2;
		client.send(position);
		#if sys
		while (true) {
			Sys.sleep(1000);
		}
		#end
	}
}
