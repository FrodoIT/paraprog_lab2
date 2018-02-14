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

-record(channel,{
	name, % name of the channel
	pid % process ID for the chanel
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

	%Se if client already joined channel
	Joined = lists:keyfind(Channel,2,St#client_st.channels),
	if
		not Joined ->
			{Result, ChannelID} = genserver:request(St#client_st.server, {join,Channel,self()}),
			NewChannel = #channel{name = Channel, pid = ChannelID},
			NewChannellist = [NewChannel | St#client_st.channels],
			NewState = St#client_st{channels = NewChannellist},
			{reply,Result,NewState};

		true ->
			{reply,{error,user_already_joined,"User already joined"},St}
	end;



% Leave channel
handle(St, {leave, Channel}) ->

	%Se if client joined channel
	Joined = lists:keyfind(Channel,2,St#client_st.channels),
	if
		not Joined ->
			{reply,{error,user_not_joined,"User not joined"},St};
		true ->
			Joined#channel.pid ! {request, self(), {leave, self()}},

			NewState = St#client_st{channels = lists:delete(Joined,St#client_st.channels)},
			{reply, ok, NewState}
	end;


% Sending message (from GUI, to channel)
handle(St, {message_send, Channel, Msg}) ->

	Joined = lists:keyfind(Channel,2,St#client_st.channels),
	if
		not Joined ->
			{reply,{error, user_not_joined,"User not joined"}, St};

		true ->
			list_to_atom(Channel) ! {request, self(), {send_message, Channel, St#client_st.nick, self(), Msg}},
			io:fwrite("Hello"),
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
	io:fwrite("- - - 'handle(St = #client_st{gui = GUI}, {message_receive, Channel, Nick, Msg})' in client ~n"), %TEMPORARY DEBUG PRINT
	gen_server:call(GUI, {message_receive, Channel, Nick++"> "++Msg}),
	{reply, ok, St} ;

% Quit client via GUI
handle(St, quit) ->
	% Any cleanup should happen here, but this is optional
	{reply, ok, St} ;

% Catch-all for any unhandled requests
handle(St, Data) ->
	{reply, {error, not_implemented, "Client does not handle this command"}, St} .
