%% Copyright (c) 2013 Robert Virding
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

%% File    : erlog_lib_lists.erl
%% Author  : Robert Virding
%% Purpose : Standard Erlog lists library.
%% 
%% This is a standard lists library for Erlog. Everything here is
%% pretty basic and common to most Prologs. We are experimenting here
%% and some predicates are compiled. We only get a small benefit when
%% only implementing indexing on the first argument.

-module(erlog_lib_mysql_search).

-export([get_from_mysql/3]).

%% Main interface functions.

%% Library functions.
% source, name, prototype


%% load(Database) -> Database.
%%  Assert predicates into the database.
-spec get_from_mysql(atom(), list(), list()) -> fun().
get_from_mysql(Source, Query, Params)->
    Pid = whereis(Source),
    QueryB = list_to_binary(Query),
    {ok, ColumnNames, Rows} = mysql:query(Pid, QueryB, Params),
    Vals = convert_binaries(Rows),  
    %% This fun will return head and itself for continuation.
    Fun = fun (F1, Es0) ->
            case Es0 of
                [E] -> {succeed_last,E};	%Optimisation for last one
                [E|Es] -> {succeed,E,fun () -> F1(F1, Es) end};
                [] -> fail		%No more elements
            end
    end,
    Fun(Fun, Vals). 

convert_binaries(L)->
    lists:map(fun(Elems) ->
                        lists:map(fun(Elem) ->   unicode:characters_to_list(to_bin(Elem)) end, Elems)
              end, L).

         
to_bin(W) when is_atom(W)->
  atom_to_binary(W, latin1);
to_bin(W) when is_binary(W)->
  W;         
to_bin(W) when is_list(W)->
  list_to_binary(W);
to_bin(W) when is_integer(W)->
  to_bin(integer_to_list(W)).  


