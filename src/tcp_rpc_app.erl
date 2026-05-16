%%%-------------------------------------------------------------------
%%% @author djani2703
%%% @copyright 2026 Erlyer
%%% @doc
%%% TCP RPC application entry point.
%%% Starts and stops the supervision tree for the TCP RPC server.
%%% @end
%%%-------------------------------------------------------------------

-module(tcp_rpc_app).

-behaviour(application).

-export([start/2, stop/1]).

-spec start(application:start_type(), term()) ->
    {ok, pid()} | {error, term()}.
start(_Type, _Args) ->
    tcp_rpc_sup:start_link().

-spec stop(term()) -> ok.
stop(_State) ->
    ok.
