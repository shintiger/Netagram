package example;

import example.PositionMessage;
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

		var channel:Channel = new Channel();
		var server:NetagramHost = new NetagramHost("0.0.0.0", 12345);

		server.callback = function(message:Message, client:NetagramEndpoint):Void {
			var responseMessage:BytesMessage = BytesMessage.fromUTF('{"x":0}');
			if (Std.is(message, PositionMessage)) {
				var position:PositionMessage = cast message;
				trace("Received position message", position.floatX, position.floatY);
			}
			channel.send(responseMessage);
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
