package com.gigateam.netagram;

/**
 * @author 
 */
interface ISwitchlessHandler 
{
	function onMessage(message:Message):Void;
	function onConnected():Void;
	function onDisconnected():Void;
}