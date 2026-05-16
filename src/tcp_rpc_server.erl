%%%-------------------------------------------------------------------
%%% @author djani2703
%%% @copyright 2026 Erlyer
%%% @doc RPC over TCP server worker.
%%% This module defines a server process that listens for incoming
%%% TCP connections and allows the user to execute RPC commands
%%% via that TCP stream.
%%% @end
%%%-------------------------------------------------------------------

-module(tcp_rpc_server).

-behaviour(gen_server).

%% API
-export([start_link/0, start_link/1, get_count/0, stop/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(DEFAULT_PORT, 1055).
-define(SERVER, ?MODULE).

-record(state, {port, lsock, request_count = 0}).

-type state() :: #state{}.

%%%===================================================================
%%% API
%%%===================================================================
%%% @doc Starts the RPC TCP server on default port.
-spec start_link() -> gen_server:start_ret().
start_link() ->
    start_link(?DEFAULT_PORT).

%%% @doc Starts the RPC TCP server on specified port.
-spec start_link(inet:port_number()) -> gen_server:start_ret().
start_link(Port) ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [Port], []).

%%% @doc Returns number of handler requests.
-spec get_count() -> {ok, non_neg_integer()}.
get_count() ->
    gen_server:call(?SERVER, get_count).

%%% @doc Stop the RPC TCP server.
-spec stop() -> ok.
stop() ->
    gen_server:cast(?SERVER, stop).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
-spec init([term()]) -> {ok, state(), non_neg_integer()} | {stop, term()}.
init([Port]) ->
    case gen_tcp:listen(Port, [{active, true}]) of
        {ok, ListenSocket} ->
            {ok, #state{port = Port, lsock = ListenSocket}, 0};
        {error, Reason} ->
            {stop, Reason}
    end.

-spec handle_call(term(), gen_server:from(), state()) -> {reply, term(), state()}.
handle_call(get_count, _From, State) ->
    {reply, {ok, State#state.request_count}, State}.

-spec handle_cast(term(), state()) -> {stop, normal, state()}.
handle_cast(stop, State) ->
    {stop, normal, State}.

-spec handle_info(term(), state()) -> {noreply, state()}.
handle_info({tcp, Socket, RawData}, #state{request_count = RequestCount} = State) ->
    do_rpc(Socket, RawData),
    {noreply, State#state{request_count = RequestCount + 1}};
handle_info(timeout, #state{lsock = ListenSocket} = State) ->
    {ok, _Socket} = gen_tcp:accept(ListenSocket),
    {noreply, State}.

-spec terminate(term(), state()) -> ok.
terminate(_Reason, _State) ->
    ok.

-spec code_change(term(), state(), term()) -> {ok, state()}.
code_change(_OldVersion, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
-spec do_rpc(port(), string()) -> ok.
do_rpc(Socket, RawData) ->
    try
        {Module, Function, Args} = split_out_mfa(RawData),
        Result = apply(Module, Function, Args),
        gen_tcp:send(Socket, io_lib:fwrite("~p~n", [Result]))
    catch
        _Class:Error ->
            gen_tcp:send(Socket, io_lib:fwrite("~p~n", [Error]))
    end.

-spec split_out_mfa(string()) -> {module(), atom(), [term()]}.
split_out_mfa(RawData) ->
    MFA = re:replace(RawData, "\r\n$", "", [{return, list}]),
    {match, [M, F, A]} =
        re:run(
            MFA,
            "(.*):(.*)\s*\\((.*)\s*\\)\s*.\s*$",
            [{capture, [1, 2, 3], list}, ungreedy]
        ),
    {list_to_atom(M), list_to_atom(F), args_to_terms(A)}.

-spec args_to_terms(string()) -> [term()].
args_to_terms(RawArgs) ->
    {ok, Tokens, _Line} = erl_scan:string("[" ++ RawArgs ++ "]. ", 1),
    {ok, Args} = erl_parse:parse_term(Tokens),
    Args.
