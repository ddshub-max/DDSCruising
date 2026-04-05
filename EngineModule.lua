local Engine = {}

-- [ SYSTEM: ANTI-AFK STEALTH ]
-- Menggunakan simulasi input yang lebih acak untuk menghindari deteksi pola
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
                local VU = game:GetService("VirtualUser")
                VU:CaptureController()
                VU:ClickButton2(Vector2.new(math.random(1,10), math.random(1,10)))
            end)
        end
    end)

    task.spawn(function()
        local VU = game:GetService("VirtualUser")
        while task.wait(math.random(15, 35)) do 
            pcall(function()
                VU:CaptureController()
                -- Menggunakan sedikit variasi tombol agar terlihat seperti aktivitas manusia
                VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(math.random(1, 5) / 10)
                VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end)
    warn("✅ [Engine] Anti-AFK Stealth Mode Active.")
end

-- [ SYSTEM: ANTI-VOID BASE ]
function Engine:CreateAntiVoid(player)
    local function setup(char)
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if root then
            task.wait(1)
            -- Ganti nama part agar tidak mencurigakan jika discan server
            if game.Workspace:FindFirstChild("GlassFloor_System") then
                game.Workspace.GlassFloor_System:Destroy()
            end
            local base = Instance.new("Part")
            base.Name = "GlassFloor_System" 
            base.Size = Vector3.new(5000, 1, 5000)
            base.Position = root.Position - Vector3.new(0, 25, 0)
            base.Anchored = true
            base.Transparency = 0.8
            base.BrickColor = BrickColor.new("Institutional white")
            base.Material = Enum.Material.Glass
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

    if not root or not hum then return warn("❌ Character not ready.") end

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
            pcall(function()
                if driveSeat.NetworkOwner ~= player then
                    driveSeat:SetNetworkOwner(player)
                end
            end)

            root.CFrame = driveSeat.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.2)

            local prompt = driveSeat:FindFirstChildOfClass("ProximityPrompt") or driveSeat:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            if prompt then
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.05)
                prompt:InputHoldEnd()
            else
                driveSeat:Sit(hum)
            end

            -- Force Sit Loop
            task.spawn(function()
                for i = 1, 5 do
                    if not hum.Sit then driveSeat:Sit(hum) end
                    task.wait(0.5)
                end
            end)
        end
    end
end

-- [ SYSTEM: CLEAR WORLD (OPTIMIZED) ]
function Engine:ClearWorld(player)
    for _, obj in ipairs(game.Workspace:GetChildren()) do
        if obj:IsA("Terrain") or obj:IsA("Camera") or obj.Name == player.Name or obj.Name == "AntiVoidBase_DDS" then 
            continue 
        end
        if string.find(obj.Name, "Montors") then continue end
        pcall(function() obj:Destroy() end)
    end
end

-- [ SYSTEM: CRUISE LOGIC - BYPASS VERSION ]
function Engine:RunCruise(player, config)
    local speed = 0
    local angle = math.random() * math.pi * 2
    local lastY = 0
    
    return game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not config.IsActive() then return end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        
        if hum and not seat then
            -- Auto Re-Sit
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
        
        local motorRoot = (seat and seat:FindFirstAncestorOfClass("Model") and seat.Parent.PrimaryPart) or seat
        if not motorRoot then return end

        -- 1. Velocity Jitter (Mengacak kecepatan sedikit agar tidak flat 250)
        local baseSpeed = math.random(225, 248)
        speed = speed + (baseSpeed - speed) * 0.1 

        -- 2. Smooth Movement (Menambah noise agar belokan tidak matematis sempurna)
        local noise = math.noise(tick() * 0.4) * 0.1
        angle += (0.35 + noise) * dt
        local move = Vector3.new(math.cos(angle), 0, math.sin(angle))
        
        -- 3. Boundary Control
        if Vector3.new(motorRoot.Position.X, 0, motorRoot.Position.Z).Magnitude > 2200 then
            move = move:Lerp((-Vector3.new(motorRoot.Position.X, 0, motorRoot.Position.Z)).Unit, 0.1)
        end
        
        -- 4. Dynamic Y-Lock (Mencegah deteksi 'Static Position')
        local targetY = (typeof(config.LockY) == "function" and config.LockY()) or config.LockY or motorRoot.Position.Y
        -- Tambahkan osilasi halus (meniru gerakan melayang yang natural)
        local hover = math.sin(tick() * 2) * 0.2
        local velocityY = (targetY + hover - motorRoot.Position.Y) * 30
        
        -- 5. Final Execution
        motorRoot.AssemblyLinearVelocity = (move * speed) + Vector3.new(0, math.clamp(velocityY, -40, 40), 0)
        
        -- Beri sedikit rotasi agar physics mesin tetap update di server
        motorRoot.AssemblyAngularVelocity = Vector3.new(0, 0.05, 0)
        
        if hum.Sit == false then hum.Sit = true end
    end)
end

return Engine
