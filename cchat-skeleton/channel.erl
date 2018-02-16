% TDA384 Lab2
% Group 12
% Rasmus Tomasson (rastom), Sofia Larborn (soflarb)

-module(channel).
-export([start/2]).

-record(channel,{members=[]}).

%Create a channel
start(FirstMemberPid, Name) ->
	Pid = spawn(fun() -> loop(#channel{members = [FirstMemberPid]}) end),
	catch(unregister(Name)),
	register(list_to_atom(Name), Pid),
	Pid.

loop(State)->
	receive
		{request, From, Data} ->
			catch case (operation(State, Data)) of
							{reply, Reply, NewState}->
								From ! {reply, Reply},
								loop(NewState)
						end
	end.

operation(State, Data)->
	case Data of
		{join,Pid} ->
			%Do the joining
			join_channel(Pid, State);
		{send_message, Channel, Nick, FromPid, Msg}->
			%Do messaging
			Receivers = lists:delete(FromPid,State#channel.members),
			spawn(fun() -> lists:foreach(
				fun (ToPid) ->
					spawn(fun () -> genserver:request(ToPid,{message_receive, Channel, Nick ,Msg}) end)
				end,
				Receivers
			)end),
			{reply, ok, State};
		{leave,ClientPid}->
			%Do leaving
			leave_channel(ClientPid,State)
	end.

leave_channel(ClientPid, State)->
	NewMembers = lists:delete(ClientPid,State#channel.members),
	NewState = State#channel{members = NewMembers},
	{reply, ok, NewState}.

join_channel(NickPid, State)->
	NewMembers = [NickPid | State#channel.members],
	NewState = State#channel{members = NewMembers},
	{reply,ok, NewState}.


