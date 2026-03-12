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
                task.wait(0.1)
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
            task.wait(0.5)
            if game.Workspace:FindFirstChild("AntiVoidBase_DDS") then
                game.Workspace.AntiVoidBase_DDS:Destroy()
            end
            local base = Instance.new("Part")
            base.Name = "AntiVoidBase_DDS"
            base.Size = Vector3.new(8000, 1, 8000)
            base.Position = root.Position - Vector3.new(0, 25, 0)
            base.Anchored = true
            base.Transparency = 0.8
            base.BrickColor = BrickColor.new("Electric blue")
            base.Material = Enum.Material.Neon
            base.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
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

    if not root or not hum then return warn("❌ Karakter belum siap.") end

    local motorModel = nil
    for _, obj in pairs(workspace:GetChildren()) do
        if string.find(obj.Name, pattern) then
            motorModel = obj
            break
        end
    end

    if motorModel then
        local driveSeat = motorModel:FindFirstChild("DriveSeat") or motorModel:FindFirstChildWhichIsA("VehicleSeat", true)
        if driveSeat then
            pcall(function() driveSeat:SetNetworkOwner(player) end)
            root.CFrame = driveSeat.CFrame
            task.wait(0.1)

            local prompt = driveSeat:FindFirstChildOfClass("ProximityPrompt") or driveSeat:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.05)
                prompt:InputHoldEnd()
            end
            if not hum.Sit then driveSeat:Sit(hum) end
            print("✅ Motor Mounted.")
        else
            warn("❌ Seat tidak ditemukan.")
        end
    else
        warn("❌ Motor belum spawn.")
    end
end

-- [ SYSTEM: CLEAR WORLD ]
function Engine:ClearWorld(player)
    for _, obj in ipairs(game.Workspace:GetChildren()) do
        if obj:IsA("Terrain") or obj:IsA("Camera") or obj.Name == player.Name or obj.Name == "AntiVoidBase_DDS" then 
            continue 
        end
        if string.find(obj.Name, "Montors") then continue end
        pcall(function() obj:Destroy() end)
    end
end

-- [ SYSTEM: CRUISE LOGIC - 0 to MAX then CYCLE ]
function Engine:RunCruise(player, config)
    local angle = math.random() * math.pi * 2
    local MIN_SPEED = 200
    local MAX_SPEED = 249
    local ACCEL_DURATION = 12 -- Durasi awal 0 ke 249
    local startTime = tick() 
    
    local lastNoiseUpdate = 0
    local currentNoise = 0
    
    return game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not config.IsActive() then 
            startTime = tick() 
            return 
        end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        
        -- Auto Re-Sit
        if hum and not seat then
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
        
        hum.Sit = true

        -- LOGIKA KECEPATAN (START 0 -> MAX -> CYCLE 200-249)
        local elapsed = tick() - startTime
        local finalSpeed = 0

        if elapsed < ACCEL_DURATION then
            -- FASE 1: Akselerasi Awal (0 ke 249)
            local alpha = elapsed / ACCEL_DURATION
            finalSpeed = alpha * MAX_SPEED
        else
            -- FASE 2: Siklus (Naik-Turun 200 ke 249)
            -- Kecepatan siklus diatur oleh tick() * 0.5 (bisa dipercepat/lambat)
            local cycleAlpha = (math.sin(tick() * 0.5) + 1) / 2
            finalSpeed = MIN_SPEED + (cycleAlpha * (MAX_SPEED - MIN_SPEED))
        end
        
        -- NOISE JITTER (Agar data tidak terbaca statis oleh server)
        if tick() - lastNoiseUpdate > 0.3 then
            currentNoise = math.random(-2500, 2500) / 1000 
            lastNoiseUpdate = tick()
        end

        finalSpeed = finalSpeed + currentNoise
        
        -- Anti-Cheat Safety Clamp
        if finalSpeed > MAX_SPEED then 
            finalSpeed = MAX_SPEED - math.random(1, 3) 
        end

        -- GERAKAN DINAMIS (Radius Lingkaran Goyang)
        local dynamicRadius = 2250 + (math.sin(tick() * 0.2) * 250)
        angle += 0.4 * dt 
        local move = Vector3.new(math.cos(angle), 0, math.sin(angle))
        
        -- Boundary Check (Smooth Turn ke tengah)
        local currentPosXZ = Vector3.new(motorRoot.Position.X, 0, motorRoot.Position.Z)
        if currentPosXZ.Magnitude > dynamicRadius then
            move = move:Lerp((-currentPosXZ).Unit, 0.05)
        end
        
        -- EKSEKUSI PHYSICS
        local targetY = (typeof(config.LockY) == "function" and config.LockY()) or config.LockY or motorRoot.Position.Y
        motorRoot.AssemblyLinearVelocity = (move * finalSpeed) + Vector3.new(0, (targetY - motorRoot.Position.Y) * 35, 0)
        motorRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0) 
    end)
end

return Engine
