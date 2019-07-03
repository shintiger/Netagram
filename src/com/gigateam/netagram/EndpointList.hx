package com.gigateam.netagram;
import sys.net.Address;

/**
 * ...
 * @author Tiger
 */
class EndpointList 
{
	private var clients:Array<SwitchlessEndpoint> = [];
	private var map:Map<Int, Map<Int, SwitchlessEndpoint>> = new Map();
	public function new(){
		
	}
	public function exists(addr:Address):Bool{
		if (map.exists(addr.host)){
			var ports:Map<Int, SwitchlessEndpoint> = map.get(addr.host);
			if (ports.exists(addr.port)){
				return true;
			}
		}
		return false;
	}
	public function get(addr:Address):SwitchlessEndpoint{
		return map.get(addr.host).get(addr.port);
	}
	public function set(addr:Address, client:SwitchlessEndpoint):Void{
		var ports:Map<Int, SwitchlessEndpoint>;
		var index:Int = clients.indexOf(client);
		if (index < 0){
			clients.push(client);
		}
		if (map.exists(addr.host)){
			ports = map.get(addr.host);
			if (ports.exists(addr.port)){
				trace("already exists");
			}
			ports.set(addr.port, client);
		}else{
			ports = new Map();
			ports.set(addr.port, client);
			map.set(addr.host, ports);
		}
	}
	public function remove(addr:Address):Void{
		if (!exists(addr)){
			trace("client not exists", addr);
			return;
		}
		var client:SwitchlessEndpoint = get(addr);
		var ports:Map<Int, SwitchlessEndpoint> = map.get(addr.host);
		ports.remove(addr.port);
		var remove:Bool = true;
		for (port in ports.keys()){
			remove = false;
			break;
		}
		
		if (remove){
			map.remove(addr.host);
		}
		var index:Int = clients.indexOf(client);
		if (index < 0){
			trace("cannot find client", index);
			return;
		}
		clients.splice(index, 1);
		trace("Removed");
	}
	public function getClients():Array<SwitchlessEndpoint>{
		return clients;
	}
	public function numClients():Int{
		return clients.length;
	}
}