local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- [ LOAD MODULES ]
local HUD_Mod = loadstring(game:HttpGet("https://raw.githubusercontent.com/ddshub-max/DDSCruising/refs/heads/main/HudModule.lua"))()
local Engine_Mod = loadstring(game:HttpGet("https://raw.githubusercontent.com/ddshub-max/DDSCruising/refs/heads/main/EngineModule.lua"))()
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()

-- [ INITIALIZE ]
Engine_Mod:InitAntiAFK(player)
Engine_Mod:CreateAntiVoid(player)
local ScreenHUD, MoneyHUD, AvgHUD = HUD_Mod:Create(player.Name)
local rpValue = player:WaitForChild("PlayerData"):WaitForChild("RPValue")

-- State
local cruiseActive = false
local startTime, startRP, targetRP = 0, 0, 0
local lockY = 0

local Window = OrionLib:MakeWindow({
    Name = "💎 DDS MONITOR PREMIUM", 
    HidePremium = true, 
    SaveConfig = false, 
    IntroText = "WELCOME BOSS SYSTEM"
})

-- [ TAB DASHBOARD ]
local MainTab = Window:MakeTab({Name = "Dashboard", Icon = "rbxassetid://6023426926"})

MainTab:AddSection({ Name = "✨ LIVE PROFIT STATUS" })
local RPNowInfo = MainTab:AddLabel("💰 Saldo: RP 0")
local RPResultInfo = MainTab:AddLabel("📈 Gained: + 0")
local RPAVGInfo = MainTab:AddLabel("⚡ AVG/Hour: 0")

MainTab:AddSection({ Name = "⏳ SESSION PROGRESS" })
local TimeInfo = MainTab:AddLabel("⏱️ Running: 00:00:00")
local TargetInfo = MainTab:AddLabel("🎯 Target: -")
local ETAInfo = MainTab:AddLabel("🚀 ETA: -")

-- [ TAB CONTROL PANEL ]
local SettingsTab = Window:MakeTab({Name = "Control Panel", Icon = "rbxassetid://6031289129"})

SettingsTab:AddSection({ Name = "🛵 VEHICLE INTERACTION" })

-- TOMBOL BARU: RIDE MOTOR
SettingsTab:AddButton({
    Name = "Ride My Motor",
    Callback = function()
        -- Memanggil fungsi dari EngineModule
        Engine_Mod:RideMotor(player)
        
        -- Update lockY otomatis setelah naik agar Cruise stabil
        task.wait(2.5) -- Tunggu animasi duduk selesai
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart then
            lockY = hum.SeatPart.Position.Y
            print("⚓ LockY Updated to: " .. lockY)
        end
    end    
})

SettingsTab:AddSection({ Name = "⚙️ CRUISE ENGINE" })

SettingsTab:AddToggle({
    Name = "Start Auto Cruise",
    Default = false,
    Callback = function(v)
        cruiseActive = v
        ScreenHUD.Enabled = v
        if v then
            Engine_Mod:ClearWorld(player)
            startTime, startRP = tick(), rpValue.Value
            
            -- Re-check lockY jika belum terisi
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.SeatPart then 
                lockY = hum.SeatPart.Position.Y 
            end
        end
    end
})

SettingsTab:AddTextbox({
    Name = "Target RP Goal",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        targetRP = tonumber(Value) or 0
        TargetInfo:Set("Target: " .. (targetRP > 0 and format(targetRP) or "-"))
    end    
})

-- [ UPDATE LOGIC ]
function format(n)
    return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

RunService.RenderStepped:Connect(function()
    local currentRP = rpValue.Value
    RPNowInfo:Set("💰 Saldo: RP " .. format(currentRP))
    
    if cruiseActive then
        MoneyHUD.Text = "💰 Rp. " .. format(currentRP)
        
        local elapsed = tick() - startTime
        local gained = currentRP - startRP
        local perHour = elapsed > 0 and (gained / elapsed) * 3600 or 0
        
        AvgHUD.Text = "⚡ " .. format(perHour) .. " / hr"
        RPResultInfo:Set("📈 Gained: + " .. format(gained))
        RPAVGInfo:Set("⚡ AVG/Hour: " .. format(perHour))

        local h, m, s = math.floor(elapsed/3600), math.floor((elapsed%3600)/60), math.floor(elapsed%60)
        TimeInfo:Set(string.format("⏱️ Running: %02d:%02d:%02d", h, m, s))

        if targetRP > 0 and perHour > 0 then
            local remain = math.max(targetRP - currentRP, 0)
            local eta = (remain / perHour) * 3600
            local eh, em, es = math.floor(eta/3600), math.floor((eta%3600)/60), math.floor(eta%60)
            ETAInfo:Set(string.format("🚀 ETA: %02dh %02dm %02ds", eh, em, es))
        else
            ETAInfo:Set("🚀 ETA: -")
        end
    end
end)

-- [ RUN ENGINE ]
Engine_Mod:RunCruise(player, {
    IsActive = function() return cruiseActive end,
    LockY = function() return lockY end -- Menggunakan function agar dinamis
})

OrionLib:Init()
