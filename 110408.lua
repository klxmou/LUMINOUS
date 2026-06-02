Config = {
    api = "aa8d9b8e-85e1-4a57-b4ad-565b7ce9c986",
    service = "LUMINOUS 1 week",
    provider = "LUMIN"
}

-- Bypass/Security Layer Execution
local function ScriptRemover()
    local Players = game:GetService("Players")
    local ServerScriptService = game:GetService("ServerScriptService")

    local function containsKickFunction(script)
        if not script or not script:IsA("LuaSourceContainer") then
            return false
        end
        local source = script.Source or ""
        if source:lower():find("function%s+kick") or source:lower():find(":%s*kick") then
            return true
        end
        return false
    end

    local function deleteKickScripts(parent)
        for _, desc in ipairs(parent:GetDescendants()) do
            if containsKickFunction(desc) then
                pcall(function() desc:Destroy() end)
            end
        end
    end

    pcall(function()
        if game:GetService("RunService"):IsServer() then
            deleteKickScripts(ServerScriptService)
            deleteKickScripts(game:GetService("ServerStorage"))
        else
            if Players.LocalPlayer then
                deleteKickScripts(Players.LocalPlayer:WaitForChild("PlayerScripts"))
            end
        end
    end)

    game.DescendantAdded:Connect(function(desc)
        if containsKickFunction(desc) then
            task.wait(0.1)
            if desc and desc.Parent then
                pcall(function() desc:Destroy() end)
            end
        end
    end)
end
pcall(ScriptRemover)

local function RivalsAnticheatBypass()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    if game.GameId ~= 6035872082 then
        return
    end

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer

    pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LogService = game:GetService("LogService")
        local ScriptContext = game:GetService("ScriptContext")
        
        task.spawn(function()
            for _, v in pairs(getgc(true)) do
                if typeof(v) == "function" then
                    local ok, src = pcall(function() return debug.info(v, "s") end)
                    if ok and type(src) == "string" and string.find(src, "AnalyticsPipelineController") then
                        hookfunction(v, newcclosure(function(...)
                            return task.wait(9e9)
                        end))
                    end
                end
            end
        end)
        
        task.spawn(function()
            local ok, remote = pcall(function()
                return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AnalyticsPipeline"):WaitForChild("RemoteEvent")
            end)
            if ok and remote and remote.OnClientEvent then
                for _, conn in pairs(getconnections(remote.OnClientEvent)) do
                    if conn and conn.Function then
                        pcall(function()
                            hookfunction(conn.Function, newcclosure(function(...) end))
                        end)
                    end
                end
            end
        end)
        
        task.spawn(function()
            for _, conn in pairs(getconnections(LogService.MessageOut)) do
                if conn and conn.Function then
                    pcall(function()
                        hookfunction(conn.Function, newcclosure(function(...) end))
                    end)
                end
            end
        end)
        
        task.spawn(function()
            for _, conn in ipairs(getconnections(ScriptContext.Error)) do
                pcall(function() conn:Disable() end)
            end
            pcall(function()
                hookfunction(ScriptContext.Error.Connect, newcclosure(function(...)
                    return nil
                end))
            end)
        end)
         
        task.spawn(function()
            local KickNames = {"Kick", "kick"}
            for _, name in ipairs(KickNames) do
                local fn = LocalPlayer[name]
                if type(fn) == "function" then
                    local oldkick
                    oldkick = hookfunction(fn, newcclosure(function(self, ...)
                        if self == LocalPlayer then return end
                        return oldkick(self, ...)
                    end))
                end
            end
        end)
    end)
end
pcall(RivalsAnticheatBypass)

local function ClientAlertBypass()
    local plrs = game:GetService("Players")
    local rf = game:GetService("ReplicatedFirst")
    local lp = plrs.LocalPlayer

    local fake = Instance.new("RemoteEvent")
    fake.Name = "ClientAlert"
    fake.Parent = lp

    local pmt = getrawmetatable(lp)
    if pmt then
        local oldnc = pmt.__namecall
        setreadonly(pmt, false)
        pmt.__namecall = newcclosure(function(self, ...)
            if getnamecallmethod() == "WaitForChild" and select(1, ...) == "ClientAlert" then
                return fake
            end
            return oldnc(self, ...)
        end)
        setreadonly(pmt, true)
    end

    local mt = getrawmetatable(game)
    if mt then
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if self == lp and (m == "Kick" or m == "kick") then return end
            if m:lower():find("kick") or m == "Shutdown" then return end
            if m == "FireServer" and self == fake then return end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end

    local ls3 = rf:FindFirstChild("LocalScript3")
    if ls3 then
        for _, f in getgc(false) do
            if typeof(f) == "function" then
                local ok, e = pcall(getfenv, f)
                if ok and e then
                    local scr = rawget(e, "script")
                    if scr and (scr == ls3 or tostring(scr):find("LoadingScreen")) then
                        local ok2, cs = pcall(debug.getconstants, f)
                        if ok2 then
                            for _, k in cs do
                                if typeof(k) == "string" and (k:find("TakeTheL") or k:find("ban") or k:find("kick")) then
                                    hookfunction(f, function() end)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
pcall(ClientAlertBypass)

local function applyBypass()
    coroutine.wrap(function()
        xpcall(function()
            local bypassWords = {
                "anticheat", "anti-cheat", "antiexploit", "anti-exploit",
                "detect", "cheatdetection", "exploitdetection", "ban", "banning",
                "blacklist", "blacklisted", "logging", "logger", "webhook",
                "report", "reporting", "screenshot", "capture", "screenie",
                "admin", "moderation", "kick", "banwave", "watchdog", "antitamper"
            }
            
            local function blockScript(obj)
                if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    local n = obj.Name:lower()
                    for _, ac in pairs(bypassWords) do
                        if n:find(ac) then 
                            pcall(function() obj.Disabled = true end)
                            break 
                        end
                    end
                end
            end
            
            for _, obj in pairs(game:GetDescendants()) do 
                blockScript(obj) 
            end
            game.DescendantAdded:Connect(blockScript)
        end, function(err) end)
        
        xpcall(function()
            local networkClient = game:GetService("NetworkClient")
            if networkClient then
                networkClient.ChildAdded:Connect(function(child)
                    local n = child.Name:lower()
                    if n:find("blackies") or n:find("femboys") or n:find("jews") then
                        pcall(function() child:Destroy() end)
                    end
                end)
            end
        end, function(err) end)
    end)()
end
pcall(applyBypass)

-- Core Game Services & State Infrastructure
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local unlockAllActive = false
local equippedCosmetics = {}
local favoritedCosmetics = {}
local currentWeaponName = nil
local currentViewingPlayer = nil

local function initializeUnlockAll()
    if unlockAllActive then return end
    unlockAllActive = true
    
    task.spawn(function()
        repeat task.wait() until game:IsLoaded()
        local v0 = game:GetService("Players")
        local v1 = game:GetService("ReplicatedStorage")
        local v3 = v0.LocalPlayer
        local v5, v7, v8
        local v6 = 0
        
        repeat 
            task.wait(1)
            v5 = v3:FindFirstChild("PlayerScripts")
            v6 = v6 + 1
            if v6 > 20 then return end
        until v5
        
        v6 = 0
        repeat 
            task.wait(1)
            v7 = v5:FindFirstChild("Controllers")
            v6 = v6 + 1
            if v6 > 20 then return end
        until v7
        
        v6 = 0
        repeat 
            task.wait(1)
            v8 = v1:FindFirstChild("Modules")
            v6 = v6 + 1
            if v6 > 20 then return end
        until v8
        
        local function waitForChild(container, childName, timeout)
            local elapsed = 0
            while not container:FindFirstChild(childName) and elapsed < timeout do
                task.wait(0.5)
                elapsed = elapsed + 0.5
            end
            return container:FindFirstChild(childName)
        end
        
        local v10 = waitForChild(v8, "CosmeticLibrary", 10)
        local v11 = waitForChild(v8, "ItemLibrary", 10)
        local v12 = waitForChild(v7, "PlayerDataController", 10)
        local v13 = waitForChild(v8, "PlayerDataUtility", 10)
        
        if not v10 or not v11 or not v12 then return end
        
        local v14, v15, v16, v17, v18
        local success = pcall(function()
            v15 = require(v10)
            v16 = require(v11)
            v17 = require(v12)
            v18 = require(v13)
            local v72 = v8:FindFirstChild("EnumLibrary")
            if v72 then
                v14 = require(v72)
                if v14 and v14.WaitForEnumBuilder then
                    task.spawn(function() pcall(function() v14:WaitForEnumBuilder() end) end)
                end
            end
        end)
        
        if not success or not v15 or not v16 or not v17 then return end
        
        local function getAllWeapons(unlocked)
            local result = {}
            if v16 and v16.Items then
                for name, _ in pairs(v16.Items) do
                    if not name:find("MISSING_") then result[name] = unlocked end
                end
            end
            return result
        end
        
        v17.OwnsAllWeapons = function() return true end
        v17.GetUnlockedWeapons = function() return getAllWeapons(true) end
        
        local equipped = {}
        local favorites = {}
        local cosmeticTypes = {Skin = true, Wrap = true}
        
        local function createCosmeticObject(name, category, options)
            if not v15 or not v15.Cosmetics then return nil end
            local cosmeticData = v15.Cosmetics[name]
            if not cosmeticData then return nil end
            local result = {}
            for k, v in pairs(cosmeticData) do result[k] = v end
            result.Name = name
            result.Type = result.Type or category
            result.Seed = math.random(1, 1000000)
            if v14 then
                pcall(function()
                    local enumVal = v14:ToEnum(name)
                    if enumVal then result.Enum = enumVal; result.ObjectID = enumVal end
                end)
            end
            if options then
                if options.inverted then result.Inverted = true end
                if options.favoritesOnly then result.OnlyUseFavorites = true end
            end
            return result
        end
        
        local configFile = "Luminous/unlockall_config.json"
        
        local function saveConfig()
            if not writefile then return end
            task.spawn(function()
                pcall(function()
                    local data = {equipped = {}, favorites = favorites}
                    for weapon, slots in pairs(equipped) do
                        data.equipped[weapon] = {}
                        for slot, item in pairs(slots) do
                            if item and item.Name then
                                data.equipped[weapon][slot] = {
                                    name = item.Name,
                                    seed = item.Seed,
                                    inverted = item.Inverted
                                }
                            end
                        end
                    end
                    if not isfolder("Luminous") then makefolder("Luminous") end
                    writefile(configFile, game:GetService("HttpService"):JSONEncode(data))
                end)
            end)
        end
        
        local function loadConfig()
            if not readfile or not isfile or not isfile(configFile) then return end
            pcall(function()
                local data = game:GetService("HttpService"):JSONDecode(readfile(configFile))
                if data.equipped then
                    for weapon, slots in pairs(data.equipped) do
                        equipped[weapon] = {}
                        for slot, itemData in pairs(slots) do
                            local cosmetic = createCosmeticObject(itemData.name, slot, {inverted = itemData.inverted})
                            if cosmetic then
                                cosmetic.Seed = itemData.seed
                                equipped[weapon][slot] = cosmetic
                            end
                        end
                    end
                end
                favorites = data.favorites or {}
            end)
        end
        
        local originalOwnsCosmetic = v15.OwnsCosmetic
        local originalOwnsCosmeticForWeapon = v15.OwnsCosmeticForWeapon
        local originalOwnsCosmeticNormally = v15.OwnsCosmeticNormally
        
        local function isSkinOrWrap(cosmeticName)
            if not cosmeticName or type(cosmeticName) ~= "string" or cosmeticName:find("MISSING_") then return false end
            local cosmeticData = v15.Cosmetics[cosmeticName]
            return cosmeticData and cosmeticTypes[cosmeticData.Type] or false
        end
        
        v15.OwnsCosmetic = function(_, _, cosmeticName, _) if isSkinOrWrap(cosmeticName) then return true end return originalOwnsCosmetic(_, _, cosmeticName, _) end
        v15.OwnsCosmeticForWeapon = function(_, _, cosmeticName, _) if isSkinOrWrap(cosmeticName) then return true end return originalOwnsCosmeticForWeapon(_, _, cosmeticName, _) end
        v15.OwnsCosmeticNormally = function(_, cosmeticName, ...) if isSkinOrWrap(cosmeticName) then return true end return originalOwnsCosmeticNormally(_, cosmeticName, ...) end
        
        local originalGet = v17.Get
        v17.Get = function(_, key)
            local result = originalGet(_, key)
            if key == "CosmeticInventory" then return result end
            if key == "FavoritedCosmetics" then
                local favs = {}
                if result then for k, v in pairs(result) do favs[k] = v end end
                for cat, items in pairs(favorites) do
                    favs[cat] = favs[cat] or {}
                    for item, val in pairs(items) do favs[cat][item] = val end
                end
                return favs
            end
            return result
        end
        
        local originalGetWeaponData = v17.GetWeaponData
        v17.GetWeaponData = function(_, weaponName)
            local data = {Unlocked = true, Level = 100, XP = 99999}
            local originalData = originalGetWeaponData(_, weaponName)
            if originalData then for k, v in pairs(originalData) do data[k] = v end end
            if equipped and equipped[weaponName] then
                for slot, cosmetic in pairs(equipped[weaponName]) do data[slot] = cosmetic end
            end
            return data
        end
        
        local fighterController = nil
        task.spawn(function()
            local fc = v7:FindFirstChild("FighterController")
            if fc then pcall(function() fighterController = require(fc) end) end
        end)
        
        task.spawn(function()
            task.wait(1)
            if not hookmetamethod then return end
            local remotes = v1:FindFirstChild("Remotes")
            local dataRemotes = remotes and remotes:FindFirstChild("Data")
            local replicationRemotes = remotes and remotes:FindFirstChild("Replication")
            local equipRemote = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
            local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
            local fighterRemote = replicationRemotes and replicationRemotes:FindFirstChild("Fighter")
            local useItemRemote = fighterRemote and fighterRemote:FindFirstChild("UseItem")
            
            if not equipRemote then return end
            
            local originalNamecall
            originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                if getnamecallmethod() ~= "FireServer" then return originalNamecall(self, ...) end
                local args = {...}
                
                if useItemRemote and self == useItemRemote and fighterController then
                    task.spawn(function()
                        pcall(function()
                            local fighter = fighterController:GetFighter(v3)
                            if fighter and fighter.Items then
                                for _, item in pairs(fighter.Items) do
                                    if item:Get("ObjectID") == args[1] then currentWeaponName = item.Name; break end
                                end
                            end
                        end)
                    end)
                end
                
                if self == equipRemote then
                    local weapon, slot, cosmeticName = args[1], args[2], args[3]
                    local options = args[4] or {}
                    equipped[weapon] = equipped[weapon] or {}
                    if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                        equipped[weapon][slot] = nil
                        if not next(equipped[weapon]) then equipped[weapon] = nil end
                    else
                        local cosmetic = createCosmeticObject(cosmeticName, slot, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                        if cosmetic then equipped[weapon][slot] = cosmetic end
                    end
                    task.spawn(function()
                        task.wait(0.1)
                        pcall(function() v17.CurrentData:Replicate("WeaponInventory") end)
                        saveConfig()
                    end)
                    return
                end
                
                if favoriteRemote and self == favoriteRemote then
                    favorites[args[1]] = favorites[args[1]] or {}
                    favorites[args[1]][args[2]] = args[3] or nil
                    saveConfig()
                    return
                end
                return originalNamecall(self, ...)
            end)
        end)
        
        local originalGetViewModelImage = v16.GetViewModelImageFromWeaponData
        v16.GetViewModelImageFromWeaponData = function(item, weaponData, highRes)
            if not weaponData then return originalGetViewModelImage(item, weaponData, highRes) end
            local weaponName = weaponData.Name
            local hasSkin = (weaponData.Skin and equipped[weaponName] and (weaponData.Skin == equipped[weaponName].Skin)) or ((currentViewingPlayer == v3) and equipped[weaponName] and equipped[weaponName].Skin)
            if hasSkin and equipped[weaponName] and equipped[weaponName].Skin then
                local viewModel = item.ViewModels[equipped[weaponName].Skin.Name]
                if viewModel then return viewModel[(highRes and "ImageHighResolution") or "Image"] or viewModel.Image end
            end
            return originalGetViewModelImage(item, weaponData, highRes)
        end
        
        task.spawn(function()
            task.wait(3)
            pcall(function()
                local clientItemModule = v5.Modules.ClientReplicatedClasses.ClientFighter.ClientItem
                local clientItem = require(clientItemModule)
                if clientItem._CreateViewModel then
                    local originalCreateViewModel = clientItem._CreateViewModel
                    clientItem._CreateViewModel = function(item, viewModelData)
                        local itemName = item.Name
                        local owner = item.ClientFighter and item.ClientFighter.Player
                        currentViewingPlayer = (owner == v3) and itemName or nil
                        if (owner == v3) and equipped[itemName] and equipped[itemName].Skin and viewModelData then
                            pcall(function()
                                local dataEnum = item:ToEnum("Data")
                                local skinEnum = item:ToEnum("Skin")
                                local nameEnum = item:ToEnum("Name")
                                if viewModelData[dataEnum] then
                                    viewModelData[dataEnum][skinEnum] = equipped[itemName].Skin
                                    viewModelData[dataEnum][nameEnum] = equipped[itemName].Skin.Name
                                elseif viewModelData.Data then
                                    viewModelData.Data.Skin = equipped[itemName].Skin
                                    viewModelData.Data.Name = equipped[itemName].Skin.Name
                                end
                            end)
                        end
                        local result = originalCreateViewModel(item, viewModelData)
                        currentViewingPlayer = nil
                        return result
                    end
                end
            end)
            
            pcall(function()
                local clientViewModelModule = v5.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
                if clientViewModelModule then
                    local clientViewModel = require(clientViewModelModule)
                    if clientViewModel.GetWrap then
                        local originalGetWrap = clientViewModel.GetWrap
                        clientViewModel.GetWrap = function(viewModel)
                            local itemName = viewModel.ClientItem and viewModel.ClientItem.Name
                            local owner = viewModel.ClientItem and viewModel.ClientItem.ClientFighter and viewModel.ClientItem.ClientFighter.Player
                            if itemName and owner == v3 and equipped[itemName] and equipped[itemName].Wrap then return equipped[itemName].Wrap end
                            return originalGetWrap(viewModel)
                        end
                    end
                    
                    local originalNew = clientViewModel.new
                    clientViewModel.new = function(data, parent)
                        local owner = parent.ClientFighter and parent.ClientFighter.Player
                        local itemName = currentViewingPlayer or parent.Name
                        if owner == v3 and equipped[itemName] then
                            pcall(function()
                                local replicatedClass = require(v1.Modules.ReplicatedClass)
                                local dataEnum = replicatedClass:ToEnum("Data")
                                data[dataEnum] = data[dataEnum] or {}
                                if equipped[itemName].Skin then data[dataEnum][replicatedClass:ToEnum("Skin")] = equipped[itemName].Skin end
                                if equipped[itemName].Wrap then data[dataEnum][replicatedClass:ToEnum("Wrap")] = equipped[itemName].Wrap end
                                if equipped[itemName].Charm then data[dataEnum][replicatedClass:ToEnum("Charm")] = equipped[itemName].Charm end
                            end)
                        end
                        local result = originalNew(data, parent)
                        if owner == v3 and equipped[itemName] and equipped[itemName].Wrap and result._UpdateWrap then
                            task.spawn(function()
                                result:_UpdateWrap()
                                task.wait(0.1)
                                if not result._destroyed then result:_UpdateWrap() end
                            end)
                        end
                        return result
                    end
                end
            end)
            
            pcall(function()
                local viewProfileModule = require(v5.Modules.Pages.ViewProfile)
                if viewProfileModule and viewProfileModule.Fetch then
                    local originalFetch = viewProfileModule.Fetch
                    viewProfileModule.Fetch = function(_, player) currentViewingPlayer = player return originalFetch(_, player) end
                end
            end)
            
            pcall(function()
                local clientEntityModule = require(v5.Modules.ClientReplicatedClasses.ClientEntity)
                if clientEntityModule.ReplicateFromServer then
                    local originalReplicate = clientEntityModule.ReplicateFromServer
                    clientEntityModule.ReplicateFromServer = function(entity, eventName, ...)
                        if eventName == "FinisherEffect" then
                            local args = {...}
                            local finisherData = args[3]
                            local finisherName = finisherData
                            if type(finisherData) == "userdata" and v14 and v14.FromEnum then
                                pcall(function() finisherName = v14:FromEnum(finisherData) end)
                            end
                            local isLocalPlayer = (tostring(finisherName) == v3.Name) or (tostring(finisherName):lower() == v3.Name:lower())
                            if isLocalPlayer and currentWeaponName and equipped[currentWeaponName] and equipped[currentWeaponName].Finisher then
                                local finisher = equipped[currentWeaponName].Finisher
                                local finisherEnum = finisher.Enum
                                if not finisherEnum and v14 then pcall(function() finisherEnum = v14:ToEnum(finisher.Name) end) end
                                if finisherEnum then args[1] = finisherEnum return originalReplicate(entity, eventName, unpack(args)) end
                            end
                        end
                        return originalReplicate(entity, eventName, ...)
                    end
                end
            end)
        end)
        loadConfig()
    end)
end

local function shutdownUnlockAll()
    if not unlockAllActive then return end
    unlockAllActive = false
end

-- Modular Combat States & Toggles
local SATarget = nil
local AimbotTarget = nil
local abHoldMem = false

local SAFOVCircleOuter = Drawing.new("Circle")
SAFOVCircleOuter.Thickness = 4; SAFOVCircleOuter.Filled = false; SAFOVCircleOuter.Color = Color3.new(0,0,0); SAFOVCircleOuter.Visible = false
local SAFOVCircleInner = Drawing.new("Circle")
SAFOVCircleInner.Thickness = 1; SAFOVCircleInner.Filled = false; SAFOVCircleInner.Color = Color3.new(1,1,1); SAFOVCircleInner.Visible = false

local AimbotFOVOuter = Drawing.new("Circle")
AimbotFOVOuter.Thickness = 4; AimbotFOVOuter.Filled = false; AimbotFOVOuter.Color = Color3.new(0,0,0); AimbotFOVOuter.Visible = false
local AimbotFOVInner = Drawing.new("Circle")
AimbotFOVInner.Thickness = 1; AimbotFOVInner.Filled = false; AimbotFOVInner.Color = Color3.new(1,1,1); AimbotFOVInner.Visible = false

-- Drawings/ESP Processing Arrays
local espBoxData = {}; local espBoxAddedCon, espBoxRemovingCon = nil, nil
local espNameData = {}; local espNameAddedCon, espNameRemovingCon = nil, nil
local espHealthData = {}; local espHealthAddedCon, espHealthRemovingCon = nil, nil

local function getCharBounds(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and Vector3.new(3, hum.HipHeight + 2, 3) or Vector3.new(4, 5, 4)
end

local function makeESPBox(plr)
    local o1 = Drawing.new("Square"); o1.Filled = false
    local o2 = Drawing.new("Square"); o2.Filled = false
    local bx = Drawing.new("Square"); bx.Filled = false
    local hb
    hb = RunService.Heartbeat:Connect(function()
        local masterOn = Toggles.MasterESP and Toggles.MasterESP.Value
        local boxOn = Toggles.BoxESP and Toggles.BoxESP.Value
        if not masterOn or not boxOn then o1.Visible = false; o2.Visible = false; bx.Visible = false; return end
        local char = plr.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then o1.Visible = false; o2.Visible = false; bx.Visible = false; return end

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
            if dist > (Options.ESPMaxDistance and Options.ESPMaxDistance.Value or 500) then
                o1.Visible = false; o2.Visible = false; bx.Visible = false; return
            end
        end

        local pPos, onScreenPrimary = Camera:WorldToViewportPoint(root.Position)
        if not onScreenPrimary then o1.Visible = false; o2.Visible = false; bx.Visible = false; return end
        local size = getCharBounds(char); local cf = root.CFrame
        local corners = {
            cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2), cf * Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
            cf * Vector3.new(size.X/2, -size.Y/2, -size.Z/2), cf * Vector3.new(size.X/2, size.Y/2, -size.Z/2),
            cf * Vector3.new(-size.X/2, -size.Y/2, size.Z/2), cf * Vector3.new(-size.X/2, size.Y/2, size.Z/2),
            cf * Vector3.new(size.X/2, -size.Y/2, size.Z/2), cf * Vector3.new(size.X/2, size.Y/2, size.Z/2),
        }
        local mnX, mnY, mxX, mxY = math.huge, math.huge, -math.huge, -math.huge
        local onScreen = false
        for _, v in ipairs(corners) do
            local p, vis = Camera:WorldToViewportPoint(v)
            if vis then onScreen = true end
            mnX = math.min(mnX, p.X); mnY = math.min(mnY, p.Y)
            mxX = math.max(mxX, p.X); mxY = math.max(mxY, p.Y)
        end
        if not onScreen then o1.Visible = false; o2.Visible = false; bx.Visible = false; return end
        local pos = Vector2.new(mnX, mnY); local sz = Vector2.new(mxX - mnX, mxY - mnY)
        local col = Options.BoxESPColor and Options.BoxESPColor.Value or Color3.new(1, 1, 1)
        local oc = Options.BoxESPOutlineColor and Options.BoxESPOutlineColor.Value or Color3.new(0, 0, 0)
        local thk = Options.BoxESPThickness and Options.BoxESPThickness.Value or 1
        local showO = Toggles.BoxESPOutline and Toggles.BoxESPOutline.Value
        o1.Position = pos - Vector2.new(1, 1); o1.Size = sz + Vector2.new(2, 2); o1.Color = oc; o1.Thickness = thk + 2; o1.Visible = showO
        o2.Position = pos + Vector2.new(1, 1); o2.Size = sz - Vector2.new(2, 2); o2.Color = oc; o2.Thickness = thk + 1; o2.Visible = showO
        bx.Position = pos; bx.Size = sz; bx.Color = col; bx.Thickness = thk; bx.Visible = true
    end)
    local function rem() o1:Remove(); o2:Remove(); bx:Remove(); if hb then hb:Disconnect() end end
    plr.CharacterRemoving:Connect(rem)
    plr.AncestryChanged:Connect(function(_, p) if not p then rem() end end)
    return rem
end

local function setupESPBox(plr)
    local d = {}; espBoxData[plr] = d
    local function add(char) char:WaitForChild("HumanoidRootPart", 5); d.rem = makeESPBox(plr) end
    if plr.Character then add(plr.Character) end
    d.ca = plr.CharacterAdded:Connect(add)
    d.cr = plr.CharacterRemoving:Connect(function() if d.rem then d.rem(); d.rem = nil end end)
end

function enable_box_esp()
    if espBoxAddedCon then return end
    espBoxAddedCon = Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then setupESPBox(p) end end)
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then setupESPBox(p) end end
    espBoxRemovingCon = Players.PlayerRemoving:Connect(function(plr)
        local d = espBoxData[plr]; if d then if d.rem then d.rem() end if d.ca then d.ca:Disconnect() end if d.cr then d.cr:Disconnect() end espBoxData[plr] = nil end
    end)
end

function disable_box_esp()
    if espBoxAddedCon then espBoxAddedCon:Disconnect(); espBoxAddedCon = nil end
    if espBoxRemovingCon then espBoxRemovingCon:Disconnect(); espBoxRemovingCon = nil end
    for _, d in pairs(espBoxData) do if d.rem then d.rem() end if d.ca then d.ca:Disconnect() end if d.cr then d.cr:Disconnect() end end
    espBoxData = {}
end

local function makeName(plr)
    local t = Drawing.new("Text"); t.Text = plr.Name; t.Size = 16; t.Center = true; t.Outline = true; t.Font = 2; t.Visible = false
    local con = RunService.Heartbeat:Connect(function()
        local masterOn = Toggles.MasterESP and Toggles.MasterESP.Value; local nameOn = Toggles.NameESP and Toggles.NameESP.Value
        if not masterOn or not nameOn then t.Visible = false; return end
        t.Color = Options.NameESPColor and Options.NameESPColor.Value or Color3.new(1, 1, 1)
        local char = plr.Character; local head = char and char:FindFirstChild("Head")
        if not head then t.Visible = false; return end

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude > (Options.ESPMaxDistance and Options.ESPMaxDistance.Value or 500) then
                t.Visible = false; return
            end
        end

        local pos, vis = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 3, 0))
        if vis and pos.Z > 0 then t.Position = Vector2.new(pos.X, pos.Y); t.Visible = true else t.Visible = false end
    end)
    return function() t:Remove(); if con then con:Disconnect() end end
end

local function setupName(plr)
    local d = {}; espNameData[plr] = d
    local function add(char) char:WaitForChild("Head", 5); d.rem = makeName(plr) end
    if plr.Character then add(plr.Character) end
    d.ca = plr.CharacterAdded:Connect(add)
    d.cr = plr.CharacterRemoving:Connect(function() if d.rem then d.rem(); d.rem = nil end end)
end

function enable_name_esp()
    if espNameAddedCon then return end
    espNameAddedCon = Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then setupName(p) end end)
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then setupName(p) end end
    espNameRemovingCon = Players.PlayerRemoving:Connect(function(plr)
        local d = espNameData[plr]; if d then if d.rem then d.rem() end if d.ca then d.ca:Disconnect() end if d.cr then d.cr:Disconnect() end espNameData[plr] = nil end
    end)
end

function disable_name_esp()
    if espNameAddedCon then espNameAddedCon:Disconnect(); espNameAddedCon = nil end
    if espNameRemovingCon then espNameRemovingCon:Disconnect(); espNameRemovingCon = nil end
    for _, d in pairs(espNameData) do if d.rem then d.rem() end if d.ca then d.ca:Disconnect() end if d.cr then d.cr:Disconnect() end end; espNameData = {}
end

local function makeHealth(plr)
    local bg = Drawing.new("Square"); bg.Filled = true; bg.Color = Color3.new(0, 0, 0)
    local ol = Drawing.new("Square"); ol.Filled = false; ol.Thickness = 1; ol.Color = Color3.new(0, 0, 0)
    local fill = Drawing.new("Square"); fill.Filled = true
    local con = RunService.Heartbeat:Connect(function()
        local masterOn = Toggles.MasterESP and Toggles.MasterESP.Value; local healthOn = Toggles.HealthESP and Toggles.HealthESP.Value
        if not masterOn or not healthOn then bg.Visible = false; ol.Visible = false; fill.Visible = false; return end
        local hc = Options.HealthESPColor and Options.HealthESPColor.Value or Color3.new(0, 1, 0)
        local char = plr.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum then bg.Visible = false; ol.Visible = false; fill.Visible = false; return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then bg.Visible = false; ol.Visible = false; fill.Visible = false; return end

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude > (Options.ESPMaxDistance and Options.ESPMaxDistance.Value or 500) then
                bg.Visible = false; ol.Visible = false; fill.Visible = false; return
            end
        end

        local rootPos, onScreenRoot = Camera:WorldToViewportPoint(root.Position)
        if not onScreenRoot then bg.Visible = false; ol.Visible = false; fill.Visible = false; return end
        local size = getCharBounds(char); local cf = root.CFrame
        local topPos, onScreenTop = Camera:WorldToViewportPoint(cf * Vector3.new(0, size.Y/2, 0))
        local bottomPos, onScreenBottom = Camera:WorldToViewportPoint(cf * Vector3.new(0, -size.Y/2, 0))
        local rightPos, onScreenRight = Camera:WorldToViewportPoint(cf * Vector3.new(size.X/2, 0, 0))
        if not onScreenTop or not onScreenBottom or not onScreenRight then bg.Visible = false; ol.Visible = false; fill.Visible = false; return end
        local bH = math.abs(topPos.Y - bottomPos.Y); local bX = rightPos.X + 4; local bY = math.min(topPos.Y, bottomPos.Y)
        bg.Position = Vector2.new(bX, bY); bg.Size = Vector2.new(3, bH); bg.Visible = true
        ol.Position = bg.Position; ol.Size = bg.Size; ol.Visible = true
        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1); local fillH = bH * pct
        fill.Color = hc; fill.Size = Vector2.new(1, fillH); fill.Position = Vector2.new(bX + 1, bY + bH - fillH); fill.Visible = true
    end)
    return function() bg:Remove(); ol:Remove(); fill:Remove(); if con then con:Disconnect() end end
end

local function setupHealth(plr)
    local d = {}; espHealthData[plr] = d
    local function add(char) char:WaitForChild("Humanoid", 5); d.rem = makeHealth(plr) end
    if plr.Character then add(plr.Character) end
    d.ca = plr.CharacterAdded:Connect(add)
    d.cr = plr.CharacterRemoving:Connect(function() if d.rem then d.rem(); d.rem = nil end end)
end

function enable_health_esp()
    if espHealthAddedCon then return end
    espHealthAddedCon = Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then setupHealth(p) end end)
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then setupHealth(p) end end
    espHealthRemovingCon = Players.PlayerRemoving:Connect(function(plr)
        local d = espHealthData[plr]; if d then if d.rem then d.rem() end if d.ca then d.ca:Disconnect() end if d.cr then d.cr:Disconnect() end espHealthData[plr] = nil end
    end)
end

function disable_health_esp()
    if espHealthAddedCon then espHealthAddedCon:Disconnect(); espHealthAddedCon = nil end
    if espHealthRemovingCon then espHealthRemovingCon:Disconnect(); espHealthRemovingCon = nil end
    for _, d in pairs(espHealthData) do if d.rem then d.rem() end if d.ca then d.ca:Disconnect() end if d.cr then d.cr:Disconnect() end end; espHealthData = {}
end

local function GetMappedBone(char, optionValue)
    if optionValue == "Random" then
        local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
        return char:FindFirstChild(parts[math.random(1, #parts)])
    elseif optionValue == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    elseif optionValue == "Left Arm" or optionValue == "LeftArm" then 
        return char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
    elseif optionValue == "Right Arm" or optionValue == "RightArm" then 
        return char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
    elseif optionValue == "Left Leg" or optionValue == "LeftLeg" then 
        return char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")
    elseif optionValue == "Right Leg" or optionValue == "RightLeg" then 
        return char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")
    end
    return char:FindFirstChild(optionValue) or char:FindFirstChild("Head")
end

local function AB_GetClosest()
    local center = (Options.AimbotFOVPosition and Options.AimbotFOVPosition.Value == "Camera") and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or Vector2.new(Mouse.X, Mouse.Y)
    local best, dist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hitPartSetting = Options.AimbotHitPart and Options.AimbotHitPart.Value or "Head"
            local part = GetMappedBone(plr.Character, hitPartSetting)
            
            if hum and hum.Health > 0 and part then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                local vel = root and root.AssemblyLinearVelocity or Vector3.new(0,0,0)
                local pred = tonumber(Options.AimbotPrediction and Options.AimbotPrediction.Value) or 0.135
                local predPos = part.Position + (vel * pred)
    
                local pos, vis = Camera:WorldToViewportPoint(predPos)
                if vis then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    local fovSz = Options.AimbotFOVSize and Options.AimbotFOVSize.Value or 120
             
                    if mag < fovSz and mag < dist then
                        dist = mag
                        best = part
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    local ae = Toggles.AimbotEnabled and Toggles.AimbotEnabled.Value
    local afov = Toggles.AimbotFOVCircle and Toggles.AimbotFOVCircle.Value
    local fovSz = Options.AimbotFOVSize and Options.AimbotFOVSize.Value or 120
    local pos = (Options.AimbotFOVPosition and Options.AimbotFOVPosition.Value == "Camera") and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or Vector2.new(Mouse.X, Mouse.Y)
    
    AimbotFOVOuter.Visible = ae and afov; AimbotFOVInner.Visible = ae and afov
    AimbotFOVOuter.Radius = fovSz; AimbotFOVInner.Radius = fovSz
    AimbotFOVOuter.Position = pos; AimbotFOVInner.Position = pos
    
    local holding = Options.AimbotKeyPicker and Options.AimbotKeyPicker:GetState() or false
    local meth = Options.AimbotMethod and Options.AimbotMethod.Value or "Camera"
    
    if ae and holding then
        if not AimbotTarget or not AimbotTarget.Parent then AimbotTarget = AB_GetClosest() end
        if AimbotTarget then
            if not abHoldMem then
                abHoldMem = true
                if meth == "Camera" then UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter end
            end
            local root = AimbotTarget.Parent:FindFirstChild("HumanoidRootPart")
            local vel = root and root.AssemblyLinearVelocity or Vector3.new(0,0,0)
            local pred = tonumber(Options.AimbotPrediction and Options.AimbotPrediction.Value) or 0.135
          
            local tPos = AimbotTarget.Position + (vel * pred)
            local smooth = Options.AimbotSmoothness and Options.AimbotSmoothness.Value or 1
            
            if meth == "Camera" then
                local newCF = CFrame.lookAt(Camera.CFrame.Position, tPos)
                if smooth > 1 then Camera.CFrame = Camera.CFrame:Lerp(newCF, 1/smooth)
                else Camera.CFrame = newCF end
            elseif meth == "Mouse" then
                local sPos, vis = Camera:WorldToViewportPoint(tPos)
                if vis then
                    local mPos = UserInputService:GetMouseLocation()
                    local dx, dy = sPos.X - mPos.X, sPos.Y - mPos.Y
                    if smooth > 1 then mousemoverel(dx/smooth, dy/smooth)
                    else mousemoverel(dx,dy) end
                end
            end
        else
            if abHoldMem then
                abHoldMem = false
                if meth == "Camera" then UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
            end
        end
    else
        if abHoldMem then
            abHoldMem = false
            AimbotTarget = nil
            if meth == "Camera" then UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
        end
    end

    local saOn = Toggles.SilentAim and Toggles.SilentAim.Value
    local saFovOn = Toggles.SAFOVCircle and Toggles.SAFOVCircle.Value
    local saFovSz = Options.SAFOVSize and Options.SAFOVSize.Value or 100
    local saFovPos = Options.SAFOVPosition and Options.SAFOVPosition.Value or "Camera"
    
    SAFOVCircleOuter.Radius = saFovSz; SAFOVCircleInner.Radius = saFovSz
    SAFOVCircleOuter.Color = Options.SAFOVOutlineColor and Options.SAFOVOutlineColor.Value or Color3.new(0,0,0)
    SAFOVCircleInner.Color = Options.SAFOVColor and Options.SAFOVColor.Value or Color3.new(1,1,1)
    SAFOVCircleOuter.Visible = saFovOn and saOn; SAFOVCircleInner.Visible = saFovOn and saOn
    
    local saCenter = saFovPos == "Camera" and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or Vector2.new(Mouse.X, Mouse.Y)
    SAFOVCircleOuter.Position = saCenter; SAFOVCircleInner.Position = saCenter
end)

local X = {
    services = {
        rep = game:GetService("ReplicatedStorage"),
        plr = game:GetService("Players"),
    }
}
X.mod = require(X.services.rep.Modules.Utility)
X.original = X.mod.Raycast
X.cam = workspace.CurrentCamera
X.me = X.services.plr.LocalPlayer

X.mod.Raycast = function(...)
    local args = {...}
    if args[4] ~= 999 then return X.original(...) end
    
    local dir = (args[3] - args[2])
    if dir.Magnitude > 0 and dir.Unit.Y < -0.7 then return X.original(...) end

    local saOn = Toggles.SilentAim and Toggles.SilentAim.Value
    if not saOn then return X.original(...) end

    local hc = Options.SAHitChance and Options.SAHitChance.Value or 100
    if math.random(1, 100) > hc then return X.original(...) end

    local saFovSz = Options.SAFOVSize and Options.SAFOVSize.Value or 100
    local saFovPos = Options.SAFOVPosition and Options.SAFOVPosition.Value or "Camera"
    local saBoneSetting = Options.SAHitPart and Options.SAHitPart.Value or "Head"
    local visChk = Toggles.SAVisCheck and Toggles.SAVisCheck.Value

    local saCenter = saFovPos == "Camera" and Vector2.new(X.cam.ViewportSize.X / 2, X.cam.ViewportSize.Y / 2) or UserInputService:GetMouseLocation()
    local winner, record = nil, saFovSz
    local pool = {}
    
    for _, v in workspace:GetChildren() do
        if v:FindFirstChildOfClass("Humanoid") then pool[#pool+1] = v end
        if v.Name == "HurtEffect" then
            for _, c in v:GetChildren() do if c.ClassName ~= "Highlight" then pool[#pool+1] = c end end
        end
    end
    
    for _, v in pool do
        if v == X.me.Character or not v:FindFirstChild("HumanoidRootPart") then continue end
        local selectedBone = GetMappedBone(v, saBoneSetting)
        if not selectedBone then continue end
        
        local p, vis = X.cam:WorldToViewportPoint(selectedBone.Position)
        if not vis then continue end
        
        local d = (saCenter - Vector2.new(p.X, p.Y)).Magnitude
        if d < record then
            if visChk then
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {X.me.Character}
                local res = workspace:Raycast(X.cam.CFrame.Position, (selectedBone.Position - X.cam.CFrame.Position), rp)
                if res and res.Instance:IsDescendantOf(v) then winner, record = selectedBone, d; SATarget = selectedBone end
            else
                winner, record = selectedBone, d; SATarget = selectedBone
            end
        end
    end
    if winner then args[3] = winner.Position end
    return X.original(table.unpack(args))
end

local tbConn, tbTarget, tbEnterTime, tbPressed = nil, nil, 0, false
local function triggerbot_step()
    if not Toggles.Triggerbot or not Toggles.Triggerbot.Value then return end
    local tp = Mouse.Target; local plrTarget = nil
    if tp then
        local model = tp:FindFirstAncestorOfClass("Model")
        if model and model:FindFirstChildOfClass("Humanoid") then
            local plr = Players:GetPlayerFromCharacter(model)
            if plr and plr ~= LocalPlayer then
                local teamOk = not (Toggles.TBTeamCheck and Toggles.TBTeamCheck.Value) or plr.Team ~= LocalPlayer.Team
                local visOk = true
                if teamOk and Toggles.TBVisCheck and Toggles.TBVisCheck.Value then
                    local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {LocalPlayer.Character}
                    local res = workspace:Raycast(Camera.CFrame.Position, (tp.Position - Camera.CFrame.Position), rp)
                    visOk = res and (res.Instance == tp or res.Instance:IsDescendantOf(model))
                end
                if teamOk and visOk then plrTarget = plr end
            end
        end
    end
    if plrTarget then
        if not tbTarget or tbTarget ~= plrTarget then tbTarget = plrTarget; tbEnterTime = tick() end
        local delay = Options.TBDelay and Options.TBDelay.Value or 0.5
        if tick() - tbEnterTime >= delay then
            if Toggles.TBHoldClick and Toggles.TBHoldClick.Value then
                if not tbPressed then tbPressed = true; mouse1press() end
            else mouse1click() end
        end
    else
        tbTarget = nil; if tbPressed then tbPressed = false; mouse1release() end
    end
end

function enable_triggerbot() tbConn = RunService.Heartbeat:Connect(triggerbot_step) end
function disable_triggerbot()
    if tbConn then tbConn:Disconnect(); tbConn = nil end
    if tbPressed then mouse1release(); tbPressed = false end; tbTarget = nil
end

-- Window Canvas Generation 
Library.ShowToggleFrameInKeybinds = true; Library.ShowCustomCursor = true; Library.NotifySide = "Left"

local Window = Library:CreateWindow({
    Title = "LUMINOUS", Center = true, AutoShow = true, Resizable = true, ShowCustomCursor = true,
    UnlockMouseWhileOpen = true, NotifySide = "Left", TabPadding = 8, MenuFadeTime = 0.2
})

local Tabs = {
    Legit = Window:AddTab("legit"),
    Misc = Window:AddTab("misc"),
    ["UI Settings"] = Window:AddTab("settings"),
}

-- Legit Tab Setup
local SABox = Tabs.Legit:AddLeftGroupbox("Silent Aim")
SABox:AddToggle("SilentAim", { Text = "Enabled", Default = false, Tooltip = "Automatically hits closest target in FOV" })
SABox:AddSlider("SAHitChance", { Text = "Hit Chance", Default = 100, Min = 0, Max = 100, Rounding = 0 })
SABox:AddToggle("SAFOVCircle", { Text = "FOV Circle", Default = false })
SABox:AddSlider("SAFOVSize", { Text = "FOV Size", Default = 100, Min = 0, Max = 500, Rounding = 0 })
SABox:AddDropdown("SAFOVPosition", { Text = "FOV Position", Values = {"Camera","Mouse"}, Default = 1 })
SABox:AddLabel("FOV Color"):AddColorPicker("SAFOVColor", { Default = Color3.new(1,1,1), Title = "FOV Color" })
SABox:AddLabel("FOV Outline"):AddColorPicker("SAFOVOutlineColor", { Default = Color3.new(0,0,0), Title = "FOV Outline" })
SABox:AddToggle("SAVisCheck", { Text = "Visible Check", Default = false })
SABox:AddDropdown("SAHitPart", { Text = "Hit Part", Values = {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg","Random"}, Default = 1 })

local AimbotBox = Tabs.Legit:AddRightGroupbox("Aimbot")
AimbotBox:AddToggle("AimbotEnabled", { Text = "Enabled", Default = false })
    :AddKeyPicker("AimbotKeyPicker", { Default = "MB2", SyncToggleState = false, Mode = "Hold", Text = "Aimbot" })
AimbotBox:AddSlider("AimbotSmoothness", { Text = "Smoothness", Default = 1, Min = 1, Max = 25, Rounding = 0 })
AimbotBox:AddDropdown("AimbotHitPart", { Text = "Hit Part", Values = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "Random"}, Default = 1 })
AimbotBox:AddDropdown("AimbotMethod", { Text = "Aimbot Method", Values = {"Camera", "Mouse"}, Default = 1 })
AimbotBox:AddDropdown("AimbotFOVPosition", { Text = "FOV Position", Values = {"Camera", "Mouse"}, Default = 1 })
AimbotBox:AddInput("AimbotPrediction", { Text = "Prediction", Default = "0.135", Numeric = true, Finished = true })
AimbotBox:AddToggle("AimbotFOVCircle", { Text = "FOV Circle", Default = false })
AimbotBox:AddSlider("AimbotFOVSize", { Text = "FOV Size", Default = 120, Min = 0, Max = 500, Rounding = 0 })

local TBBox = Tabs.Legit:AddRightGroupbox("Triggerbot")
TBBox:AddToggle("Triggerbot", { Text = "Enabled", Default = false, Callback = function(v)
    if v then enable_triggerbot() else disable_triggerbot() end
end })
TBBox:AddToggle("TBHoldClick", { Text = "Hold Click", Default = false })
TBBox:AddSlider("TBDelay", { Text = "Delay (s)", Default = 0.5, Min = 0.1, Max = 2, Rounding = 1 })
TBBox:AddToggle("TBVisCheck", { Text = "Visible Check", Default = false })
TBBox:AddToggle("TBTeamCheck", { Text = "Team Check", Default = false })

-- ESP Migrated to Legit Tab
local ESPBox = Tabs.Legit:AddLeftGroupbox('ESP')
ESPBox:AddToggle('MasterESP', { Text = 'Master Toggle', Default = false, Tooltip = 'Enable/disable all ESP' })
ESPBox:AddSlider("ESPMaxDistance", { Text = "Max ESP Distance", Default = 500, Min = 50, Max = 3000, Rounding = 0 })
ESPBox:AddToggle('BoxESP', { Text = 'Box ESP', Default = false, Tooltip = 'Draw 2D bounding boxes', Callback = function(v) if v then enable_box_esp() else disable_box_esp() end end }):AddColorPicker('BoxESPColor', { Default = Color3.fromRGB(255,255,255), Title = 'Box Color' })
ESPBox:AddToggle('BoxESPOutline', { Text = 'Box Outline', Default = true }):AddColorPicker('BoxESPOutlineColor', { Default = Color3.fromRGB(0,0,0), Title = 'Outline Color' })
ESPBox:AddSlider('BoxESPThickness', { Text = 'Thickness', Default = 1, Min = 1, Max = 5, Rounding = 0 })
ESPBox:AddToggle('NameESP', { Text = 'Name ESP', Default = false, Callback = function(v) if v then enable_name_esp() else disable_name_esp() end end }):AddColorPicker('NameESPColor', { Default = Color3.new(1,1,1), Title = 'Name Color' })
ESPBox:AddToggle('HealthESP', { Text = 'Health Bar', Default = false, Callback = function(v) if v then enable_health_esp() else disable_health_esp() end end }):AddColorPicker('HealthESPColor', { Default = Color3.new(0,1,0), Title = 'Health Color' })

-- Misc Tab Setup
local MiscBox = Tabs.Misc:AddLeftGroupbox("Unlock All")
MiscBox:AddToggle("UnlockAllEnabled", {
    Text = "Unlock All Cosmetics & Weapons",
    Default = false,
    Tooltip = "Unlocks all weapon skins, wraps, charms, finishers, and gives max weapon level",
    Callback = function(value)
        if value then initializeUnlockAll() else shutdownUnlockAll() end
    end
})
MiscBox:AddDivider()
MiscBox:AddLabel("Note: After enabling, equip skins/items through the")
MiscBox:AddLabel("game's normal customization menu. Your selections")
MiscBox:AddLabel("will be saved automatically between sessions.")

-- UI Settings Setup Tab
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end })
MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = true, Callback = function(Value) Library.ShowCustomCursor = Value end })
MenuGroup:AddDropdown("NotificationSide", { Values = { "Left", "Right" }, Default = "Left", Text = "Notification Side", Callback = function(Value) Library:SetNotifySide(Value) end })
MenuGroup:AddDropdown("DPIDropdown", { Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%", Text = "DPI Scale", Callback = function(Value) Value = Value:gsub("%%", "") local DPI = tonumber(Value) Library:SetDPIScale(DPI) end })
MenuGroup:AddSlider("UICornerSlider", { Text = "Corner Radius", Default = Library.CornerRadius, Min = 0, Max = 20, Rounding = 0, Callback = function(value) Window:SetCornerRadius(value) end })

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function() 
    if unlockAllActive then shutdownUnlockAll() end
    disable_triggerbot()
    X.mod.Raycast = X.original
    SAFOVCircleOuter:Remove(); SAFOVCircleInner:Remove()
    AimbotFOVOuter:Remove(); AimbotFOVInner:Remove()
    disable_box_esp()
    disable_name_esp()
    disable_health_esp()
    Library:Unload() 
end)

Library.ToggleKeybind = Options.MenuKeybind

-- Configuration File Pipeline Managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("Luminous/themes")
SaveManager:SetFolder("Luminous/setting")
SaveManager:SetSubFolder("rivals")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
