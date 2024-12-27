--// [[ DEPENDENCIES ]] \\--
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// [[ VARIABLES ]] \\--

--// UI
local Toggles = {
    AutoDeploy = false,
    SelfFarm = false,
    AutoBreakBoxes = false,

    KillBricks = false,

    Killaura = false,
    Instakill = false
}
local Sliders = {
    WalkSpeed = 30,
    JumpPower = 50
}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// LocalPlayer
local Client = Players.LocalPlayer
local Character = Client.Character
local Humanoid = if Character then
    Character:FindFirstChild("Humanoid")
else
    nil

--// Misc
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

--// [[ INTERNAL ]] \\--

local function GetCurrentWeaponName()
    return Remotes:WaitForChild("GetCurrentWeapon"):InvokeServer()
end

local function GetCurrentWeaponObject()
    local CurrentWeapon = GetCurrentWeaponName()

    if Character and Character:FindFirstChild(CurrentWeapon) then
        return Character:FindFirstChild(CurrentWeapon)
    end

    if Client.Backpack:FindFirstChild(CurrentWeapon) then
        return Client.Backpack:FindFirstChild(CurrentWeapon)
    end

    return false
end

local function IsPlayerSpawn(Player : Player)
    if Player.Character and Player.Character:FindFirstChild("Spawned") then
        return Player.Character.Spawned.Value
    else
        return false
    end
end

--// [[ CONNECTIONS ]] \\--

Client.CharacterAdded:Connect(function(NewCharacter)
    Character = NewCharacter
    Humanoid = NewCharacter:WaitForChild("Humanoid")

    Humanoid.UseJumpPower = true
    Humanoid.WalkSpeed = Sliders.WalkSpeed
    Humanoid.JumpPower = Sliders.JumpPower

    Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        Humanoid.WalkSpeed = Sliders.WalkSpeed
        Humanoid.JumpPower = Sliders.JumpPower
    end)

    if Toggles.AutoDeploy == true then
        task.wait(0.1)
        local Head = NewCharacter:WaitForChild("Head")
        local SpawnPart = workspace.Shop:FindFirstChild("TouchInterest", true).Parent

        firetouchinterest(Head, SpawnPart, 0)
        task.wait(0.1)
        firetouchinterest(Head, SpawnPart, 1)
    end

    if Toggles.SelfFarm == true then
        local OldValue = Toggles.Instakill
        Toggles.Instakill = true;
        task.wait(0.1)
        local Head = NewCharacter:WaitForChild("Head")
        local SpawnPart = workspace.Shop:FindFirstChild("TouchInterest", true).Parent
        
        firetouchinterest(Head, SpawnPart, 0)
        task.wait(0.1)
        firetouchinterest(Head, SpawnPart, 1)
        
        for i=1, 50 do
            pcall(function()
                GetCurrentWeaponObject().Events.Hit:FireServer(Humanoid)
            end)
        end
        Toggles.Instakill = OldValue
    end
end)

--// [[ INIT ]] \\--

if Humanoid then 
    Humanoid.UseJumpPower = true 
    Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        Humanoid.JumpPower = Sliders.JumpPower
        Humanoid.WalkSpeed = Sliders.WalkSpeed
    end)
end

--// [[ HOOKS ]] \\--
local ClientName = Client.Name

local OldIndex; OldIndex = hookmetamethod(game, "__index", newcclosure(function(Self, Key, ...)
    if Key == "HumanoidRootPart" and Self == nil then
        return workspace:WaitForChild(ClientName):WaitForChild("HumanoidRootPart")
    end
    return OldIndex(Self, Key, ...)
end))

local OldNamecall; OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(Self, ...)
    if getnamecallmethod() == "FireServer" and Self.Name == "Hit" and Toggles.Instakill == true then
        for i=1, 25 do
            OldNamecall(Self, ...)
        end
    end

    return OldNamecall(Self, ...)
end))

--// [[ TOGGLES ]] \\--

local function ToggleAutodeploy(NewValue : boolean)
    Toggles.AutoDeploy = NewValue
end

local function SelfFarm(NewValue : boolean)
    Toggles.SelfFarm = NewValue

    if IsPlayerSpawn(Client) then
        for i=1, 50 do
            GetCurrentWeaponObject().Events.Hit:FireServer(Humanoid)
        end
    else
        local Head = Character:WaitForChild("Head")
        local SpawnPart = workspace.Shop:FindFirstChild("TouchInterest", true).Parent
        
        firetouchinterest(Head, SpawnPart, 0)
        task.wait(0.1)
        firetouchinterest(Head, SpawnPart, 1)

        for i=1, 50 do
            pcall(function()
                GetCurrentWeaponObject().Events.Hit:FireServer(Humanoid)
            end)
        end
    end
end

local function AutoBreakBoxes(NewValue : boolean)
    if NewValue == false then return end

    for _,BoxPostion in workspace.BoxPositions:GetChildren() do
        if #BoxPostion:GetChildren() > 0 then
            Remotes:WaitForChild("BoxEvent"):FireServer(BoxPostion:GetChildren()[1])
        end
    end

    local Connection; Connection = workspace.BoxPositions.DescendantAdded:Connect(function(Box)
        if Toggles.AutoBreakBoxes.CurrentValue == false then Connection:Disconnect() end

        Remotes:WaitForChild("BoxEvent"):FireServer(Box)
    end)
end

local function ToggleKillaura(NewValue : boolean)
    while Toggles.Killaura.CurrentValue == true do
        for _,Player in Players:GetPlayers() do
            if  Player ~= Client 
            and Player.Character 
            and Player.Character:FindFirstChild("Humanoid")
            and Player.Character:FindFirstChild("HumanoidRootPart") 
            and Player.Character.Humanoid.Health > 0
            and Humanoid
            and Humanoid.Health > 0 then
                local Distance = Client:DistanceFromCharacter(Player.Character:FindFirstChild("HumanoidRootPart").Position)
                
                if Distance <= 100 and GetCurrentWeaponObject() ~= false then
                    pcall(function()
                        GetCurrentWeaponObject().Events.Hit:FireServer(Player.Character.Humanoid)
                    end)
                end
            end
        end
        task.wait()
    end
end

local function ToggleInstakill(NewValue : boolean)
    Toggles.Instakill = NewValue
    print(Toggles.Instakill)
end

local function ToggleKillbricks(NewValue : boolean)
    for _,Object in workspace.Map:GetDescendants() do
        if Object.ClassName == "TouchTransmitter" then
            pcall(function() 
                Object.Parent.CanCollide = not NewValue 
                Object.Parent.CanTouch = NewValue
            end)
        end
    end
end

--// [[ BUTTONS ]] \\--

local function TeleportToMap()
    if Humanoid and Humanoid.Health > 0 then
        Character.HumanoidRootPart.Position = Vector3.new(-134.2, 28, 600.5)
    end
end

local function TeleportToSpawn()
    if Humanoid and Humanoid.Health > 0 then
        Character.HumanoidRootPart.Position = Vector3.new(-119, -80, -641.5)
    end
end

--// [[ SLIDERS ]] \\--

local function UpdateGravity(NewValue : number)
    workspace.Gravity = NewValue
end

local function UpdateWalkspeed(NewValue : number)
    Humanoid.WalkSpeed = NewValue
    Sliders.WalkSpeed = NewValue
end

local function UpdateJumpPower(NewValue : number)
    Humanoid.JumpPower = NewValue
    Sliders.JumpPower = NewValue
end

--// [[ UI ]] \\--
local Window = Rayfield:CreateWindow({
    Name = "Blink",
    Icon = "eye",

    LoadingTitle = "Blink",
    LoadingSubtitle = "bypassed in a blink",

    Theme = "Amethyst",

    DisableBuildWarnings = true,

    Discord = {
        Enabled = true,
        Invite = "https://discord.gg/g9a5besaD6",
        RememberJoins = true
    },

    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil, -- Create a custom folder for your hub/game
        FileName = "Blink"
     }
})

local GrindTab = Window:CreateTab("Grind", "gamepad-2")
GrindTab:CreateSection("Game")

GrindTab:CreateToggle({
    Name = "AutoDeploy",
    CurrentValue = false,
    Flag = "AutoDeploy",
    Callback = ToggleAutodeploy
})

GrindTab:CreateToggle({
    Name = "Farm Yourself",
    CurrentValue = false,
    Flag = "SelfFarm",
    Callback = SelfFarm;
})

GrindTab:CreateSection("Boxes")

Toggles.AutoBreakBoxes = GrindTab:CreateToggle({
    Name = "Autobreak Boxes",
    CurrentValue = false,
    Flag = "AutobreakBoxes",
    Callback = AutoBreakBoxes
})

--//

local CombatTab = Window:CreateTab("Combat", "sword")
CombatTab:CreateSection("Attack")

Toggles.Killaura = CombatTab:CreateToggle({
    Name = "Killaura",
    CurrentValue = false,
    Flag = "Killaura",
    Callback = ToggleKillaura
})

CombatTab:CreateToggle({
    Name = "Instakill",
    CurrentValue = false,
    Flag = "InstaKill",
    Callback = ToggleInstakill
})
--//
local CharacterTab = Window:CreateTab("Character", "user")
CharacterTab:CreateSection("Game")

CharacterTab:CreateSlider({
    Name = "Gravity",
    Range = {25, 250},
    Increment = 1,
    CurrentValue = 196,
    Flag = "Gravity",
    Callback = UpdateGravity
})
CharacterTab:CreateSection("Properties")

CharacterTab:CreateSlider({
    Name = "Walkspeed",
    Range = {30, 150},
    Increment = 1,
    CurrentValue = 30,
    Flag = "WalkspeedSlider",
    Callback = UpdateWalkspeed
})

CharacterTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 250},
    Increment = 1,
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = UpdateJumpPower
})

--//
local MiscTab = Window:CreateTab("Misc", "ellipsis")

MiscTab:CreateSection("Map")

MiscTab:CreateToggle({
    Name = "Killbricks",
    CurrentValue = true,
    Flag = "Killbricks",
    Callback = ToggleKillbricks
})

MiscTab:CreateButton({
    Name = "Teleport To Map",
    Callback = TeleportToMap
})

MiscTab:CreateButton({
    Name = "Teleport To Spawn",
    Callback = TeleportToSpawn
})
