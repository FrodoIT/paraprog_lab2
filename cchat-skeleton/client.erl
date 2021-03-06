% TDA384 Lab2
% Group 12
% Rasmus Tomasson (rastom), Sofia Larborn (soflarb)

-module(client).
-export([handle/2, initial_state/3]).

% This record defines the structure of the state of a client.
% Add whatever other fields you need.
-record(client_st, {
	gui, % atom of the GUI process
	nick, % nick/username of the client
	server, % atom of the chat server
	channels % the channels this client is a member of
}).

% Return an initial state record. This is called from GUI.
% Do not change the signature of this function.
initial_state(Nick, GUIAtom, ServerAtom) ->
	#client_st{
		gui = GUIAtom,
		nick = Nick,
		server = ServerAtom,
		channels = []
	}.

% handle/2 handles each kind of request from GUI
% Parameters:
%   - the current state of the client (St)
%   - request data from GUI
% Must return a tuple {reply, Data, NewState}, where:
%   - Data is what is sent to GUI, either the atom `ok` or a tuple {error, Atom, "Error message"}
%   - NewState is the updated state of the client

% Join channel
handle(St, {join, Channel}) ->

	%See if client already joined channel. 
	Joined = lists:member(Channel,St#client_st.channels),
	if
		not Joined ->
			NewState = St#client_st{channels = [Channel|St#client_st.channels]},
			try genserver:request(St#client_st.server, {join,Channel,self()}) of
				ok ->
					{reply,ok,NewState}
			catch
				_:_ ->
					{reply,{error,server_not_reached, "server not reached"},St}
			end;
		true ->
			{reply,{error,user_already_joined,"User already joined"},St}
	end;

% Leave channel
handle(St, {leave, Channel}) ->

	%Se if client joined channel
	Joined = lists:member(Channel,St#client_st.channels),
	if
		not Joined ->
			{reply,{error,user_not_joined,"User not joined"},St};
		true ->
			genserver:request(list_to_atom(Channel), {leave,self()}),
			NewState = St#client_st{channels = lists:delete(Channel,St#client_st.channels)},
			{reply, ok, NewState}
	end;

% Sending message (from GUI, to channel)
handle(St, {message_send, Channel, Msg}) ->

	Joined = lists:member(Channel,St#client_st.channels),
	if
		not Joined ->
			{reply,{error, user_not_joined,"User not joined"}, St};

		true ->
			genserver:request(list_to_atom(Channel), {send_message, Channel, St#client_st.nick, self(), Msg}),
			{reply, ok, St}
	end;

% ---------------------------------------------------------------------------
% The cases below do not need to be changed...
% But you should understand how they work!

% Get current nick
handle(St, whoami) ->
	{reply, St#client_st.nick, St} ;

% Change nick (no check, local only)
handle(St, {nick, NewNick}) ->
	{reply, ok, St#client_st{nick = NewNick}} ;

% Incoming message (from channel, to GUI)
handle(St = #client_st{gui = GUI}, {message_receive, Channel, Nick, Msg}) ->
	gen_server:call(GUI, {message_receive, Channel, Nick++"> "++Msg}),
	{reply, ok, St} ;

% Quit client via GUI
handle(St, quit) ->
	% Any cleanup should happen here, but this is optional
	{reply, ok, St} ;

% Catch-all for any unhandled requests
handle(St, Data) ->
	{reply, {error, not_implemented, "Client does not handle this command"}, St} .
