-module(server).
-export([start/1,stop/1]).

% Start a new server process with the given name
% Do not change the signature of this function.
-record(serverState, {channels=[]}).
-record(channel,{name ="channelname",members=[]}).


start(ServerAtom) ->
	% TODO Implement function
	% - Spawn a new process which waits for a message, handles it, then loops infinitely
	genserver:start(ServerAtom,#serverState{channels=[]},fun handler/2).
% - Register this process to ServerAtom

% - Return the process ID



% Stop the server process registered to the given name,
% together with any other associated processes
stop(ServerAtom) ->
	% TODO Implement function
	ServerAtom ! stop,
	% Return ok
	ok.

handler(State,Data)->

	case Data of
		{join,ChannelName,Pid} ->
			io:fwrite("'join', in server ~n"),
			Channel = lists:keyfind(ChannelName,2,State#serverState.channels),
			if
				not Channel ->
					io:fwrite("    added channel~n"),
					NewChannel = #channel{name = ChannelName,members = [Pid]},
					Channels = State#serverState.channels,
					NewState = #serverState{channels = [NewChannel|Channels]},
					{reply, ok, NewState};
				true ->

					io:fwrite("    Channel already exist~n"),
					Joined = lists:member(Pid,Channel#channel.members),
					if
						Joined ->
							io:fwrite("    user already joined~n"),
							NewState = State,
							{reply,{error, user_already_joined, "User already joined"},NewState};
						not Joined ->
							io:fwrite("    user joined~n"),
							UpdatedMembers = [Pid|Channel#channel.members],
							UpdatedChannel = #channel{name = ChannelName,members = UpdatedMembers},
							UpdatedChannels = [UpdatedChannel | lists:delete(Channel,State#serverState.channels)],
							NewState = #serverState{channels = UpdatedChannels},
							{reply, ok, NewState}
					end
			end;

		{leave,ChannelName,Pid} ->
			io:fwrite("'leave', in server ~n"),
			Channel = lists:keyfind(ChannelName,2,State#serverState.channels),
			if
				not Channel ->
					io:fwrite("    user not joined~n"),
					{reply,{error,user_not_joined,"User not joined"},State};
				true ->
					io:fwrite("    User left~n"),
					UpdatedMembers = lists:delete(Pid,Channel#channel.members),
					UpdatedChannel = #channel{name = ChannelName,members = UpdatedMembers},
					UpdatedChannels = [UpdatedChannel | lists:delete(Channel,State#serverState.channels)],
					NewState = #serverState{channels = UpdatedChannels},
					{reply,ok,NewState}
			end;

		{message_send, ChannelName,Pid, Msg,Nick} ->
			io:fwrite("'message_send', in server ~n"),
			Channel = lists:keyfind(ChannelName,2,State#serverState.channels),
			Joined = lists:member(Pid,Channel#channel.members),
			if
				Joined ->
					Members = Channel#channel.members,
					send_message(Members,{Msg, Nick},Channel,State),
					{reply,ok,State};

				not Joined ->
					io:fwrite("    can't write in channel not joined~n"),
					{reply,{error,user_not_joined,"    User not joined~n"},State}
			end
	end.

send_message([H|T],{Msg, Nick},Channel,State) ->
io:fwrite("- - - 'send_message([H|T],{Msg, Nick},Channel,State)' in server ~n"),
%	H ! {State,{message_receive, Channel, Nick, Msg}},
	genserver:request(H, {State,{message_receive, Channel, Nick ,Msg}}),
	io:fwrite("    To: ~p(~p). send_message <<~p>> in server. channel: ~p~n", [Nick,H,Msg,Channel]),
	send_message(T,{Msg, Nick},Channel,State);

	send_message([],_,_,_) ->
		ok.
