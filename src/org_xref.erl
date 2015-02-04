-module(org_xref).

-export([undefined/0, defined/0, run/0, run/1]).

undefined() -> undefined_module:undefined_function().

defined() -> ktn_random:generate().

unused() -> unused_function.


run() ->
  Checks =
    [ undefined_function_calls
    , undefined_functions
    , locals_not_used
    , exports_not_used
    , deprecated_function_calls
    , deprecated_functions
    ],
  run(
    #{  dirs    => ["ebin"]
     ,  checks  => Checks
     }).

run(Config) ->
  #{  dirs    := Dirs
   ,  checks  := Checks
   } = Config,

  {ok, Xref} = xref:start(?MODULE),
  xref:set_default(Xref, [{warnings, true}, {verbose, true}]),

  try
    ok = xref:set_library_path(Xref, code:get_path()),
    lists:foreach(
      fun(Dir) ->
        {ok, _} = xref:add_directory(Xref, Dir)
      end, Dirs),
    [{Check, analyze(Xref, Check)} || Check <- Checks]
  after
    xref:stop(Xref)
  end.

analyze(Xref, Check) ->
  case xref:analyze(Xref, Check) of
    {ok, Result} ->
      filter_xref_results(Check, Result);
    Error -> throw(Error)
  end.

filter_xref_results(XrefCheck, XrefResults) ->
  SearchModules =
    lists:usort(
      lists:map(
        fun ({Mt,_Ft,_At}) -> Mt;
            ({{Ms,_Fs,_As},{_Mt,_Ft,_At}}) -> Ms;
            (_) -> undefined
        end, XrefResults)),

  Ignores =
    lists:flatmap(
      fun(Module) ->
        get_xref_ignorelist(Module, XrefCheck)
      end, SearchModules),

  [Result || Result <- XrefResults
           , not lists:member(parse_xref_result(Result), Ignores)].

parse_xref_result({_, MFAt}) -> MFAt;
parse_xref_result(MFAt) -> MFAt.

%%
%% Ignore behaviour functions, and explicitly marked functions
%%
%% Functions can be ignored by using
%% -ignore_xref([{F, A}, {M, F, A}...]).

get_xref_ignorelist(Mod, XrefCheck) ->
  %% Get ignore_xref attribute and combine them in one list
  Attributes =
    try
      Mod:module_info(attributes)
    catch
      _Class:_Error -> []
    end,

  IgnoreXref = keyall(ignore_xref, Attributes),

  BehaviourCallbacks = get_behaviour_callbacks(XrefCheck, Attributes),

  %% And create a flat {M,F,A} list
  lists:foldl(
    fun({F, A}, Acc) -> [{Mod,F,A} | Acc];
       ({M, F, A}, Acc) -> [{M,F,A} | Acc]
    end, [], lists:flatten([IgnoreXref, BehaviourCallbacks])).

keyall(Key, List) ->
    lists:flatmap(fun({K, L}) when Key =:= K -> L; (_) -> [] end, List).

get_behaviour_callbacks(exports_not_used, Attributes) ->
    [B:behaviour_info(callbacks) || B <- keyall(behaviour, Attributes)];
get_behaviour_callbacks(_XrefCheck, _Attributes) ->
    [].
