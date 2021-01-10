# Netagram

If you are going to develop a time-critical application, TCP may not suitable for you. Netagram is a UDP based server/client library, allow you to optionally send message reliably or not.

# What kind of application need Netagram?

## 1. PvP game, eg: League of Legends, Overwatch, Left 4 Dead

Nowaday, almost every esport level PvP game are UDP based with a interpolation delay, but design a protocol from plain UDP is a pain.

## 2. Send/receive latest market price when trading

Depends on algorithm, many of them are not nessesary to know every price update, instead, need most update price as soon as possible.

## 3. Any restriction to TCP

If you want to Host the game by one of the player, you need to perform some hole punching TCP are not very well at the moment.

# Who should consider to use Netagram?

## 1. Non-C++ user

Haxe have many major target include C++, if you are experienced C++ developer and your project is fine to fully using C++, there are many library may better than Netagram.
Otherwise you can write your server in Nodejs, Java, C#, C++, python and Haxe, C++, C#, JS, Java in client.

## 2. Small team/one man dev

Write server and client with same logic is a pain, Netagram(Haxe) offer you to write once and transpile to multiple targets.

# Network components

When Netagram using multiple techniques to avoid real world latency, there are many components rather than some raw bytes.

## Message

Message is the most high level network unit in Netagram, most circumstances communicate with Message is enough.

## Payload

Both server and client are sending data in a fix interval, send exact 1 payload for each timeframe

## Fragment

When payload size exceed "MTU size" (This is constant 1024 rather than system MTU), it splits into multiple fragments and send every fragment as a independant packet.

## Block

Let's imagine you have 30 players in the room, they got all update of states already. The 31 player enter the game, this player need got all of players states to initiate the game, size of this states may too large when comparing update payload.
Fragmentation does not solve the problem. Netagram split it into multiple SliceMessage and assemble at peer as Block to avoid UDP flooding.

## SliceMessage

Extends Message, this is reserved Message that will assemble to Block handled by Netagram.

# The example

Example below are not support Windows at current stage.

Build both server and client binaries:

```
haxe build.hxml
```

```
./server/Server-debug
```

launch another terminal/cmd and run:

```
./client/Client-debug
```

This example to show you how to interact with basic netagram connection between server and client. If you can see the debug message "Message is as expected!", you are on the right way!
