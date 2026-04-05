local Engine = {}

-- [ SYSTEM: ANTI-AFK ]
-- Menggunakan simulasi input yang lebih acak agar tidak terbaca sebagai botting sederhana
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
        while task.wait(math.random(15, 45)) do
            pcall(function()
                VU:CaptureController()
                -- Simulasi klik kanan acak
                VU:Button2Down(Vector2.new(math.random(1,10), math.random(1,10)), workspace.CurrentCamera.CFrame)
                task.wait(math.random(1, 4) / 10)
                VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end)
    warn("✅ [Engine] Anti-AFK & Pattern Randomizer Active.")
end

-- [ SYSTEM: ANTI-VOID ]
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
            base.Size = Vector3.new(8000, 2, 8000) -- Area lebih luas
            base.Position = root.Position - Vector3.new(0, 35, 0) -- Lebih dalam agar tidak terlihat dari permukaan
            base.Anchored = true
            base.Transparency = 1 -- Fully invisible
            base.CanCollide = true
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
            -- Klaim kendali fisik motor
            pcall(function() driveSeat:SetNetworkOwner(player) end)
            
            root.CFrame = driveSeat.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.4)

            local prompt = driveSeat:FindFirstChildOfClass("ProximityPrompt") or driveSeat:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            if prompt then
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + math.random(1, 4)/10)
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
        
        -- Auto Re-Sit
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

        -- 1. BREAK LOGIC (PENTING): Berhenti sejenak setiap beberapa menit
        -- Ini merusak pola deteksi "Constant Movement"
        if not isResting and tick() - lastReset > math.random(180, 300) then
            isResting = true
            restTime = math.random(3, 7) -- Diam selama 3-7 detik
            lastReset = tick()
        end

        if isResting then
            restTime -= dt
            motorRoot.AssemblyLinearVelocity = motorRoot.AssemblyLinearVelocity:Lerp(Vector3.new(0, -1, 0), 0.05)
            if restTime <= 0 then isResting = false end
            return
        end

        -- 2. DYNAMIC SPEED (160 - 210 KM/H)
        -- Jangan gunakan angka konstan. Gunakan gelombang Sine untuk variasi.
        local baseSpeed = config.Speed or 185
        local sineWave = math.sin(tick() * 0.8) * 25 
        speedVar = speedVar + ((baseSpeed + sineWave) - speedVar) * 0.1

        -- 3. HUMANIZED DIRECTION
        -- Menambahkan noise pada sudut belok agar tidak berbentuk lingkaran sempurna
        local drift = math.sin(tick() * 0.2) * 0.1
        angle += (0.28 + drift) * dt
        local moveDirection = Vector3.new(math.cos(angle), 0, math.sin(angle))
        
        -- 4. Y-AXIS STABILIZER & JITTER
        local targetY = (typeof(config.LockY) == "function" and config.LockY()) or config.LockY or motorRoot.Position.Y
        -- Menambahkan "Vertical Breathing" agar posisi Y tidak kaku (bypass Fly-check)
        local verticalJitter = math.sin(tick() * 2) * 1.2
        local yVelocity = math.clamp(( (targetY + verticalJitter) - motorRoot.Position.Y) * 12, -45, 45)

        -- 5. FINAL EXECUTION (LERP)
        -- Menggunakan Lerp 0.15 agar perubahan arah terasa halus seperti dikendarai manusia
        local targetVelocity = (moveDirection * speedVar) + Vector3.new(0, yVelocity, 0)
        motorRoot.AssemblyLinearVelocity = motorRoot.AssemblyLinearVelocity:Lerp(targetVelocity, 0.15)
        
        -- Kunci rotasi motor agar tetap stabil
        motorRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        -- Paksa status duduk
        if not hum.Sit then hum.Sit = true end
    end)
end

return Engine
