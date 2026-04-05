local Engine = {}

-- [ SYSTEM: CLEAR SAFE WORLD ]
-- Membersihkan part lama agar tidak menumpuk dan tidak dicurigai server
function Engine:ClearSafeWorld()
    pcall(function()
        for _, v in pairs(game.Workspace:GetChildren()) do
            if v.Name == "AntiVoidBase_DDS" or v:FindFirstChild("IsEnginePart") then
                v:Destroy()
            end
        end
    end)
    warn("🧹 [Engine] Workspace Cleared.")
end

-- [ SYSTEM: ANTI-AFK BYPASS ]
-- Menggunakan VirtualInputManager karena VirtualUser sering di-flag oleh anticheat baru
function Engine:InitAntiAFK(player)
    local VIM = game:GetService("VirtualInputManager")
    
    pcall(function()
        local GC = getconnections or get_signal_cons
        if GC then
            for _, v in pairs(GC(player.Idled)) do
                if v["Disable"] then v["Disable"](v) 
                elseif v["Disconnect"] then v["Disconnect"](v) end
            end
        end
    end)

    task.spawn(function()
        while task.wait(math.random(20, 40)) do
            pcall(function()
                -- Mengirim input ringan agar server menganggap player aktif
                VIM:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game)
            end)
        end
    end)
    warn("✅ [Engine] Anti-AFK Active (Stealth Mode).")
end

-- [ SYSTEM: ANTI-VOID BASE ]
function Engine:CreateAntiVoid(player)
    self:ClearSafeWorld() -- Pastikan bersih sebelum membuat baru
    
    local function setup(char)
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if root then
            task.wait(1)
            if game.Workspace:FindFirstChild("AntiVoidBase_DDS") then
                game.Workspace.AntiVoidBase_DDS:Destroy()
            end
            local base = Instance.new("Part")
            base.Name = "AntiVoidBase_DDS"
            base.Size = Vector3.new(10000, 5, 10000) -- Lebih lebar untuk safety
            -- Posisi sedikit lebih jauh di bawah untuk menghindari raycast anticheat
            base.Position = root.Position - Vector3.new(0, 35, 0) 
            base.Anchored = true
            base.Transparency = 1 -- Full transparan agar tidak di-report admin/player
            base.CanCollide = true
            base.Material = Enum.Material.ForceField
            
            -- Penanda untuk pembersihan otomatis
            local tag = Instance.new("BoolValue", base)
            tag.Name = "IsEnginePart"
            
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
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.1)
                    prompt:InputHoldEnd()
                end
            else
                driveSeat:Sit(hum)
            end

            task.spawn(function()
                for i = 1, 5 do
                    if not hum.Sit then driveSeat:Sit(hum) end
                    task.wait(0.5)
                end
            end)
        end
    end
end

-- [ SYSTEM: CRUISE LOGIC BYPASS ]
function Engine:RunCruise(player, config)
    local currentSpeed = 0
    local angle = math.random() * math.pi * 2
    local runService = game:GetService("RunService")
    
    return runService.Heartbeat:Connect(function(dt)
        if not config.IsActive() then return end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        
        if not seat then
            self:RideMotor(player)
            return 
        end
        
        local motor = seat:FindFirstAncestorOfClass("Model")
        local motorRoot = (motor and motor.PrimaryPart) or seat
        if not motorRoot then return end

        -- 1. Dinamika Kecepatan (Pola Non-Linear agar tidak terdeteksi bot)
        -- Menggunakan Perlin Noise untuk fluktuasi kecepatan yang natural
        local noise = math.noise(tick() * 0.5) * 25
        local targetMax = config.MaxSpeed or 220
        local targetMin = config.MinSpeed or 180
        local dynamicTarget = ((targetMax + targetMin) / 2) + noise
        
        currentSpeed = currentSpeed + (dynamicTarget - currentSpeed) * (dt * 1.5)

        -- 2. Arah Lingkaran
        angle += (0.15 * dt)
        local moveVector = Vector3.new(math.cos(angle), 0, math.sin(angle))
        
        -- 3. Boundary Control (Radius 1500)
        local posXZ = Vector3.new(motorRoot.Position.X, 0, motorRoot.Position.Z)
        if posXZ.Magnitude > 1500 then
            moveVector = moveVector:Lerp(-posXZ.Unit, 0.15)
        end
        
        -- 4. Hybrid Execution (CFrame + Velocity)
        -- Menggunakan CFrame Lerp untuk posisi presisi (Anti-Bounce)
        -- Dan memberikan sedikit Velocity asli agar physics server tetap sinkron
        local targetY = (typeof(config.LockY) == "function" and config.LockY()) or config.LockY or motorRoot.Position.Y
        local nextPosition = motorRoot.Position + (moveVector * currentSpeed * dt)
        
        -- Lock rotasi dan posisi secara halus
        local targetCF = CFrame.new(Vector3.new(nextPosition.X, targetY, nextPosition.Z), 
                                    Vector3.new(nextPosition.X + moveVector.X, targetY, nextPosition.Z + moveVector.Z))
        
        motorRoot.CFrame = motorRoot.CFrame:Lerp(targetCF, 0.2)
        
        -- Set Velocity rendah agar physics tidak "stuck" tapi tidak memicu anticheat kecepatan tinggi
        motorRoot.AssemblyLinearVelocity = moveVector * 10 
        motorRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        if hum.Sit == false then hum.Sit = true end
    end)
end

return Engine
