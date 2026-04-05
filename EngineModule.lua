local Engine = {}

-- [ SYSTEM: ANTI-AFK STEALTH ]
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
                game:GetService("VirtualUser"):ClickButton2(Vector2.new(math.random(1,20), math.random(1,20)))
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
end

-- [ SYSTEM: ANTI-VOID BASE ]
function Engine:CreateAntiVoid(player)
    local function setup(char)
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if root then
            task.wait(1)
            if game.Workspace:FindFirstChild("System_Base_V2") then
                game.Workspace.System_Base_V2:Destroy()
            end
            local base = Instance.new("Part")
            base.Name = "System_Base_V2"
            base.Size = Vector3.new(5000, 1, 5000)
            base.Position = root.Position - Vector3.new(0, 30, 0)
            base.Anchored = true
            base.Transparency = 1 -- Invisible agar tidak mencurigakan
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
            root.CFrame = driveSeat.CFrame
            task.wait(0.2)
            local prompt = driveSeat:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.1)
                prompt:InputHoldEnd()
            else
                driveSeat:Sit(hum)
            end
        end
    end
end

-- [ SYSTEM: CLEAR WORLD + NO COLLISION (BIAR GAK NABRAK) ]
function Engine:ClearWorld(player)
    local function disableCollision(obj)
        if obj:IsA("BasePart") then
            -- Lewati jika itu motor kita, karakter kita, atau lantai antivoid
            if string.find(obj.Name, "Montors") or obj.Name == player.Name or obj.Name == "System_Base_V2" then 
                return 
            end
            
            pcall(function()
                obj.CanCollide = false -- Matikan tabrakan
                obj.Transparency = 1  -- Hilangkan visual (biar ringan)
                -- Opsional: Matikan Shadow agar FPS naik
                obj.CastShadow = false
            end)
        end
    end

    -- Scan semua objek di Workspace secara mendalam
    for _, item in ipairs(game.Workspace:GetDescendants()) do
        disableCollision(item)
    end

    -- Pantau jika ada objek baru yang muncul (StreamingEnabled fix)
    game.Workspace.DescendantAdded:Connect(disableCollision)
    
    warn("✅ [Engine] World Cleared & No-Collision Active.")
end

-- [ SYSTEM: CRUISE LOGIC - STEALTH BYPASS ]
function Engine:RunCruise(player, config)
    local speed = 0
    local angle = math.random() * math.pi * 2
    
    return game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not config.IsActive() then return end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        if not seat then return end
        
        local motorRoot = (seat:FindFirstAncestorOfClass("Model") and seat.Parent.PrimaryPart) or seat
        if not motorRoot then return end

        -- 1. Kecepatan (Turunkan sedikit ke 190 agar tidak kick "Speed Hack")
        local targetSpeed = math.random(185, 205)
        speed = speed + (targetSpeed - speed) * 0.1 

        -- 2. Gerakan Melingkar dengan Noise
        local noise = math.noise(tick() * 0.3) * 0.15
        angle += (0.32 + noise) * dt
        local move = Vector3.new(math.cos(angle), 0, math.sin(angle))
        
        -- 3. Boundary (Kembali ke tengah jika terlalu jauh)
        if Vector3.new(motorRoot.Position.X, 0, motorRoot.Position.Z).Magnitude > 2500 then
            move = move:Lerp((-Vector3.new(motorRoot.Position.X, 0, motorRoot.Position.Z)).Unit, 0.15)
        end
        
        -- 4. Y-Lock + Oscillate (Biar tidak terlihat kaku melayang)
        local baseIDLE_Y = (typeof(config.LockY) == "function" and config.LockY()) or config.LockY or motorRoot.Position.Y
        local hover = math.sin(tick() * 3) * 0.5 -- Efek naik turun 0.5 stud
        local velocityY = (baseIDLE_Y + hover - motorRoot.Position.Y) * 20

        -- 5. Final Move
        motorRoot.AssemblyLinearVelocity = (move * speed) + Vector3.new(0, math.clamp(velocityY, -45, 45), 0)
        motorRoot.AssemblyAngularVelocity = Vector3.new(0, 0.03, 0)

        if hum.Sit == false then hum.Sit = true end
    end)
end

return Engine
