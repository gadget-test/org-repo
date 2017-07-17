-module(org_warning).

-export([warning/1, my_fun/1]).

warning(Something) -> unused.

my_fun(X) ->
  [X || is_list(X), length(X) > 0].
