playerslistteams = {}

function tablefind(tab, el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end

    return nil
end

function removeplayer(player)
    local index = tablefind(playerslistteams, player)
    if index ~= nil then
        table.remove(playerslistteams, index)
    end
end

function player_connected(player)
    
    player.time_in_game = game:gettime()

    player:onnotifyonce("disconnect", function()
        removeplayer(player)
    end)
    table.insert(playerslistteams, player)
end

function balanceteams()
    local functions = game:scriptcall("maps/mp/gametypes/_teams", "_id_410A")
    if(functions == 0) then
        balance()		
    end
end


function balance()
    alliedplayers = {}
    axisplayers = {}
    printboltallplayer()
    for i = 1, #playerslistteams do
        if game:isdefined(playerslistteams[i].time_in_game) == 0 then
            goto continue
        end
        
        if((game:isdefined(playerslistteams[i].pers["team"]) == 1) and (playerslistteams[i].pers["team"] == "allies")) then
            table.insert(alliedplayers, playerslistteams[i])
		elseif((game:isdefined(playerslistteams[i].pers["team"]) == 1) and (playerslistteams[i].pers["team"] == "axis")) then
            table.insert(axisplayers, playerslistteams[i])
        end
        
        ::continue::
    end

    mostrecent = nil

    while((#alliedplayers > (#axisplayers + 1)) or (#axisplayers > #alliedplayers + 1))
    do
        if(#alliedplayers > (#axisplayers + 1)) then
		
			-- Move the player that's been on the team the shortest ammount of time (highest kills value)
			for j = 1, #alliedplayers do
			
				if(game:isdefined(alliedplayers[j].dont_auto_balance) == 1) then
                    goto continue_2
                end
                if(mostrecent == nil) then
					mostrecent = alliedplayers[j]
				elseif(alliedplayers[j].time_in_game > mostrecent.time_in_game) and (alliedplayers[j].sessionteam ~= "spectator") then
					mostrecent = alliedplayers[j]
                end
                ::continue_2::
            end

			mostrecent:changeteam("axis");
		end
        if(#axisplayers > (#alliedplayers + 1)) then
		
			-- Move the player that's been on the team the shortest ammount of time (highest kills value)
			for k = 1,  #axisplayers do
			
				if(game:isdefined(axisplayers[k].dont_auto_balance) == 1) then
                    goto continue_1
                end
				if(mostrecent == nil) then
					mostrecent = axisplayers[k]
				elseif(axisplayers[k].time_in_game > mostrecent.time_in_game) and (axisplayers[k].sessionteam ~= "spectator") then
					mostrecent = axisplayers[k]
                end
                ::continue_1::
            end

			mostrecent:changeteam("allies");
		end

        mostrecent = nil;
		alliedplayers = {}
        axisplayers = {}

        for i = 1, #playerslistteams do              
            if((game:isdefined(playerslistteams[i].pers["team"]) == 1) and (playerslistteams[i].pers["team"] == "allies")) then
                table.insert(alliedplayers, playerslistteams[i])
            elseif((game:isdefined(playerslistteams[i].pers["team"]) == 1) and (playerslistteams[i].pers["team"] == "axis")) then
                table.insert(axisplayers, playerslistteams[i])
            end         
            
        end
    end
end

function entity:changeteam( team )
    if self.sessionstate ~= "dead" then
        self.switching_teams = true;
        self.joining_team = team;
        self.leaving_team = self.pers["team"];
        game:ontimeout(function ()
            self:suicide()
        end, 0)
    end

    self.pers["team"] = team;
    self.team = team;
    --self.pers["kills"] = nil;
    self.sessionteam = self.pers["team"];
    self:scriptcall("maps/mp/_utility", "_id_9B42")
    
    self:notify( "end_respawn" );
end

if game:getdvar("gamemode") == "mp" then    
    level:onnotifyonce("matchStartTimer", function() game:ontimeout(updateTeamBalance, 0) end)
    level:onnotify("connected", player_connected)
end

function printboltallplayer()
    for i = 1, #playerslistteams do
        playerslistteams[i]:clientiprintlnbold("Balanced teams!")
    end
end

function updateTeamBalance()

    local isroundbased = game:scriptcall("maps/mp/_utility", "_id_5194")

    if ( level.teambalance  == 1 and isroundbased == 1 ) then
    	level:onnotify("restarting", balanceteams)
	else
		monitorbalance = game:oninterval(balanceteams, 60000)
        monitorbalance:endon(level, "game_ended") -- timelimit or scorelimit is reached
    end
end
