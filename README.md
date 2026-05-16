# tcp_rpc
TCP RPC server built with Erlang/OTP.

## Overview
`tcp_rpc` is a simple OTP-based application that allows execution of Erlang expressions over a TCP connection.

## How to run

To build and run the server:
### 1. Compile the project
```bash
  make
```
### 2. Start Erlang shell
```bash
  make shell
```
### 3. Start the application
```erlang
  application:start(tcp_rpc).
```
### 4. Connect via telnet
```bash
  make run_telnet
```
### 5. Execute RPC calls
  In the telnet session, send Erlang expressions, for example:
```erlang
  lists:seq(1, 10).
```
  You will receive the evaluated result.