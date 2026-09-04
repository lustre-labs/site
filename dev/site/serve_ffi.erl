-module(serve_ffi).

-export([reload_modified_modules/0]).

reload_modified_modules() ->
    Modules = code:modified_modules(),
    lists:foreach(fun code:purge/1, Modules),
    case code:atomic_load(Modules) of
        ok -> {ok, nil};
        {error, Errors} ->
            Message = io_lib:format("Could not reload modules: ~p", [Errors]),
            {error, unicode:characters_to_binary(Message)}
    end.
