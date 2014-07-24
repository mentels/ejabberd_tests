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
    [client_to_component,
     component_to_component,
     multiple_bind,
     late_multiple_bind,
     component_unbind].

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
               {bind_hostname, [H = <<"component1.localhost">>]}],
    {ok, Component} = escalus_client:start_component(Config, Options),
    {ok, Alice} = escalus_client:start(Config, alice, <<"res1">>),
    escalus_client:send(Alice, escalus_stanza:chat_to(H, <<"Hi!">>)),
    escalus_assert:is_chat_message(
      <<"Hi!">>, escalus_client:wait_for_stanza(Component)),
    [escalus_client:stop(C) || C <- [Component, Alice]].

component_to_component(Config) ->
    Options1 = [{port, 8888}, {server, <<"localhost">>},
               {from, <<"component1.localhost">>},
               {bind_hostname, [H1 = <<"component1.localhost">>]}],
    {ok, Component1} = escalus_client:start_component(Config, Options1),
    Options2 = [{port, 8888}, {server, <<"localhost">>},
                {from, <<"component2.localhost">>},
                {bind_hostname, [H2 = <<"component2.localhost">>]}],
    {ok, Component2} = escalus_client:start_component(Config, Options2),
    escalus_client:send(Component1,
                        escalus_stanza:chat(H1, H2,
                                            Msg = <<"Yo!">>)),
    escalus_assert:is_chat_message(
      Msg, escalus_client:wait_for_stanza(Component2)),
    [escalus_client:stop(C) || C <- [Component1, Component2]].
    
multiple_bind(Config) ->
    Hostnames = [<<"x.localhost">>, <<"y.localhost">>],
    Options = [{port, 8888}, {server, <<"localhost">>},
               {from, <<"component.localhost">>},
               {bind_hostname, Hostnames}],
    {ok, Component} = escalus_client:start_component(Config, Options),
    {ok, Alice} = escalus_client:start(Config, alice, <<"res1">>),
    Msgs = [begin
                Msg = <<"Hi from ", H/binary>>,
                escalus_client:send(Alice, escalus_stanza:chat_to(H, Msg)),
                Msg
            end || H <- Hostnames],
    [escalus_assert:is_chat_message(
       M, escalus_client:wait_for_stanza(Component))
     || M <- Msgs],
    [escalus_client:stop(C) || C <- [Component, Alice]].

late_multiple_bind(Config) ->
    Options = [{port, 8888}, {server, <<"localhost">>},
               {from, <<"component.localhost">>},
               {bind_hostname, [H1 = <<"h1.localhost">>]}],
    {ok, Component} = escalus_client:start_component(Config, Options),
    {ok, Alice} = escalus_client:start(Config, alice, <<"res1">>),
    escalus_client:send(Alice, escalus_stanza:chat_to(H1, <<"Hi!">>)),
    escalus_assert:is_chat_message(
      <<"Hi!">>, escalus_client:wait_for_stanza(Component)),
    H2 = <<"h2.localhost">>,
    escalus_client:send(Component, escalus_stanza:component_bind(H2)),
    escalus_client:wait_for_stanza(Component),
    escalus_client:send(Alice, escalus_stanza:chat_to(H2, <<"Hi2!">>)),
    escalus_assert:is_chat_message(
      <<"Hi2!">>, escalus_client:wait_for_stanza(Component)),
    [escalus_client:stop(C) || C <- [Component, Alice]].

component_unbind(Config) ->
    Options = [{port, 8888}, {server, <<"localhost">>},
               {from, <<"component.localhost">>},
               {bind_hostname, [H = <<"component1.localhost">>]}],
    {ok, Component} = escalus_client:start_component(Config, Options),
    {ok, Alice} = escalus_client:start(Config, alice, <<"res1">>),
    escalus_client:send(Alice, escalus_stanza:chat_to(H, <<"Hi!">>)),
    escalus_assert:is_chat_message(
      <<"Hi!">>, escalus_client:wait_for_stanza(Component)),
    escalus_client:send(Component, escalus_stanza:component_unbind(H)),
    escalus:assert(is_iq_result, [],
                   escalus_client:wait_for_stanza(Component)),
    escalus_client:send(Alice, escalus_stanza:chat_to(H, <<"Hi!">>)),
    escalus:assert(is_error, [<<"cancel">>, <<"service-unavailable">>],
                   escalus_client:wait_for_stanza(Alice)),
    [escalus_client:stop(C) || C <- [Component, Alice]].
