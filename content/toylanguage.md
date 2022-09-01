+++
title = "Writing a brainf**k interpreter with networking functionality"
slug = "toylanguage"
date = 2022-08-31
description = "Writing a brainfuck interpreter with networking functionality"
+++

I wrote [Toy Language](https://github.com/stefanovazzocell/ToyLanguage/), a [brainf**k](https://en.wikipedia.org/wiki/Brainfuck) interpreter written in Go with [TCP networking](https://github.com/stefanovazzocell/ToyLanguage/#networking) functionality.

<!-- more -->

## The language

I wanted to write a simple interpreter for a while so recently I've taken a look at writing one for an esoteric programming language called Brainfuck.

To give the reader an idea of how this language looks like, let's take a look at an example from Wikipedia:

```
Hello World
++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
```

The language operates with a byte array and a pointer to a value in such array, all operations revolve around manipulating the pointer and the array value at the pointer head.
`<` and `>` allow us to add or subtract 1 from the pointer, `+` and `-` allow adding or subtracting 1 from the byte at the data pointer, `.` and `,` allow us to print the value at the data pointer to StdOut or write from StdIn, and finally `[` and `]` are equivalent to a `while (*ptr) {}` in C.

## Writing a interpreter

To speed up my intepreter, I first wrote a parser that goes over an input file and removes all invalid characters, so we can ignore them while iterating over the code.

Now, with some cleaned up code, I iterate over the instructions and execute them one by one.

I used a series of `if` statements instead of a `switch/case` to decide what instructions to execute since the former is 3x faster in `go 1.19` and, at least in my opinion, is still quite readable.

## Extending the language

### The problem

Adding a TCP networking extension to the language was a bit of a design challenge. I wanted commands not to feel too foreign to the original language while avoiding a custom messaging protocol on top of TCP.

At first I thought of grouping consecutive selectors - for example, to send a 4 byte packet you write `^^^^` but this felt a bit of a cheat where the first few `^` do a different task than the last `^` and doesn't easily allow variable sizes. Similar challenges came to selecting the connection target and more.

### Compromise

To make this work well, I had to compromise.

First, the networking extension needs to keep an internal state that the user code can interact with.

Second, I decided on a pre-set listening address `0.0.0.0` and a pre-set `127.0.0.1` connection target address.

Then, I allow the user to set (`@`) a port value `42000` plus the value at the data pointer, so a single byte can represent a range of ports - and similarly, the timeout is set (`*`) to `0.1` seconds times the value at the data pointer.

Finally, the user can read a byte from the connection with `?` or queue a byte write with `^` or flush the write queue with `;`.

The connection is setup in server mode (listener) when using `?` and in client mode (connect to) when using `;`, but once a connection is setup any subsequent `?` and `;` will interact with it.

Essentially this design allows our brainfuck code to operate like a feature complete TCP client/server while offering a coding experience which still breaks your brain.

### Sample code

[Sample code](https://github.com/stefanovazzocell/ToyLanguage/tree/main/samples) with comments is available in the repo, but two quick examples for networking are:

| Netcat command           | BF + `net` extension  |
|:------------------------:|:---------------------:|
| `nc -k -l 0.0.0.0 42002` | `tl:net -*+++@[>?.<]` |
| `nc 127.0.0.1 42001`     | `tl:net -*++@[>,^;<]` |

## Conclusion

[Try it out](https://github.com/stefanovazzocell/ToyLanguage) for yourself - what are you going to build? a chat app? a simple http server? surprise me!