package com.gigateam.netagram;
import haxe.io.Bytes;

/**
 * ...
 * @author Tiger
 */
class PayloadData 
{
	public var flag:Int;
	public var raw:Bytes;
	public function new(bytes:Bytes, flag:Int) 
	{
		this.flag = flag;
		raw = bytes;
	}
}