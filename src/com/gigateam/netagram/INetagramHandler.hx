package com.gigateam.netagram;

/**
 * @author 
 */
interface INetagramHandler 
{
	function onMessage(message:Message):Void;
	function onConnected():Void;
	function onDisconnected():Void;
}