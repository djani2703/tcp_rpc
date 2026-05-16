%%%-------------------------------------------------------------------
%%% @author djani2703 <djani2703@gmail.com>
%%% @copyright 2026 Erlyer
%%% @doc RPC over TCP server supervisor.
%%% Starts and manages the TCP RPC supervision tree.
%%% @end
%%%-------------------------------------------------------------------

-module(tcp_rpc_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%%%===================================================================
%%% API
%%%===================================================================
%%% @doc Starts the RPC TCP server supervisor.
-spec start_link() -> supervisor:start_link_ret().
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%%===================================================================
%%% supervisor callbacks
%%%===================================================================
init(_Args) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 3,
        period => 1
    },
    Children = [
        #{
            id => tcp_rpc_server,
            start => {tcp_rpc_server, start_link, []},
            restart => permanent,
            shutdown => 2000,
            type => worker,
            modules => [tcp_rpc_server]
        }
    ],
    {ok, {SupFlags, Children}}.
