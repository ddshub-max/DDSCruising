local HUD = {}

function HUD:Create(playerName)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DDS_PremiumDashboard"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = false
    ScreenGui.IgnoreGuiInset = true -- Menutupi seluruh layar termasuk TopBar
    ScreenGui.DisplayOrder = 999 -- Pastikan di atas UI lain
    ScreenGui.Parent = (game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui"))

    -- [ BACKGROUND FULL SCREEN ]
    local MainBG = Instance.new("ScrollingFrame")
    MainBG.Name = "MainBackground"
    MainBG.Size = UDim2.new(1, 0, 1, 0)
    MainBG.BackgroundColor3 = Color3.fromRGB(10, 10, 15) -- Gelap elegan
    MainBG.BackgroundTransparency = 0
    MainBG.BorderSizePixel = 0
    MainBG.ScrollBarThickness = 0
    MainBG.CanvasSize = UDim2.new(1, 0, 1, 0)
    MainBG.Parent = ScreenGui

    -- Efek Gradient Aksen untuk BG agar tidak bosan
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 20, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 10, 40))
    })
    UIGradient.Rotation = 45
    UIGradient.Parent = MainBG

    -- [ CONTAINER CENTER ]
    local CenterFrame = Instance.new("Frame")
    CenterFrame.Size = UDim2.new(0, 500, 0, 0)
    CenterFrame.Position = UDim2.new(0.5, -250, 0.2, 0)
    CenterFrame.BackgroundTransparency = 1
    CenterFrame.AutomaticSize = Enum.AutomaticSize.Y
    CenterFrame.Parent = MainBG

    local List = Instance.new("UIListLayout", CenterFrame)
    List.HorizontalAlignment = Enum.HorizontalAlignment.Center
    List.Padding = UDim.new(0, 20)

    -- [ FUNGSI PEMBUAT ELEMENT ]
    local function CreateSection(title, isMain)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 0)
        f.AutomaticSize = Enum.AutomaticSize.Y
        f.BackgroundTransparency = 0.9
        f.BackgroundColor3 = isMain and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(255, 255, 255)
        f.Parent = CenterFrame
        
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
        local pad = Instance.new("UIPadding", f)
        pad.PaddingBottom, pad.PaddingTop = UDim.new(0, 15), UDim.new(0, 15)
        pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 20), UDim.new(0, 20)
        
        local l = Instance.new("UIListLayout", f)
        l.Padding = UDim.new(0, 8)

        return f
    end

    -- [ 1. INFO UTAMA (Besar & Jelas) ]
    local MainSection = CreateSection("MAIN", true)
    
    local function AddText(parent, text, size, color, bold)
        local t = Instance.new("TextLabel", parent)
        t.BackgroundTransparency = 1
        t.Size = UDim2.new(1, 0, 0, size + 4)
        t.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
        t.Text = text
        t.TextSize = size
        t.TextColor3 = color
        t.TextXAlignment = Enum.TextXAlignment.Left
        return t
    end

    local UserLbl = AddText(MainSection, "👤 @" .. playerName, 24, Color3.fromRGB(0, 200, 255), true)
    local StarterMoneyLbl = AddText(MainSection, "📥 Starting: Rp. 0", 18, Color3.fromRGB(200, 200, 200), false)
    local CurrentMoneyLbl = AddText(MainSection, "💰 Current: Rp. 0", 32, Color3.fromRGB(255, 255, 255), true)

    -- [ 2. SUB INFO (Lebih Kecil / Rinci) ]
    local SubSection = CreateSection("SUB", false)
    
    local AvgLbl = AddText(SubSection, "⚡ Earn/h: Calculating...", 16, Color3.fromRGB(0, 255, 150), false)
    local EstLbl = AddText(SubSection, "🎯 Estimation: --", 16, Color3.fromRGB(255, 200, 0), false)
    local RuntimeLbl = AddText(SubSection, "⏱️ Runtime: 00:00:00", 16, Color3.fromRGB(255, 255, 255), false)
    local StatusLbl = AddText(SubSection, "🛡️ System: Running Smoothly", 14, Color3.fromRGB(150, 150, 150), false)

    -- [ FOOTER ]
    local Footer = AddText(CenterFrame, "PRESS 'K' TO HIDE DASHBOARD", 12, Color3.fromRGB(100, 100, 100), false)
    Footer.TextXAlignment = Enum.TextXAlignment.Center

    -- [ TOGGLE LOGIC ]
    -- Agar user bisa buka tutup dashboard dengan tombol keyboard
    game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.K then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    -- Return labels yang perlu diupdate oleh Engine
    return ScreenGui, {
        CurrentMoney = CurrentMoneyLbl,
        StarterMoney = StarterMoneyLbl,
        Avg = AvgLbl,
        Estimation = EstLbl,
        Runtime = RuntimeLbl,
        Status = StatusLbl
    }
end

return HUD
