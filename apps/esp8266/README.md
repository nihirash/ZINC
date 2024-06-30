# Tools for ESP8266 with default AT-firmware

It's important setup your UART speed settings to same mode as ESP8266 module via `zinc-setup`.

All tools working via IOBYTE.

## esprst.com - resets your ESP8266 module

Just resets your module and closes all opened connections

## dial.com 

Dialer that allows use your ESP8266 module with usual BBSes and tools like kermit/ZMP etc.

Just run it as:
```shell
zinc dial kayprobbs.org 23
```

Where `kayprobbs.org` is host name and `23` is port(replace with any values that you want).

Connection will be opened with direct streaming mode and every transmitted byte TO uart will be send to socket and every received from socket byte will be send to uart.

Only one issue - if remote host will close connection - it will be re-established automatically, so for closing socket you should call esprst tool: 

```shell
zinc esprst
```

