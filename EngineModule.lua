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
                game:GetService("VirtualUser"):ClickButton2(Vector2.new(math.random(1,50), math.random(1,50)))
            end)
        end
    end)

    task.spawn(function()
        local VU = game:GetService("VirtualUser")
        while task.wait(math.random(20, 45)) do 
            pcall(function()
                VU:CaptureController()
                VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(math.random(2, 8) / 10)
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
            -- Ganti nama ke sesuatu yang sangat umum agar tidak terfilter
            local baseName = "Part" 
            if game.Workspace:FindFirstChild(baseName) and game.Workspace[baseName].Size.X > 4000 then
                game.Workspace[baseName]:Destroy()
            end
            local base = Instance.new("Part")
            base.Name = baseName
            base.Size = Vector3.new(5000, 1, 5000)
            -- Turunkan sedikit lebih jauh agar tidak dianggap nempel lantai
            base.Position = root.Position - Vector3.new(0, 35, 0)
            base.Anchored = true
            base.Transparency = 1 -- Buat benar-benar tidak terlihat (invisible)
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
            task.wait(0.3)
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

-- [ SYSTEM: CLEAR WORLD (SAFE VERSION) ]
function Engine:ClearWorld(player)
    -- Daripada menghapus, lebih aman menyembunyikan objek secara lokal
    -- Menghapus objek Workspace sering memicu kick "Missing Map Data"
    for _, obj in ipairs(game.Workspace:GetChildren()) do
        if obj:IsA("BasePart") and not string.find(obj.Name, "Montors") and obj.Name ~= player.Name then
            pcall(function()
                obj.Transparency = 1
                obj.CanCollide = false
            end)
        elseif obj:IsA("Model") and not string.find(obj.Name, "Montors") and obj.Name ~= player.Name then
            pcall(function()
                for _, p in pairs(obj:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.Transparency = 1
                        p.CanCollide = false
                    end
                end
            end)
        end
    end
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

        -- 1. SPEED LIMITER (CRITICAL)
        -- Turunkan ke 180-190. Kecepatan > 200 sangat mudah dideteksi server modern.
        local safeSpeed = math.random(175, 195)
        speed = speed + (safeSpeed - speed) * 0.05 

        -- 2. RANDOM DIRECTION (Mencegah deteksi pola melingkar)
        angle += (0.2 + (math.noise(tick() * 0.2) * 0.1)) * dt
        local move = Vector3.new(math.cos(angle), 0, math.sin(angle))
        
        -- 3. JITTERY Y-AXIS (Sangat penting agar tidak dianggap melayang statis)
        local targetY = (typeof(config.LockY) == "function" and config.LockY()) or config.LockY or motorRoot.Position.Y
        -- Tambahkan efek "Naik Turun" seperti motor kena gelombang jalan
        local fakeBumpyRoad = math.sin(tick() * 4) * 0.8
        local velocityY = (targetY + fakeBumpyRoad - motorRoot.Position.Y) * 15

        -- 4. APPLY VELOCITY
        motorRoot.AssemblyLinearVelocity = (move * speed) + Vector3.new(0, math.clamp(velocityY, -50, 50), 0)
        
        -- 5. SIMULASI STUCK/LAG (Teknik bypass agar server menganggap player lag)
        if math.random(1, 500) == 1 then
            motorRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            task.wait(0.1)
        end

        if hum.Sit == false then hum.Sit = true end
    end)
end

return Engine
