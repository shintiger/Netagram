package com.gigateam.netagram;

import com.gigateam.util.BytesStream;
import com.gigateam.util.NetworkTool;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import hx.concurrent.executor.Executor;
import hx.concurrent.lock.RLock;
import sys.net.Address;
import sys.net.Host;
import sys.net.UdpSocket;

/**
 * ...
 * @author Tiger
 */
class NetagramHost 
{
	private var autoUpdate:Bool = true;
	private var lock:RLock = new RLock();
	private var executor1:Executor;
	private var executor2:Executor;
	
	private var secret:Int;
	private var globalStartTime:Float;
	//private var clients:Map<Float, SwitchlessClient>;
	private var clients:EndpointList = new EndpointList();
	private var host:Host;
	public var callback:Message->NetagramEndpoint->Void;
	public var onAccept:NetagramEndpoint->MessageFactory;
	public var onAccepted:NetagramEndpoint->Void;
	public var onDisconnect:NetagramEndpoint->Void;
	public var onRequest:UdpSocket->Address->NetagramEndpoint;
	public var onUpdate:Float->Void;
	public var preUpdate:Float->Void;
	private var impl:UdpSocket;
	public function new(host:String, port:Int) 
	{
		//var executor:Executor = Executor.create(1);
		//var future = executor.submit(loop, FIXED_RATE(100)); 
		secret = Math.ceil(Math.random() * 65535);
		impl = new UdpSocket();
		var _host = new Host(host);
		impl.bind(_host, port);
	}
	public static function fromExisting(old:UdpSocket):NetagramHost{
		var server:NetagramHost = new NetagramHost("0.0.0.0", 0);
		server.impl = old;
		return server;
	}
	//public function start(callback:Message->SwitchlessEndpoint->Void, onAccept:SwitchlessEndpoint->MessageFactory, onRequest:UdpSocket->Address->SwitchlessEndpoint, preUpdate:Float->Void, interval:Int):Void{
	
	public function start(interval:Int):Void{
		executor1 = Executor.create(1);
		executor2 = Executor.create(1);
		executor1.submit(read, FIXED_RATE(1)); 
		if (interval <= 0){
			autoUpdate = false;
		}
		if(autoUpdate){
			executor2.submit(innerUpdate, FIXED_RATE(interval));
		}
		globalStartTime = Sys.time();
		
		if (onAccept == null){
			onAccept = function(client:NetagramEndpoint):MessageFactory{
				return new MessageFactory(MessageRegistry.getInstance());
			};
		}
	}
	private function disableInterval():Bool{
		if (!autoUpdate){
			return false;
		}
		autoUpdate = false;
		return true;
	}
	public function update():Void{
		if (autoUpdate){
			return;
		}
		innerUpdate();
	}
	private function innerUpdate():Void{
		lock.acquire();
		var time:Float = Sys.time();
		if(preUpdate!=null){
			preUpdate(time);
		}
		if (onUpdate != null){
			try{
				onUpdate(time);
			}catch (e:Dynamic){
				trace("Exception", e);
			}
		}
		var removeClient:Address = null;
		var clientList:Array<NetagramEndpoint> = clients.getClients();
		for (client in clientList){
			var diff:Float = time-client.lastReceived;
			//trace("Time diff:" + Std.string(diff), time, client.lastReceived);
			if (client.lastReceived > 0 && diff > DuplexStream.DEFAULT_TIMEOUT){
				trace("Client timedout", diff, client.lastReceived);
				client.send(new ConnectionMessage(ConnectionMessage.DISCONNECT));
				removeClient = client.addr;
			}
			client.flush(impl, time);
		}
		if (removeClient != null){
			trace("removing client", NetworkTool.addressToHash(removeClient));
			if (onDisconnect != null){
				onDisconnect(clients.get(removeClient));
			}
			clients.remove(removeClient);
		}
		lock.release();
	}
	private function read():Void{
		impl.waitForRead();
		lock.acquire();
		var addr:Address = null;
		var buf:Bytes = null;
		var read:Int = -1;
		var addrFloat:Float = 0;
		var client:NetagramEndpoint;
		try{
			addr = new Address();
			buf = Bytes.alloc(2048);
			read = impl.readFrom(buf, 0, buf.length, addr);
			//var addrString:String = NetworkTool.addressToString6(addr);
			addrFloat = NetworkTool.addressToFloat(addr);
		}catch (e:Dynamic){
			var errorMsg:String = Std.string(e);
			switch(errorMsg){
				case "Custom(EOF)":
					
				default:
					trace("Unknown exception:", e);
			}
			//lock.release();
		}
		
		if (clients.exists(addr)){
			client = clients.get(addr);
		}else{
			trace("client not exists", addrFloat);
			if (onRequest != null){
				client = onRequest(impl, addr);
			}else{
				client = new NetagramEndpoint(impl, addr);
			}
			
			client.addrFloat = addrFloat;
			client.addr = addr;
			clients.set(addr, client);
		}
		if (!client.accepted){
			var stream:BytesStream = new BytesStream(buf, 0);
			var header:Int = stream.readInt32();
			if (header == Netagram.REQUEST_HEADER){
				var body:String = "";
				try{
					body = stream.readUTF();
					if (body.length != 64){
						trace("body not 64 length");
						lock.release();
						return;
					}else if (body == Netagram.REQUEST_COMMAND){
						client.setReceiveBaseTime(stream.readDouble());
						if (client.token == ""){
							client.token = Sha256.encode(Std.string(addrFloat) + Std.string(Sys.time()));
						}
						var respondBytes:Bytes = Bytes.alloc(client.token.length + 11);
						stream = new BytesStream(respondBytes, 0);
						stream.writeUTF(client.token);
						stream.writeDouble(client.getSentBaseTime());
						var pointer:BytesPointer = BytesPointer.create(respondBytes, 0, stream.offset());
						client.rawSend(impl, pointer);
						trace("responding", NetworkTool.addressToHash(addr), client.token, client.addrFloat);
					}else if (client.token == ""){
						trace("empty token", client.addrFloat);
						lock.release();
						return;
					}else if(body==client.token){
						//client.accept();
						trace("correct token!", client.addrFloat, body);
						client.allocate(onAccept(client), 65535);
						if (onAccepted != null){
							onAccepted(client);
						}
					}else{
						trace("wtf?");
						lock.release();
						return;
					}
				}catch (e:Dynamic){
					trace("exception", e);
					lock.release();
					return;
				}
			}
			lock.release();
			return;
		}
		client.append(buf, read);
		if (read < buf.length){
			var messages:Array<Message> = client.fetchMessage();
			for (message in messages){
				if (Std.is(message, ConnectionMessage)){
					var connectionMessage:ConnectionMessage = cast message;
					switch(connectionMessage.action){
						case ConnectionMessage.DISCONNECT:
							trace("Disconnect from client");
							if (onDisconnect != null){
								onDisconnect(client);
							}
							client.terminate();
							clients.remove(client.addr);
							continue;
						case ConnectionMessage.CONNECT:
							break;
					}
				}
				callback(message, client);
			}
		}
		lock.release();
	}
}