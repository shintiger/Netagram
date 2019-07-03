package com.gigateam.netagram;

/**
 * ...
 * @author 
 */
class MessageRegistry 
{
	private var messages:Array<Message>;
	private static var instance:MessageRegistry;
	public function new() 
	{
		if (instance != null){
			throw "MessageRegistry is a Singleton.";
		}
		messages = [];
		
		//System reserved
		register(new SliceMessage());
		register(new BytesMessage());
		register(new ConnectionMessage(0));
	}
	public static function getInstance():MessageRegistry{
		if (instance == null){
			instance = new MessageRegistry();
		}
		return instance;
	}
	public function register(message:Message):Void{
		if (messageTypeExists(message.type)){
			var className:String = Type.getClassName(Type.getClass(createMessage(message.type)));
			throw "Duplicate message type. Previous Class is "+className;
		}
		
		messages.push(message);
	}
	public function createMessage(messageType:Int):Message{
		//trace("createMessage", messageType);
		for (m in messages){
			if (m.type == messageType){
				return Type.createInstance(Type.getClass(m), []);
			}
		}
		return null;
	}
	public function messageTypeExists(messageType:Int):Bool{
		for (m in messages){
			if (m.type == messageType){
				return true;
			}
		}
		return false;
	}
}