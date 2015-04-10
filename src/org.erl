-module(org).

-author('elbrujohalcon@inaka.net').

-behaviour(application).

-export([ start/0
        , stop/0
        , start/2
        , stop/1
        ]).

-spec start() -> {ok, _} | {error, term()}.
start() -> application:ensure_all_started(org).

-spec stop() -> ok | {error, term()}.
stop() -> application:stop(org).

-spec start(atom(), any()) -> {ok, pid()} | {error, term()}.
start(normal, _Args) ->
  lager:alert("Application ~p starting", [?MODULE]),
  {ok, self()}.

-spec stop(atom()) -> ok.
stop(_State) ->
  lager:alert("Application ~p stopping", [?MODULE]),
  ok.
