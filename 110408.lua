local repo = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"

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

local RagebotInstance = nil
local RagebotActive = false
local GunModsActive = false
local SlingRagebotActive = false
local spamTick = false

local TELEPORT_HEIGHT_OFFSET = 6
local HEAD_BOOST = 2.5
local FREEZE_POS = CFrame.new(999999, 999999, 999999)

local GunModsHooks = {
    OldInput = nil,
    LoopConnection = nil,
    RenderConnection = nil,
    ClientItemModule = nil,
}

local trackedProjectiles = {}
local freezeConnections = {
    ChildAdded = nil,
    ChildRemoved = nil,
    Heartbeat = nil,
}

local function StartSlingRagebot()
    if SlingRagebotActive then return end
    SlingRagebotActive = true
    
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    trackedProjectiles = {}
    
    freezeConnections.ChildAdded = workspace.ChildAdded:Connect(function(obj)
        if not SlingRagebotActive then return end
        if not obj:IsA("BasePart") then return end
        
        if obj.Name == "CoreProjectile" then
            trackedProjectiles[obj] = true
        elseif obj.Name == "Part" then
            task.defer(function()
                if SlingRagebotActive and obj and obj.Parent and obj.AssemblyLinearVelocity and obj.AssemblyLinearVelocity.Magnitude > 50 then
                    trackedProjectiles[obj] = true
                end
            end)
        end
    end)
    
    freezeConnections.ChildRemoved = workspace.ChildRemoved:Connect(function(obj)
        trackedProjectiles[obj] = nil
    end)
    
    freezeConnections.Heartbeat = RunService.Heartbeat:Connect(function()
        if not SlingRagebotActive then return end
        
        pcall(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        rootPart.CFrame = FREEZE_POS
                        rootPart.AssemblyLinearVelocity = Vector3.zero
                        rootPart.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end
            
            for _, obj in pairs(workspace:GetChildren()) do
                if obj.Name == "CoreProjectile" and obj:IsA("BasePart") then
                    obj.CFrame = FREEZE_POS
                    obj.AssemblyLinearVelocity = Vector3.zero
                end
            end
            
            for projectile in pairs(trackedProjectiles) do
                if projectile and projectile.Parent then
                    projectile.CFrame = FREEZE_POS
                    projectile.AssemblyLinearVelocity = Vector3.zero
                else
                    trackedProjectiles[projectile] = nil
                end
            end
        end)
    end)
end

local function StopSlingRagebot()
    if not SlingRagebotActive then return end
    SlingRagebotActive = false
    trackedProjectiles = {}
    
    if freezeConnections.Heartbeat then
        freezeConnections.Heartbeat:Disconnect()
        freezeConnections.Heartbeat = nil
    end
    if freezeConnections.ChildAdded then
        freezeConnections.ChildAdded:Disconnect()
        freezeConnections.ChildAdded = nil
    end
    if freezeConnections.ChildRemoved then
        freezeConnections.ChildRemoved:Disconnect()
        freezeConnections.ChildRemoved = nil
    end
end

local function StartGunMods()
    if GunModsActive then return end
    GunModsActive = true
    
    local LocalPlayer = game:GetService("Players").LocalPlayer
    
    pcall(function()
        local clientItemModule = require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
        local inputFunc = clientItemModule.Input
        GunModsHooks.ClientItemModule = clientItemModule

        if clientItemModule and inputFunc then
            local oldInput;
            oldInput = hookfunction(inputFunc, function(...)
                local args = {...}
                if type(args[1]) == "table" and args[1].Info then
                    args[1].Info.ShootRecoil = 0
                    args[1].Info.ShootSpread = 0
                    args[1].Info.ProjectileSpeed = 99999999
                    args[1].Info.ShootCooldown = 0
                    args[1].Info.QuickShotCooldown = 0
                end
                return oldInput(...)
            end)
            GunModsHooks.OldInput = oldInput
        end
    end)

    pcall(function()
        local FighterController = require(LocalPlayer.PlayerScripts.Controllers.FighterController)
        local LocalFighter = FighterController:WaitForLocalFighter()

        GunModsHooks.LoopConnection = task.spawn(function()
            while GunModsActive do
                task.wait(0.05)
                if LocalFighter and LocalFighter.EquippedItem and LocalFighter.EquippedItem.Info then
                    local Info = LocalFighter.EquippedItem.Info
                    Info.ShootRecoil = 0
                    Info.ShootExplosionRadius = 0
                    Info.ShootCooldown = 0
                    Info.QuickShotCooldown = 0
                    Info.ShootBurstCooldown = 0
                    Info.HeavyAttackCooldown = 0
                    Info.AttackCooldown = 0
                    Info.Cooldown = 0
                    Info.DashCooldown = 0
                    Info.SpinCooldown = 0
                    Info.SpinSpeed = 500
                    Info.DeflectCooldown = 0
                end
            end
        end)
    end)
    
    GunModsHooks.RenderConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if not GunModsActive then return end
        pcall(function()
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
            if tool then
                for _, obj in pairs(tool:GetDescendants()) do
                    if obj:IsA("ModuleScript") or obj.Name:lower():find("config") or obj.Name:lower():find("setting") then
                        local gunConfig = require(obj)
                        if type(gunConfig) == "table" then
                            if gunConfig.FireRate then gunConfig.FireRate = 0 end
                            if gunConfig.Delay then gunConfig.Delay = 0 end
                            if gunConfig.Spread then gunConfig.Spread = 0 end
                            if gunConfig.Recoil then gunConfig.Recoil = 0 end
                        end
                    end
                end
            end
        end)
    end)
end

local function StopGunMods()
    if not GunModsActive then return end
    GunModsActive = false
    
    if GunModsHooks.LoopConnection then
        task.cancel(GunModsHooks.LoopConnection)
        GunModsHooks.LoopConnection = nil
    end
    
    if GunModsHooks.RenderConnection then
        GunModsHooks.RenderConnection:Disconnect()
        GunModsHooks.RenderConnection = nil
    end
    
    if GunModsHooks.ClientItemModule and GunModsHooks.OldInput then
        pcall(function()
            GunModsHooks.ClientItemModule.Input = GunModsHooks.OldInput
        end)
        GunModsHooks.OldInput = nil
        GunModsHooks.ClientItemModule = nil
    end
end

local function StartRagebot()
    if RagebotActive then return end
    RagebotActive = true
    
    StartGunMods()
    
    local __a1b2c3 = setmetatable({}, {
        __index = function(__d4e5f6, __g7h8i9)
            local __j0k1l2, __m3n4o5 = pcall(function()
                return game:GetService(__g7h8i9)
            end)
            if __m3n4o5 then
                return cloneref(__m3n4o5)
            end
            return nil
        end
    })

    local __p6q7r8 = getgenv()
    if __p6q7r8.__s9t0u1 then
        __p6q7r8.__s9t0u1:Shutdown()
    end

    local __v2w3x4 = __a1b2c3.Players
    local __y5z6a7 = __a1b2c3.RunService
    local __b8c9d0 = __a1b2c3.ReplicatedStorage
    local __e1f2g3 = __a1b2c3.Workspace
    local __h4i5j6 = __a1b2c3.UserInputService
    local __k7l8m9 = __v2w3x4.LocalPlayer
    local __n0o1p2 = __e1f2g3.CurrentCamera
    local __q3r4s5 = __k7l8m9.PlayerScripts
    local __t6u7v8 = require(__q3r4s5.Modules.ItemTypes.Gun)
    local __w9x0y1 = require(__b8c9d0.Modules.Utility)

    local __z2a3b4 = setmetatable({}, {
        __index = function(_, __c5d6e7)
            local __f8g9h0 = __k7l8m9.Character
            if not __f8g9h0 then return nil end
            if __c5d6e7 == "__root" then
                return __f8g9h0:FindFirstChild("HumanoidRootPart")
            elseif __c5d6e7 == "__head" then
                return __f8g9h0:FindFirstChild("Head")
            end
            return nil
        end
    })

    __p6q7r8.__s9t0u1 = {}

    do
        local __i1j2k3 = __p6q7r8.__s9t0u1
        RagebotInstance = __i1j2k3

        function __i1j2k3:__init()
            self.__active = true
            self.__target = nil
            self.__desync = false
            self.__shootingState = false
            self.__conn1 = nil
            self.__conn2 = nil
            self.__task1 = nil
            self.__oldfunc = nil
            self:__setup()
        end

        function __i1j2k3:__setup()
            -- Heartbeat Scan Loop & Continuous Void/Desync Movements
            self.__conn1 = __y5z6a7.Heartbeat:Connect(function()
                if not self.__active then return end
                self.__target = self:__find()
                
                local myRoot = __z2a3b4.__root
                if not myRoot then return end

                -- VoidSpam & Desync loops run only when NOT firing to prevent server shot rejection
                if not self.__shootingState then
                    if Library.Toggles.RagebotVoidSpam and Library.Toggles.RagebotVoidSpam.Value then
                        spamTick = not spamTick
                        local height = spamTick and math.huge or 1000000000000000
                        
                        -- Cache standard positions for visual client rendering correction
                        local trueCFrame = myRoot.CFrame
                        local trueVelocity = myRoot.Velocity
                        local trueRotVelocity = myRoot.RotVelocity

                        myRoot.CFrame = myRoot.CFrame * CFrame.new(0, height, 0)

                        -- Keep Your POV completely normal while others see you teleporting
                        __y5z6a7:BindToRenderStep("__povCorrection", 100, function()
                            __n0o1p2.CFrame = __n0o1p2.CFrame * CFrame.new(0, -height, 0)
                            __y5z6a7:UnbindFromRenderStep("__povCorrection")
                        end)

                        __y5z6a7:BindToRenderStep("__restore", 101, function()
                            myRoot.CFrame = trueCFrame
                            myRoot.Velocity = trueVelocity
                            myRoot.RotVelocity = trueRotVelocity
                            __y5z6a7:UnbindFromRenderStep("__restore")
                        end)
                    end
                end
            end)

            local __l4m5n6 = __t6u7v8.StartShooting
            self.__oldfunc = __l4m5n6
            __t6u7v8.StartShooting = function(__o7p8q9, ...)
                local __r0s1t2 = {__l4m5n6(__o7p8q9, ...)}
                if not __o7p8q9.ClientFighter or not __o7p8q9.ClientFighter.IsLocalPlayer then
                    return unpack(__r0s1t2)
                end

                local __u3v4w5 = __r0s1t2[3]
                if not __u3v4w5 or typeof(__u3v4w5) ~= "table" then
                    return unpack(__r0s1t2)
                end

                __r0s1t2[4] = true
                local __x6y7z8 = self.__target

                if not self.__active or not __x6y7z8 or not __x6y7z8.Character then
                    return unpack(__r0s1t2)
                end

                local targetHead = __x6y7z8.Character:FindFirstChild("Head")
                if not targetHead then 
                    return unpack(__r0s1t2) 
                end

                -- Instantly pause general spamming loops for structural alignment
                self.__shootingState = true

                if not self.__desync or self.__curr ~= __x6y7z8 then
                    self:__desync_start(__x6y7z8)
                    task.wait(0.05)
                end

                if self.__task1 then
                    task.cancel(self.__task1)
                    self.__task1 = nil
                end

                local headPos = targetHead.Position
                local targetHeadCFrame = targetHead.CFrame
                
                local teleportPos = headPos + Vector3.new(0, TELEPORT_HEIGHT_OFFSET, 0)
                local shootPos = headPos + Vector3.new(0, HEAD_BOOST, 0)
                local groundPos = teleportPos - Vector3.new(0, 5, 0)
                local lookCFrame = CFrame.lookAt(groundPos, shootPos)
                
                local randomOffset = Vector3.new(
                    math.random() * 0.05, 
                    math.random() * 0.05, 
                    math.random() * 0.05
                )
                
                __u3v4w5[utf8.char(0)] = __w9x0y1:EncodeCFrame(CFrame.new(groundPos, shootPos) * CFrame.Angles(lookCFrame:ToOrientation()))
                __u3v4w5[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(shootPos + randomOffset) * CFrame.Angles(lookCFrame:ToOrientation()))
                __u3v4w5[utf8.char(2)] = targetHead
                
                local relativeCFrame = targetHeadCFrame:ToObjectSpace(CFrame.new(shootPos + randomOffset))
                __u3v4w5[utf8.char(3)] = __w9x0y1:EncodeCFrame(relativeCFrame)

                -- Automatically hand back control to the continuous VoidSpammer after Rageshot finishes
                self.__task1 = task.delay(0.12, function()
                    self:__desync_stop()
                    self.__shootingState = false
                end)

                return unpack(__r0s1t2)
            end
        end

        function __i1j2k3:__find()
            local myChar = __k7l8m9.Character
            if not myChar then return nil end
            local myRoot = myChar:FindFirstChild("HumanoidRootPart")
            if not myRoot then return nil end
           
            local closest = nil
            local closestDist = math.huge
            local MAX_DISTANCE = 200

            for _, player in next, __v2w3x4:GetPlayers() do
                if player == __k7l8m9 then continue end
                if player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
               
                local char = player.Character
                if not char then continue end

                local root = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                
                if not (root and head and hum and hum.Health > 0) then continue end
               
                local dist = (myRoot.Position - head.Position).Magnitude
                
                if dist > MAX_DISTANCE then continue end
                
                if dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end
            
            return closest
        end

        function __i1j2k3:__desync_start(__c3d4e5)
            if self.__conn2 then self.__conn2:Disconnect() end
            self.__desync = true
            self.__curr = __c3d4e5

            self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
                if not self.__desync then return end
                local __f6g7h8 = __z2a3b4.__root
                if not __f6g7h8 then return end

                local targetHead = __c3d4e5.Character and __c3d4e5.Character:FindFirstChild("Head")
                if not targetHead then
                    self:__desync_stop()
                    return
                end

                local __l2m3n4 = __f6g7h8.CFrame
                local __o5p6q7 = __f6g7h8.Velocity
                local __r8s9t0 = __f6g7h8.RotVelocity

                local targetPos = targetHead.Position + Vector3.new(0, TELEPORT_HEIGHT_OFFSET, 0)
                __f6g7h8.CFrame = CFrame.new(targetPos)

                -- Keep client-side rendering looking identical to normal workspace position
                __y5z6a7:BindToRenderStep("__restore", 101, function()
                    __f6g7h8.CFrame = __l2m3n4
                    __f6g7h8.Velocity = __o5p6q7
                    __f6g7h8.RotVelocity = __r8s9t0
                    __y5z6a7:UnbindFromRenderStep("__restore")
                end)
            end)
        end

        function __i1j2k3:__desync_stop()
            self.__desync = false
            self.__curr = nil
            if self.__conn2 then
                self.__conn2:Disconnect()
                self.__conn2 = nil
            end
        end

        function __i1j2k3:Shutdown()
            self.__active = false
            if self.__conn1 then self.__conn1:Disconnect() end
            if self.__conn2 then self.__conn2:Disconnect() end
            if self.__task1 then task.cancel(self.__task1) end
            if self.__oldfunc then
                __t6u7v8.StartShooting = self.__oldfunc
            end
        end

        __i1j2k3:__init()
    end
end

local function StopRagebot()
    if not RagebotActive then return end
    
    StopGunMods()
    
    if RagebotInstance and RagebotInstance.Shutdown then
        RagebotInstance:Shutdown()
    end
    local __p6q7r8 = getgenv()
    if __p6q7r8.__s9t0u1 then
        __p6q7r8.__s9t0u1:Shutdown()
        __p6q7r8.__s9t0u1 = nil
    end
    RagebotInstance = nil
    RagebotActive = false
end

local AnimationManager = {
    CurrentAnimation = nil,
    CurrentTrack = nil,
    Animator = nil,
    Active = false,
    Enabled = false,
    SelectedAnimation = nil,
}

local AnimList = {
    {Name = "Tornado", ID = "rbxassetid://135373056067761"},
    {Name = "Spin Box", ID = "rbxassetid://90057760975026"},
    {Name = "ball spin", ID = "rbxassetid://122319751392556"},
    {Name = "ground", ID = "rbxassetid://80007036319743"},
    {Name = "Aura", ID = "rbxassetid://115838519466885"}
}

local function GetAnimator()
    local character = game:GetService("Players").LocalPlayer.Character
    if not character then return nil end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return nil end
    return humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
end

local function PlayAnimation(animationId, animationName)
    if AnimationManager.CurrentTrack then
        AnimationManager.CurrentTrack:Stop()
        AnimationManager.CurrentTrack = nil
    end
    
    local animator = GetAnimator()
    if not animator then return false end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    animation.Name = animationName or "CustomAnim"
    
    local track = animator:LoadAnimation(animation)
    if track then
        track:Play()
        AnimationManager.CurrentTrack = track
        AnimationManager.CurrentAnimation = animationName
        AnimationManager.Active = true
        return true
    end
    return false
end

local function StopAnimation()
    if AnimationManager.CurrentTrack then
        AnimationManager.CurrentTrack:Stop()
        AnimationManager.CurrentTrack = nil
    end
    AnimationManager.CurrentAnimation = nil
    AnimationManager.Active = false
end

local function OnAnimationToggle(value)
    AnimationManager.Enabled = value
    if value then
        if AnimationManager.SelectedAnimation then
            for _, anim in pairs(AnimList) do
                if anim.Name == AnimationManager.SelectedAnimation then
                    PlayAnimation(anim.ID, anim.Name)
                    break
                end
            end
        end
    else
        StopAnimation()
    end
end

local function OnAnimationChange(value)
    AnimationManager.SelectedAnimation = value
    if AnimationManager.Enabled then
        for _, anim in pairs(AnimList) do
            if anim.Name == value then
                PlayAnimation(anim.ID, anim.Name)
                break
            end
        end
    end
end

local LocalPlayer = game:GetService("Players").LocalPlayer
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if AnimationManager.Enabled and AnimationManager.SelectedAnimation then
        for _, anim in pairs(AnimList) do
            if anim.Name == AnimationManager.SelectedAnimation then
                PlayAnimation(anim.ID, anim.Name)
                break
            end
        end
    end
end)

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Left"

local Window = Library:CreateWindow({
    Title = "LUMINOUS",
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    UnlockMouseWhileOpen = true,
    NotifySide = "Left",
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab("main"),
    Character = Window:AddTab("character"),
    ["UI Settings"] = Window:AddTab("settings"),
}

local LeftTabBox = Tabs.Main:AddLeftTabbox()

local SilentAimTab = LeftTabBox:AddTab("silent aim")

SilentAimTab:AddToggle("SilentAimEnabled", { Text = "Enabled", Default = false })
SilentAimTab:AddToggle("SilentAim360", { Text = "360 Mode (Ignores FOV)", Default = false })
SilentAimTab:AddSlider("SilentAimFOVRadius", { Text = "FOV Radius", Default = 200, Min = 0, Max = 500, Rounding = 0, Suffix = "px" })
SilentAimTab:AddToggle("SilentAimShowFOV", { Text = "Show FOV Circle", Default = false })
SilentAimTab:AddDropdown("SilentAimTargetBone", { Text = "Target Bone", Default = "Head", Values = { "Head", "Torso", "HumanoidRootPart", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "UpperTorso", "LowerTorso" } })
SilentAimTab:AddSlider("SilentAimHitChance", { Text = "Hit Chance", Default = 100, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
SilentAimTab:AddToggle("SilentAimVisibleOnly", { Text = "Wall Check (Visible Only)", Default = true })
SilentAimTab:AddDivider()
SilentAimTab:AddToggle("SilentAimClosestPart", { Text = "Closest Part", Default = false })

local RagebotTab = LeftTabBox:AddTab("ragebot")

RagebotTab:AddToggle("RagebotEnabled", { 
    Text = "Ragebot ", 
    Default = false,
    Callback = function(value)
        if value then
            StartRagebot()
        else
            StopRagebot()
        end
    end
})

RagebotTab:AddToggle("SlingRagebotEnabled", { 
    Text = "Sling Ragebot ", 
    Default = false,
    Callback = function(value)
        if value then
            StartSlingRagebot()
        else
            StopSlingRagebot()
        end
    end
})

RagebotTab:AddToggle("RagebotVoidSpam", { Text = "void spam", Default = false })

local WeaponsGroup = Tabs.Main:AddRightGroupbox("weapons")
WeaponsGroup:AddLabel("⚠️ Turn off sling rage for normal guns:")
WeaponsGroup:AddLabel("• Ragebot: For normal gun")
WeaponsGroup:AddLabel("• Sling Ragebot: use with ragebot")
WeaponsGroup:AddLabel("  Hold / Click depend on gun" )

local CharacterTab = Tabs.Character

local animGroup = CharacterTab:AddLeftGroupbox("Animations")

local AnimationToggle = animGroup:AddToggle("AnimationEnable", {
    Text = "Enable Animation", Default = false,
    Callback = function(value) OnAnimationToggle(value) end
})

local animationDropdown = animGroup:AddDropdown("AnimationSelect", {
    Text = "Select Animation", Default = 1, Values = {},
    Callback = function(value) OnAnimationChange(value) end
})

local animationNames = {}
for _, anim in pairs(AnimList) do table.insert(animationNames, anim.Name) end
animationDropdown:SetValues(animationNames)
animationDropdown:SetValue(animationNames[1])
AnimationManager.SelectedAnimation = animationNames[1]

animGroup:AddButton("Stop Animation", function()
    if AnimationToggle:Get() then AnimationToggle:Set(false) end
    StopAnimation()
    AnimationManager.Enabled = false
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end})
MenuGroup:AddToggle("ShowCustomCursor", {Text = "Custom Cursor", Default = true, Callback = function(Value) Library.ShowCustomCursor = Value end})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() 
    if RagebotActive then
        StopRagebot()
    end
    if SlingRagebotActive then
        StopSlingRagebot()
    end
    Library:Unload() 
end)

Library.ToggleKeybind = Options.MenuKeybind

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
