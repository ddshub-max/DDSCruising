local HUD = {}

function HUD:Create(playerName)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DDS_IndependentHUD"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = true -- Set ke true untuk testing
    ScreenGui.Parent = (game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui"))

    local HUDFrame = Instance.new("Frame")
    HUDFrame.Size = UDim2.new(0, 220, 0, 0) -- Tinggi 0 karena akan pakai AutomaticSize
    HUDFrame.Position = UDim2.new(0.5, -110, 0.05, 0)
    HUDFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    HUDFrame.BackgroundTransparency = 0.2
    HUDFrame.BorderSizePixel = 0
    HUDFrame.Active = true
    HUDFrame.AutomaticSize = Enum.AutomaticSize.Y -- Frame memanjang otomatis sesuai isi
    HUDFrame.Parent = ScreenGui

    Instance.new("UICorner", HUDFrame).CornerRadius = UDim.new(0, 10)
    local Stroke = Instance.new("UIStroke", HUDFrame)
    Stroke.Thickness, Stroke.Color, Stroke.Transparency = 2, Color3.fromRGB(0, 170, 255), 0.5

    -- Tambahkan UIListLayout
    local ListLayout = Instance.new("UIListLayout", HUDFrame)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 5) -- Jarak antar label

    -- Tambahkan UIPadding supaya teks tidak nempel ke pinggir frame
    local UIPadding = Instance.new("UIPadding", HUDFrame)
    UIPadding.PaddingLeft = UDim.new(0, 12)
    UIPadding.PaddingRight = UDim.new(0, 12)
    UIPadding.PaddingTop = UDim.new(0, 10)
    UIPadding.PaddingBottom = UDim.new(0, 10)

    local function CreateLabel(name, text, color, bold, order)
        local l = Instance.new("TextLabel", HUDFrame)
        l.Name = name
        l.Size = UDim2.new(1, 0, 0, 25) -- Lebar penuh, tinggi tetap 25px
        l.Font = (bold and Enum.Font.GothamBold or Enum.Font.GothamMedium)
        l.TextColor3 = color
        l.Text = text
        l.TextSize = 14 -- Lebih konsisten daripada TextScaled untuk HUD kecil
        l.BackgroundTransparency = 1
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = order -- Menentukan urutan atas ke bawah
        return l
    end

    -- Urutan: Nama User (0), Money (1), Average (2)
    local UserL = CreateLabel("User", "@" .. playerName, Color3.fromRGB(200, 200, 200), false, 0)
    local MoneyL = CreateLabel("Money", "💰 Rp. 0", Color3.fromRGB(255, 255, 255), true, 1)
    local AvgL = CreateLabel("Avg", "⚡ 0 / hr", Color3.fromRGB(0, 255, 180), false, 2)

    -- Drag Logic (Tetap sama)
    local dragging, dragStart, startPos
    HUDFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = HUDFrame.Position
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            HUDFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(input) dragging = false end)

    return ScreenGui, MoneyL, AvgL
end

return HUD
