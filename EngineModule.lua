local Engine = {}

-- [ SYSTEM: ANTI-AFK ]
function Engine:InitAntiAFK(player)
    pcall(function()
        local GC = getconnections or get_signal_cons
        if GC then
            for _, v in pairs(GC(player.Idled)) do
                if v["Disable"] then v["Disable"](v) 
                elseif v["Disconnect"] then v["Disconnect"](v) end
            end
        else
            player.Idled:Connect(function() 
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new(0,0))
            end)
        end
    end)

    task.spawn(function()
        local VU = game:GetService("VirtualUser")
        while task.wait(math.random(15, 30)) do
            pcall(function()
                VU:CaptureController()
                VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(math.random(1, 3) / 10)
                VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end)
end

-- [ SYSTEM: ANTI-VOID ]
function Engine:CreateAntiVoid(player)
    local function setup(char)
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if root then
            if game.Workspace:FindFirstChild("AntiVoidBase_DDS") then
                game.Workspace.AntiVoidBase_DDS:Destroy()
            end
            local base = Instance.new("Part")
            base.Name = "AntiVoidBase_DDS"
            base.Size = Vector3.new(6000, 2, 6000)
            base.Position = root.Position - Vector3.new(0, 30, 0)
            base.Anchored = true
            base.Transparency = 1 -- Buat sepenuhnya transparan agar tidak mencolok
            base.Parent = game.Workspace
        end
    end
    player.CharacterAdded:Connect(setup)
    if player.Character then task.spawn(setup, player.Character) end
end

-- [ SYSTEM: CRUISE LOGIC - BYPASS VERSION ]
function Engine:RunCruise(player, config)
    local currentSpeed = 0
    local angle = math.random() * math.pi * 2
    local lastStutter = tick()
    local stutterDuration = 0
    
    return game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not config.IsActive() then return end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        
        if not seat then return end
        
        local motor = seat:FindFirstAncestorOfClass("Model")
        local motorRoot = (motor and motor.PrimaryPart) or seat
        if not motorRoot then return end

        -- 1. EFEK STUTTER (PENTING): Berhenti sejenak setiap 45-60 detik
        -- Ini memutus catatan "Constant Speed" di server
        if tick() - lastStutter > math.random(45, 60) then
            stutterDuration = math.random(1, 3) -- Berhenti 1-3 detik
            lastStutter = tick()
        end

        if stutterDuration > 0 then
            stutterDuration -= dt
            motorRoot.AssemblyLinearVelocity = motorRoot.AssemblyLinearVelocity:Lerp(Vector3.new(0, -1, 0), 0.1)
            return
        end

        -- 2. DYNAMIC SPEED (Sering Berubah)
        local baseTarget = config.Speed or 190
        local noise = math.sin(tick() * 2) * 30 -- Naik turun 30 studs
        local targetSpeed = baseTarget + noise
        currentSpeed = currentSpeed + (targetSpeed - currentSpeed) * 0.05

        -- 3. RANDOMIZED PATHING
        -- Menambahkan noise pada sudut putar agar tidak membentuk lingkaran sempurna
        local angleNoise = math.sin(tick() * 0.1) * 0.05
        angle += (0.3 + angleNoise) * dt
        local moveVector = Vector3.new(math.cos(angle), 0, math.sin(angle))
        
        -- 4. BOUNDARY & Y-AXIS (Slightly Wobbling)
        local targetY = (typeof(config.LockY) == "function" and config.LockY()) or config.LockY or motorRoot.Position.Y
        -- Tambahkan goyangan vertikal kecil (seperti bernapas)
        targetY = targetY + (math.sin(tick() * 1.5) * 1.5)
        
        local yVelocity = math.clamp((targetY - motorRoot.Position.Y) * 8, -40, 40)

        -- 5. APPLY VELOCITY
        local finalVel = (moveVector * currentSpeed) + Vector3.new(0, yVelocity, 0)
        motorRoot.AssemblyLinearVelocity = motorRoot.AssemblyLinearVelocity:Lerp(finalVel, 0.2)
        motorRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        -- Anti-Sit Bug
        if hum.Sit == false then hum.Sit = true end
    end)
end

return Engine
