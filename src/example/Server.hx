package example;

import example.message.JsonMessage;
import example.message.PositionMessage;
import com.gigateam.netagram.MessageRegistry;
import com.gigateam.netagram.Channel;
import com.gigateam.netagram.BytesMessage;
import com.gigateam.netagram.NetagramEndpoint;
import com.gigateam.netagram.Message;
import com.gigateam.netagram.NetagramHost;

/**
 * ...
 * @author
 */
class Server {
	static function main() {
		MessageRegistry.getInstance().register(new PositionMessage());
		MessageRegistry.getInstance().register(new JsonMessage());

		var channel:Channel = new Channel();
		var server:NetagramHost = new NetagramHost("0.0.0.0", 12345);

		server.callback = function(message:Message, client:NetagramEndpoint):Void {
			if (Std.is(message, PositionMessage)) {
				var position:PositionMessage = cast message;
				trace("Received position message", position.floatX, position.floatY);
				var jsonMessage:JsonMessage = new JsonMessage();
				jsonMessage.data = {
					'doubleFloatX': position.floatX * 2,
					'doubleFloatY': position.floatY * 2
				}
				channel.send(jsonMessage);
			} else {
				trace("Unknown message received.");
			}
		}

		server.onAccepted = function(client:NetagramEndpoint):Void {
			client.subscribe(channel);
			trace("New client accepted: " + client.addrString + ", clients in channel", channel.numClients());
		};

		server.onDisconnect = function(client:NetagramEndpoint):Void {
			client.unsubscribe(channel);
			trace("Removed from channel", channel.numClients());
		};

		server.preUpdate = function(time:Float):Void {
			// trace("step world");
		};

		server.start(50);

		while (true) {
			Sys.sleep(1);
		}
	}
}
