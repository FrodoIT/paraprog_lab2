% TDA384 Lab2
% Group 12
% Rasmus Tomasson (rastom), Sofia Larborn (soflarb)

-module(server).
-export([start/1]).

% Start a new server process with the given name
% Do not change the signature of this function.
-record(serverState, {channels=[]}).
-record(channel,{name ="channelname",pid = "ChannelID"}).

start(ServerAtom) ->
	% - Spawn a new process which waits for a message, handles it, then loops infinitely
	% - Register this process to ServerAtom
	% - Return the process ID
	genserver:start(ServerAtom,#serverState{channels=[]},fun handler/2).

% Stop the server process registered to the given name
stop(ServerAtom) ->
	genserver:stop(ServerAtom).

handler(State,Data)->
	case Data of
		{join,ChannelName,NickPid} ->
			%io:fwrite("'join', in server ~n"),
			Channel = lists:keyfind(ChannelName,2,State#serverState.channels),
			if
				%Add channel
				not Channel ->
					%io:fwrite("    added channel~n"),
					NewChannelID = channel:start(NickPid, ChannelName),
					NewChannels = [#channel{name = ChannelName, pid = NewChannelID}| State#serverState.channels],
					NewState = #serverState{channels = NewChannels},
					{reply, {ok, NewChannelID}, NewState};
				%Join existing channel
				true ->
					%io:fwrite("    Channel already exist~n"),
					Channel#channel.pid ! {request, self(), {join, NickPid}},
					receive
						{reply,Result} ->
							{reply, {Result, Channel#channel.pid}, State}
					end
			end
	end.
