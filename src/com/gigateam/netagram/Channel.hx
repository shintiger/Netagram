package com.gigateam.netagram;
import sys.net.Address;

/**
 * ...
 * @author Tiger
 */
class Channel extends EndpointList implements IMessageSender
{
	public function sendImportant(message:Message):Int{
		var sent:Int = 0;
		for (client in clients){
			var cloned:Message = message.clone();
			client.sendImportant(cloned);
			sent += 1;
		}
		return sent;
	}
	public function sendReliable(message:Message):Int{
		var sent:Int = 0;
		for (client in clients){
			var cloned:Message = message.clone();
			client.sendReliable(cloned);
			sent += 1;
		}
		return sent;
	}
	public function send(message:Message):Int{
		var sent:Int = 0;
		for (client in clients){
			var cloned:Message = message.clone();
			client.send(cloned);
			sent += 1;
		}
		return sent;
	}
	public function getEarliestAckedMessageTime(before:Float):Float{
		var earliest:Float = before;
		for (client in clients){
			if (client.getLastAckedMessageTime() < earliest){
				earliest = client.getLastAckedMessageTime();
			}
		}
		return earliest;
	}
	override public function set(addr:Address, client:SwitchlessEndpoint):Void{
		super.set(addr, client);
	}
	override public function remove(addr:Address):Void{
		super.remove(addr);
	}
	private function onSubscribe(client:SwitchlessEndpoint):Void{
		
	}
	private function onUnsubscribe(client:SwitchlessEndpoint):Void{
		
	}
}