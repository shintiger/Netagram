package com.gigateam.netagram;

/**
 * @author 
 */
interface IMessageSender 
{
	function sendImportant(message:Message):Int;
	function sendReliable(message:Message):Int;
	function send(message:Message):Int;
}