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
    warn("✅ [Engine] Anti-AFK Active.")
end

-- [ SYSTEM: ANTI-VOID BASE ]
function Engine:CreateAntiVoid(player)
    local function setup(char)
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if root then
            task.wait(1)
            if game.Workspace:FindFirstChild("AntiVoidBase_DDS") then
                game.Workspace.AntiVoidBase_DDS:Destroy()
            end
            local base = Instance.new("Part")
            base.Name = "AntiVoidBase_DDS"
            base.Size = Vector3.new(5000, 2, 5000) -- Sedikit lebih tebal
            base.Position = root.Position - Vector3.new(0, 25, 0)
            base.Anchored = true
            base.Transparency = 0.8
            base.BrickColor = BrickColor.new("Electric blue")
            base.Material = Enum.Material.ForceField -- Material ForceField lebih ringan dirender
            base.Parent = game.Workspace
        end
    end
    player.CharacterAdded:Connect(setup)
    if player.Character then task.spawn(setup, player.Character) end
end

-- [ SYSTEM: RIDE MOTOR ]
function Engine:RideMotor(player)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    local pattern = player.Name .. "Montors"

    if not root or not hum then return warn("❌ Character belum siap.") end

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
                -- Tambahkan sedikit randomness agar tidak terdeteksi botting prompt
                task.wait(prompt.HoldDuration + math.random(1, 5)/10)
                prompt:InputHoldEnd()
            else
                driveSeat:Sit(hum)
            end

            -- Safety Sit Loop
            task.spawn(function()
                for i = 1, 5 do
                    if not hum.Sit then driveSeat:Sit(hum) end
                    task.wait(0.5)
                end
            end)
        end
    end
end

-- [ SYSTEM: CRUISE LOGIC ]
function Engine:RunCruise(player, config)
    local currentSpeed = 0
    local angle = math.random() * math.pi * 2
    local runService = game:GetService("RunService")
    
    return runService.Heartbeat:Connect(function(dt)
        if not config.IsActive() then return end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        
        if hum and not seat then
            -- Auto Re-sit logic
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

        -- 1. Logika Kecepatan Adaptif (Mencegah deteksi kecepatan konstan)
        -- Target antara 180 - 230 (lebih aman daripada 250+)
        local targetMax = config.MaxSpeed or 220
        local targetMin = config.MinSpeed or 180
        local wave = math.sin(tick() * 0.5) * 20 -- Variasi 20 unit
        local dynamicTarget = (targetMax + targetMin) / 2 + wave
        
        -- Lerp kecepatan agar akselerasi halus (tidak instan)
        currentSpeed = currentSpeed + (dynamicTarget - currentSpeed) * (dt * 2)

        -- 2. Logika Arah Lingkaran (Circular Movement)
        angle += (0.25 * dt) -- Kecepatan putar
        local moveVector = Vector3.new(math.cos(angle), 0, math.sin(angle))
        
        -- 3. Boundary Control (Radius 1500 agar tidak terlalu jauh)
        local posXZ = Vector3.new(motorRoot.Position.X, 0, motorRoot.Position.Z)
        if posXZ.Magnitude > 1500 then
            moveVector = moveVector:Lerp(-posXZ.Unit, 0.1)
        end
        
        -- 4. Y-Level Smoothing (Anti-Bounce)
        local targetY = (typeof(config.LockY) == "function" and config.LockY()) or config.LockY or motorRoot.Position.Y
        local yError = targetY - motorRoot.Position.Y
        local yVelocity = math.clamp(yError * 10, -30, 30) -- Power 10 lebih halus dari 40

        -- 5. Eksekusi Velocity dengan Lerp
        local finalVelocity = (moveVector * currentSpeed) + Vector3.new(0, yVelocity, 0)
        
        -- Menggunakan Lerp pada Velocity agar transisi antar frame tidak patah-patah
        motorRoot.AssemblyLinearVelocity = motorRoot.AssemblyLinearVelocity:Lerp(finalVelocity, 0.3)
        
        -- Kunci rotasi agar tidak guling
        motorRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        -- Paksa karakter tetap duduk
        if hum.Sit == false then hum.Sit = true end
    end)
end

return Engine
