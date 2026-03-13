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
                VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                VU:MouseMoveEvent(Vector2.new(math.random(1, 5), math.random(1, 5)), workspace.CurrentCamera.CFrame)
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
            base.Size = Vector3.new(4000, 1, 4000)
            base.Position = root.Position - Vector3.new(0, 20, 0)
            base.Anchored = true
            base.Transparency = 0.7
            base.BrickColor = BrickColor.new("Electric blue")
            base.Material = Enum.Material.Neon
            base.Parent = game.Workspace
        end
    end
    player.CharacterAdded:Connect(setup)
    if player.Character then task.spawn(setup, player.Character) end
end

-- [ SYSTEM: RIDE MOTOR (Safe Hold Manipulation) ]
-- Perbaikan: Menggunakan manipulasi inputhold daripada fireproximityprompt
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
        local driveSeat = motorModel:FindFirstChild("DriveSeat") or motorModel:FindFirstChildWhichIsA("VehicleSeat", true)
        
        if driveSeat then
            -- Set Network Owner (PENTING: Agar physics tidak lag/stuck)
            pcall(function()
                driveSeat:SetNetworkOwner(player)
            end)

            -- Teleport tepat ke kursi
            root.CFrame = driveSeat.CFrame
            task.wait(0.3)

            local prompt = driveSeat:FindFirstChildOfClass("ProximityPrompt") or driveSeat:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            if prompt then
                print("⏳ Safe Hold Interaction Started...")
                prompt:InputHoldBegin()
                -- Mengikuti durasi hold asli dari game
                task.wait(prompt.HoldDuration + 0.1)
                prompt:InputHoldEnd()
                print("✅ Hold Interaction Finished.")
            else
                -- Jika tidak ada prompt, gunakan metode paksa sebagai cadangan
                driveSeat:Sit(hum)
            end

            -- Kunci agar tidak mental saat awal gerak
            task.spawn(function()
                for i = 1, 10 do
                    if hum.Sit == false then driveSeat:Sit(hum) end
                    task.wait(0.2)
                end
            end)
        else
            warn("❌ DriveSeat tidak ditemukan.")
        end
    else
        warn("❌ Motor tidak ditemukan!")
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

-- [ SYSTEM: CRUISE LOGIC ]
-- Perbaikan: Logika deteksi root part yang lebih cerdas agar tidak stuck
function Engine:RunCruise(player, config)
    local speed, dir, angle = 0, 1, math.random()*math.pi*2
    
    return game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not config.IsActive() then return end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        
        -- Auto Re-Sit: Jika karakter turun saat cruise aktif, tarik balik ke motor
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
        
        -- Ambil Root Part Motor dengan aman
        local motor = seat:FindFirstAncestorOfClass("Model")
        -- Jika model tidak punya PrimaryPart, gunakan Seat itu sendiri sebagai root physics
        local motorRoot = (motor and motor.PrimaryPart) or seat
        
        if not motorRoot then return end
        
        -- Memastikan status duduk terkunci
        if hum.Sit == false then hum.Sit = true end

        -- Logika Kecepatan (220 - 250 KM/H)
        speed += dir*(dt*(250-220)/8)
        if speed>=250 then speed=250 dir=-0.6 elseif speed<=220 then speed=220 dir=0.6 end

        -- Logika Arah (Circular Movement)
        angle += 0.35*dt
        local move = Vector3.new(math.cos(angle),0,math.sin(angle))
        
        -- Boundary: Jika terlalu jauh (radius 2000), tarik balik ke tengah
        if Vector3.new(motorRoot.Position.X,0,motorRoot.Position.Z).Magnitude > 2000 then
            move = move:Lerp((-Vector3.new(motorRoot.Position.X,0,motorRoot.Position.Z)).Unit, 0.08)
        end
        
        -- Eksekusi Pergerakan (Linear Velocity)
        -- Menggunakan Y-Lock dinamis dari config
        local targetY = (typeof(config.LockY) == "function" and config.LockY()) or config.LockY or motorRoot.Position.Y
        
        motorRoot.AssemblyLinearVelocity = (move * speed) + Vector3.new(0, math.clamp((targetY - motorRoot.Position.Y) * 40, -35, 35), 0)
        
        -- Mencegah Motor miring (Optional but recommended)
        motorRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
end

return Engine
