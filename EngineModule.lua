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
        while task.wait(math.random(20, 40)) do
            pcall(function()
                VU:CaptureController()
                VU:Button2Down(Vector2.new(math.random(1, 10), math.random(1, 10)), workspace.CurrentCamera.CFrame)
                task.wait(math.random(1, 4) / 10)
                VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end)
    warn("✅ [Engine] Anti-AFK Active.")
end

-- [ SYSTEM: ANTI-VOID / SAFE PART ]
function Engine:CreateAntiVoid(player)
    local function setup(char)
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if root then
            task.wait(1)
            -- Hapus base lama jika ada
            if game.Workspace:FindFirstChild("AntiVoidBase_DDS") then
                game.Workspace.AntiVoidBase_DDS:Destroy()
            end
            
            -- Membuat Platform Aman (Safe Part)
            local base = Instance.new("Part")
            base.Name = "AntiVoidBase_DDS"
            base.Size = Vector3.new(10000, 2, 10000) -- Sangat luas agar tidak jatuh
            base.Position = root.Position - Vector3.new(0, 35, 0) -- Di bawah karakter
            base.Anchored = true
            base.Transparency = 1 -- Tidak terlihat
            base.CanCollide = true
            base.Material = Enum.Material.Glass
            base.Parent = game.Workspace
            warn("✅ [Engine] Safe Part Created.")
        end
    end
    player.CharacterAdded:Connect(setup)
    if player.Character then task.spawn(setup, player.Character) end
end

-- [ SYSTEM: CLEAR WORLD ]
-- Menghapus objek Workspace untuk mengurangi lag & deteksi visual
function Engine:ClearWorld(player)
    pcall(function()
        for _, obj in ipairs(game.Workspace:GetChildren()) do
            -- Jangan hapus hal penting
            if obj:IsA("Terrain") or obj:IsA("Camera") or obj.Name == player.Name or obj.Name == "AntiVoidBase_DDS" then 
                continue 
            end
            -- Jangan hapus motor sendiri
            if string.find(obj.Name, "Montors") then continue end
            
            -- Hapus sisanya
            obj:Destroy()
        end
    end)
    warn("✅ [Engine] World Cleared.")
end

-- [ SYSTEM: RIDE MOTOR ]
function Engine:RideMotor(player)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    local pattern = player.Name .. "Montors"

    if not root or not hum then return end

    local motorModel = nil
    for _, obj in pairs(workspace:GetChildren()) do
        if string.find(obj.Name, pattern) then
            motorModel = obj
            break
        end
    end

    if motorModel then
        local driveSeat = motorModel:FindFirstChildWhichIsA("VehicleSeat", true)
        if driveSeat then
            pcall(function() driveSeat:SetNetworkOwner(player) end)
            root.CFrame = driveSeat.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.5)

            local prompt = driveSeat:FindFirstChildOfClass("ProximityPrompt") or driveSeat:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + math.random(1, 5)/10)
                prompt:InputHoldEnd()
            else
                driveSeat:Sit(hum)
            end
        end
    end
end

-- [ SYSTEM: CRUISE LOGIC - BYPASS VERSION ]
function Engine:RunCruise(player, config)
    local speedVar = 0
    local angle = math.random() * math.pi * 2
    local lastReset = tick()
    local isResting = false
    local restTime = 0
    
    return game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not config.IsActive() then return end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        
        if not seat then
            local pattern = player.Name .. "Montors"
            for _, obj in pairs(workspace:GetChildren()) do
                if string.find(obj.Name, pattern) then
                    local s = obj:FindFirstChildWhichIsA("VehicleSeat", true)
                    if s then s:Sit(hum) end
                    break
                end
            end
            return 
        end
        
        local motor = seat:FindFirstAncestorOfClass("Model")
        local motorRoot = (motor and motor.PrimaryPart) or seat
        if not motorRoot then return end

        -- 1. BREAK LOGIC: Berhenti sejenak setiap 3-5 menit (Reset Heuristics)
        if not isResting and tick() - lastReset > math.random(180, 300) then
            isResting = true
            restTime = math.random(4, 8)
            lastReset = tick()
        end

        if isResting then
            restTime -= dt
            motorRoot.AssemblyLinearVelocity = motorRoot.AssemblyLinearVelocity:Lerp(Vector3.new(0, -1, 0), 0.05)
            if restTime <= 0 then isResting = false end
            return
        end

        -- 2. DYNAMIC SPEED (180 - 210 KM/H)
        local baseSpeed = config.Speed or 185
        local sineWave = math.sin(tick() * 0.8) * 20
        speedVar = speedVar + ((baseSpeed + sineWave) - speedVar) * 0.1

        -- 3. HUMANIZED DIRECTION (Anti-Circular Detection)
        local drift = math.sin(tick() * 0.2) * 0.1
        angle += (0.28 + drift) * dt
        local moveDirection = Vector3.new(math.cos(angle), 0, math.sin(angle))
        
        -- 4. Y-AXIS STABILIZER & VERTICAL BREATHE
        local targetY = (typeof(config.LockY) == "function" and config.LockY()) or config.LockY or motorRoot.Position.Y
        local verticalJitter = math.sin(tick() * 1.5) * 1.5 -- Goyangan naik turun halus
        local yVelocity = math.clamp(((targetY + verticalJitter) - motorRoot.Position.Y) * 10, -40, 40)

        -- 5. APPLY VELOCITY
        local targetVelocity = (moveDirection * speedVar) + Vector3.new(0, yVelocity, 0)
        motorRoot.AssemblyLinearVelocity = motorRoot.AssemblyLinearVelocity:Lerp(targetVelocity, 0.15)
        
        motorRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        if not hum.Sit then hum.Sit = true end
    end)
end

return Engine
