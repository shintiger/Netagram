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

Haxe have many major target include C++, if you are experienced C++ developer and your project is fine to fully using C++, there are many library better than Netagram.
Otherwise you can write your server in Nodejs, Java, C#, C++, python and Haxe, C++, C#, JS, Java in client.

## 2. Small team/one man dev

Write server and client with same logic is a pain, Netagram(Haxe) offer you to write once and transpile to multiple target.

# The example

run:

```
haxe server.hxml
neko server.n
```

launch another terminal/cmd and run:

```
haxe client.hxml
neko client.n
```

This example to show you how to interact with basic netagram connection between server and client.
