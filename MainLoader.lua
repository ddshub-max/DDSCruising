local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- [ LOAD MODULES ]
local HUD_Mod = loadstring(game:HttpGet("URL_MODUL_HUD_DI_SINI"))()
local Engine_Mod = loadstring(game:HttpGet("URL_MODUL_ENGINE_DI_SINI"))()
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()

-- [ INITIALIZE ]
Engine_Mod:InitAntiAFK(player)
local ScreenHUD, MoneyHUD, AvgHUD = HUD_Mod:Create(player.Name)
local rpValue = player:WaitForChild("PlayerData"):WaitForChild("RPValue")

local cruiseActive = false
local startTime, startRP = 0, 0
local lockY = 0

local Window = OrionLib:MakeWindow({Name = "💎 DDS MONITOR PREMIUM", IntroText = "WELCOME BOSS SYSTEM"})
local MainTab = Window:MakeTab({Name = "Dashboard", Icon = "rbxassetid://6023426926"})

local SaldoLabel = MainTab:AddLabel("💰 Saldo: RP 0")

MainTab:AddToggle({
    Name = "Start Auto Cruise",
    Default = false,
    Callback = function(v)
        cruiseActive = v
        ScreenHUD.Enabled = v
        if v then
            Engine_Mod:ClearWorld(player)
            startTime, startRP = tick(), rpValue.Value
            local char = player.Character
            local seat = char:FindFirstChildOfClass("Humanoid").SeatPart
            if seat then lockY = seat.Position.Y end
        end
    end
})

-- [ UPDATE LOOP ]
local function format(n)
    return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

game:GetService("RunService").RenderStepped:Connect(function()
    local currentRP = rpValue.Value
    SaldoLabel:Set("💰 Saldo: RP " .. format(currentRP))
    
    if cruiseActive then
        MoneyHUD.Text = "💰 Rp. " .. format(currentRP)
        local elapsed = tick() - startTime
        local perHour = elapsed > 0 and ((currentRP - startRP) / elapsed) * 3600 or 0
        AvgHUD.Text = "⚡ " .. format(perHour) .. " / hr"
    end
end)

-- [ RUN ENGINE ]
Engine_Mod:RunCruise(player, {
    IsActive = function() return cruiseActive end,
    LockY = lockY
})

OrionLib:Init()
