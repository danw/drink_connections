%%%-------------------------------------------------------------------
%%% File    : drink_connections.erl
%%% Author  : Dan Willemsen <dan@csh.rit.edu>
%%% Purpose : 
%%%
%%%
%%% edrink, Copyright (C) 2010 Dan Willemsen
%%%
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License as
%%% published by the Free Software Foundation; either version 2 of the
%%% License, or (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%%% General Public License for more details.
%%%                         
%%% You should have received a copy of the GNU General Public License
%%% along with this program; if not, write to the Free Software
%%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
%%% 02111-1307 USA
%%%
%%%-------------------------------------------------------------------

-module (drink_connections).
-behaviour (gen_server).

-export ([start_link/0]).
-export ([init/1, terminate/2, code_change/3]).
-export ([handle_call/3, handle_cast/2, handle_info/2]).
-export ([register/3, set_user/1, set_app/1]).

-record (state, {}).

start_link () ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init ([]) ->
    {ok, #state{}}.

terminate (_Reason, _State) ->
    ok.

code_change (_OldVsn, State, _Extra) ->
    {ok, State}.

handle_cast (_Request, State) -> {noreply, State}.

handle_call ({register, Pid, Username, Transport, App}, _From, State) ->
    dw_events:send(drink_connections, {connected, Pid, Username, Transport, App}),
    erlang:monitor(process, Pid),
    {reply, ok, State};
handle_call ({set_user, Pid, Username}, _From, State) ->
    dw_events:send(drink_connections, {changed, Pid, user, Username}),
    {reply, ok, State};
handle_call ({set_app, Pid, App}, _From, State) ->
    dw_events:send(drink_connections, {changed, Pid, app, App}),
    {reply, ok, State};
handle_call (_Request, _From, State) -> {noreply, State}.

handle_info ({'DOWN', _Ref, process, Pid, _Info}, State) ->
    dw_events:send(drink_connections, {disconnected, Pid}),
    {noreply, State};
handle_info (_Info, State) -> {noreply, State}.

register(Username, Transport, App) when is_list(Username), is_atom(Transport), is_atom(App) ->
    gen_server:call(?MODULE, {register, self(), Username, Transport, App}).

set_user(Username) when is_list(Username) ->
    gen_server:call(?MODULE, {set_user, self(), Username}).

set_app(App) when is_atom(App) ->
    gen_server:call(?MODULE, {set_app, self(), App}).
