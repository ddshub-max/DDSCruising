local HUD = {}

function HUD:Create(playerName)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DDS_IndependentHUD"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = false
    ScreenGui.Parent = (game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui"))

    local HUDFrame = Instance.new("Frame")
    HUDFrame.Size = UDim2.new(0, 250, 0, 100)
    HUDFrame.Position = UDim2.new(0.5, -100, 0.05, 0)
    HUDFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    HUDFrame.BackgroundTransparency = 0.3
    HUDFrame.BorderSizePixel = 0
    HUDFrame.Active = true
    HUDFrame.Parent = ScreenGui

    Instance.new("UICorner", HUDFrame).CornerRadius = UDim.new(0, 12)
    local Stroke = Instance.new("UIStroke", HUDFrame)
    Stroke.Thickness, Stroke.Color, Stroke.Transparency = 2, Color3.fromRGB(0, 170, 255), 0.4

    local function CreateLabel(name, pos, size, font, color, text, bold)
        local l = Instance.new("TextLabel", HUDFrame)
        l.Name, l.Position, l.Size, l.Font = name, pos, size, (bold and Enum.Font.GothamBold or Enum.Font.GothamMedium)
        l.TextColor3, l.Text, l.TextScaled = color, text, true
        l.BackgroundTransparency, l.TextXAlignment = 1, Enum.TextXAlignment.Left
        return l
    end

    local UserL = CreateLabel("User", UDim2.new(0,10,0,28), UDim2.new(1,-20,0,35), nil, Color3.fromRGB(255,255,255), "@"..playerName, false)
    local MoneyL = CreateLabel("Money", UDim2.new(0,10,0,28), UDim2.new(1,-20,0,35), nil, Color3.fromRGB(255,255,255), "💰 Rp. 0", true)
    local AvgL = CreateLabel("Avg", UDim2.new(0,10,0,65), UDim2.new(1,-20,0,25), nil, Color3.fromRGB(0,255,180), "⚡ 0 / hr", false)

    -- Drag Logic
    local dragging, dragInput, dragStart, startPos
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
