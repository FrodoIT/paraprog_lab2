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
		{join,Channel,Pid} ->
			io:fwrite("JOINING! ~n"),
			ThisChannel = lists:keyfind(Channel,2,State#serverState.channels),
			if
				not ThisChannel ->
					io:fwrite("added channel~n"),
					Newchannel = #channel{name = Channel,members = [Pid]},
					ThisChannel = Newchannel,
					ChannelsUpdated = [Newchannel | State#serverState.channels],
					NewState = #serverState{channels = ChannelsUpdated};

				true ->
					io:fwrite("Channel already exist~n"),
					Joined = lists:member(Pid,ThisChannel#channel.members),
					NewState = State

			end,

			if
				Joined ->
					io:fwrite("user already joined~n"),
					{reply,{error, user_already_joined, "User already joined"},NewState};
				not Joined ->
					MembersUpdated = [Pid | ThisChannel#channel.members],
					ChannelUpdated = #channel{members = MembersUpdated},
					ChannelsUpdated = lists:delete(ThisChannel,NewState#serverState.channels),
					ChannelsUpdated = [ChannelUpdated | ChannelsUpdated],
					NewState = #serverState{channels = ChannelsUpdated},
					io:fwrite("user joined~n"),
					{reply, ok, NewState}
			end;

		{leave,Channel,Nick} ->
			io:fwrite("LEAVING! ~n"),
			{test,State};
		{message_send, Channel,Nick, Msg} ->
			io:fwrite("WRITING ~n"),
			{test,State};
		_ ->
			io:fwrite("DEBUG: COULD NOT MATCH DATA ~n"),
			{test,State}
	end.









