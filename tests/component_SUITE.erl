%%==============================================================================
%% Copyright 2010 Erlang Solutions Ltd.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%==============================================================================

-module(component_SUITE).
-compile(export_all).

-include_lib("escalus/include/escalus.hrl").
-include_lib("common_test/include/ct.hrl").

%%--------------------------------------------------------------------
%% Suite configuration
%%--------------------------------------------------------------------

all() ->
    [client_to_component].

suite() ->
    escalus:suite().

%%--------------------------------------------------------------------
%% Init & teardown
%%--------------------------------------------------------------------

init_per_suite(Config0) ->
    Config1 = escalus:init_per_suite(Config0),
    escalus:create_users(Config1, {by_name, [alice, bob]}).

end_per_suite(Config) ->
    escalus:delete_users(Config, {by_name, [alice, bob]}),
    escalus:end_per_suite(Config).

init_per_group(_GroupName, Config) ->
    Config.

end_per_group(_GroupName, _Config) ->
    ok.

init_per_testcase(CaseName, Config) ->
    escalus:init_per_testcase(CaseName, Config).

end_per_testcase(CaseName, Config) ->
    escalus:end_per_testcase(CaseName, Config).

%%--------------------------------------------------------------------
%% Tests
%%--------------------------------------------------------------------

client_to_component(Config) ->
    Options = [{port, 8888}, {server, <<"localhost">>},
               {from, <<"component.localhost">>},
               {bind_hostname, <<"component1.localhost">>}],
    {ok, Component} = escalus_client:start_component(Config, Options),
    {ok, Alice} = escalus_client:start(Config, alice, <<"res1">>),
    escalus_client:send(Alice, escalus_stanza:chat_to(Component, <<"Hi!">>)),
    escalus_assert:is_chat_message(
      <<"Hi!">>, escalus_client:wait_for_stanza(Component)),
    [escalus_client:stop(C) || C <- [Component, Alice]].
    
