package com.gigateam.netagram;
import com.gigateam.util.NetworkTool;
import haxe.io.Bytes;
import sys.net.Address;
import sys.net.UdpSocket;

/**
 * ...
 * @author Tiger
 */
class SwitchlessEndpoint extends DuplexStream
{
	public var addr:Address;
	public var addrFloat:Float;
	public var addrString:String = "";
	public var token:String = "";
	public var accepted:Bool = false;
	public function new(sock:UdpSocket, addr:Address) 
	{
		super(1024, addr, sock);
	}
	
	override public function send(message:Message):Int{
		if (!accepted){
			throw "Please send after endpoint accepted.";
		}
		return super.send(message);
	}
	
	override public function sendReliable(message:Message):Int{
		if (!accepted){
			throw "Please send after endpoint accepted.";
		}
		return super.sendReliable(message);
	}
	
	override public function sendImportant(message:Message):Int{
		if (!accepted){
			throw "Please send after endpoint accepted.";
		}
		return super.sendImportant(message);
	}
	
	public function sendBytes(bytes:Bytes, time:Float):Int{
		//return sendBytes(bytes, bytes.length);
		//return sendTo(impl, bytes, bytes.length, time);
		return 0;
	}
	public function toString():String{
		return NetworkTool.addressToString(address) + ":" + Std.string(address.port);
	}
	override public function allocate(factory:MessageFactory, bufferSize:Int):Void{
		super.allocate(factory, bufferSize);
		accepted = true;
	}
	override public function flush(impl:UdpSocket, time:Float):Int{
		if (!accepted){
			return -1;
		}
		return super.flush(impl, time);
	}
	public function subscribe(channel:Channel):Void{
		if (channel.exists(addr)){
			throw "Subscriber exists.";
		}
		channel.set(addr, this);
	}
	public function unsubscribe(channel:Channel):Void{
		if (!channel.exists(addr)){
			throw "Subscriber not exists.";
		}
		channel.remove(addr);
	}
	public function shouldProcess(message:Message):Array<Message>{
		return [message];
	}
}