package com.gigateam.netagram;
import com.gigateam.util.BytesStream;
import com.gigateam.util.NetworkTool;
import haxe.io.Bytes;
import hx.concurrent.executor.Executor;
import sys.net.Address;
import sys.net.Host;
import sys.net.UdpSocket;

/**
 * ...
 * @author Tiger
 */
class Netagram extends DuplexStream
{
	public static inline var REQUEST_HEADER:Int = 0xf0ff0f00;
	public static inline var REQUEST_COMMAND:String = "1234567812345678123456781234567812345678123456781234567812345678";
	
	private var _startConnecting:Float;
	
	private var _lastConnecting:Float;
	private var _connected:Bool = false;
	private var _connectionToken:String = "";
	private var _host:Host;
	private var _target:Address;
	private var _hostInt:Int;
	private var _impl:UdpSocket;
	private var _port:Int;
	private var _messagesPending:Bool = false;
	
	private var executor1:Executor;
	private var executor2:Executor;
	
	public var receiveDiff:Float = 0;
	public var ignoreDifferentAddress:Bool = false;
	
	public var onMessage:Message->Void;
	public var onConnected:Void->Void;
	public var onDisconnected:Void->Void;
	public var handler:ISwitchlessHandler;
	public var mannualHandleMessage:Bool = true;
	public function new(host:Host, port:Int, factory:MessageFactory) 
	{
		_impl = new UdpSocket();
		_host = host;
		_impl.bind(new Host("0.0.0.0"), 0);
		_target = NetworkTool.stringToAddress(host.host);
		_target.port = port;
		super(65536, _target, _impl);
		allocate(factory, 65536);
		//_target.host = 
	}
	public static function fromString(host:String, port:Int, factory:MessageFactory):Netagram{
		var switchless:Netagram = new Netagram(new Host(host), port, factory);
		return switchless;
	}
	public function start():Void{
		//_callback = callback;
		executor1 = Executor.create(1);
		executor2 = Executor.create(1);
		executor1.submit(read, FIXED_RATE(1));
		executor2.submit(update, FIXED_RATE(50)); 
		
		var message:ConnectionMessage = new ConnectionMessage(ConnectionMessage.CONNECT);
		message.onAcknowledged = function():Void{
			_connected = true;
			if (onConnected != null){
				onConnected();
			}else{
				handler.onConnected();
			}
		};
		_startConnecting = Sys.time();
		sendReliable(message);
	}
	private function update():Void{
		var time:Float = Sys.time();
		if (!_connected){
			var diff:Float = time-_lastConnecting;
			if (diff > 0.9){
				if ((time - _startConnecting) > DuplexStream.DEFAULT_TIMEOUT){
					// Connection timedout
					trace("Timedout! disconnect");
					send(new ConnectionMessage(ConnectionMessage.DISCONNECT));
			
					stop();
					return;
				}
				_lastConnecting = time;
				var bytes:Bytes = Bytes.alloc(1024);
				var stream:BytesStream = new BytesStream(bytes, 0);
				var pointer:BytesPointer;
				stream.writeInt32(REQUEST_HEADER);
				if (_connectionToken == ""){
					trace("token requesting");
					stream.writeUTF(REQUEST_COMMAND);
					stream.writeDouble(sentBaseTime);
					pointer = BytesPointer.create(bytes, 0, stream.offset());
				}else{
					trace("answering token");
					stream.writeUTF(_connectionToken);
					pointer = BytesPointer.create(bytes, 0, stream.offset());
				}
				rawSend(_impl, pointer);
			}
		}
		receiveDiff = time-lastReceived;
		if (lastReceived > 0 && receiveDiff > DuplexStream.DEFAULT_TIMEOUT){
			trace("Timedout! disconnect");
			send(new ConnectionMessage(ConnectionMessage.DISCONNECT));
			
			stop();
		}
		flush(_impl, time);
	}
	private function stop():Void{
		if (onDisconnected != null){
			onDisconnected();
		}else if (handler != null){
			handler.onDisconnected();
		}
		terminate();
		executor1.stop();
		executor2.stop();
	}
	private function read():Void{
		_impl.waitForRead();
		var buf:Bytes = Bytes.alloc(4096);
		var addr:Address = new Address();
		var read:Int = _impl.readFrom(buf, 0, buf.length, addr);
		
		if (read < 0){
			// EOF character indicate termination from remote
			return;
		}
		
		if (ignoreDifferentAddress && addr.compare(_target) != 0){
			trace("Unknown packet, ignore");
			return;
		}
		append(buf, read);
		if (read < buf.length){
			if(!mannualHandleMessage){
				handleMessages();
			}else{
				_messagesPending = true;
			}
			//if (!_connected && messages.length == 0){
			if (!_connected){
				var stream:BytesStream = new BytesStream(buf, 0);
				_connectionToken = stream.readUTF();
				if (_connectionToken.length != 64){
					_connectionToken = "";
					return;
				}
				setReceiveBaseTime(stream.readDouble());
				_lastConnecting = 0;
			}
			//var payload:PayloadData = new PayloadData(buf, 0);
			//_callback(payload);
		}
	}
	
	public function handleMessages():Void{
		if (!_messagesPending){
			return;
		}
		_messagesPending = false;
		var messages:Array<Message> = fetchMessage();
		for (message in messages){
			if (Std.is(message, ConnectionMessage)){
				var connectionMessage:ConnectionMessage = cast message;
				if (connectionMessage.action == ConnectionMessage.DISCONNECT){
					trace("Disconnect from server");
					stop();
					return;
				}
			}
			if(onMessage!=null){
				onMessage(message);
			}else{
				handler.onMessage(message);
			}
		}
	}
	
	public function sendBytes(bytes:Bytes, time:Float):Int{
		//return sendTo(_impl, bytes, bytes.length, time);
		//return _impl.sendTo(bytes, 0, bytes.length, _target);
		return 0;
	}
}