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
            base.Size = Vector3.new(3000, 1, 3000) -- Ukuran lebih besar agar aman saat cruise
            base.Position = root.Position - Vector3.new(0, 15, 0)
            base.Anchored = true
            base.Transparency = 0.6
            base.BrickColor = BrickColor.new("Electric blue")
            base.Material = Enum.Material.Neon
            base.Parent = game.Workspace
        end
    end
    player.CharacterAdded:Connect(setup)
    if player.Character then task.spawn(setup, player.Character) end
end

-- [ SYSTEM: RIDE MOTOR (Auto-Teleport & Sit) ]
-- Fungsi baru untuk naik motor yang sudah di-spawn manual
function Engine:RideMotor(player)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    local pattern = player.Name .. "Montors"

    if not root or not hum then return warn("❌ Character belum siap.") end

    print("🔍 Mencari motor: " .. pattern)
    
    local motorModel = nil
    -- Mencari model di workspace
    for _, obj in pairs(workspace:GetChildren()) do
        if string.find(obj.Name, pattern) then
            motorModel = obj
            break
        end
    end

    if motorModel then
        local driveSeat = motorModel:FindFirstChild("DriveSeat") or motorModel:FindFirstChildWhichIsA("VehicleSeat", true)
        
        if driveSeat then
            -- Teleport ke kursi
            root.CFrame = driveSeat.CFrame * CFrame.new(0, 2, 0)
            print("⏳ Menunggu sinkronisasi (2 detik)...")
            task.wait(2)
            
            -- Coba gunakan ProximityPrompt jika ada executor
            local prompt = driveSeat:FindFirstChildOfClass("ProximityPrompt") or driveSeat:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and fireproximityprompt then
                fireproximityprompt(prompt)
                print("🔥 Berhasil menekan prompt!")
            else
                -- Fallback paksa duduk
                driveSeat:Sit(hum)
                print("⚠️ Memaksa duduk.")
            end
        else
            warn("❌ DriveSeat tidak ditemukan.")
            root.CFrame = motorModel:GetPivot() * CFrame.new(0, 5, 0)
        end
    else
        warn("❌ Motor tidak ditemukan! Pastikan sudah spawn manual.")
    end
end

-- [ SYSTEM: CLEAR WORLD ]
function Engine:ClearWorld(player)
    for _, obj in ipairs(game.Workspace:GetChildren()) do
        if obj:IsA("Terrain") or obj:IsA("Camera") or obj.Name == player.Name or obj.Name == "AntiVoidBase_DDS" then 
            continue 
        end
        -- Jangan hapus motor sendiri
        if string.find(obj.Name, "Montors") then continue end
        pcall(function() obj:Destroy() end)
    end
end

-- [ SYSTEM: CRUISE LOGIC ]
function Engine:RunCruise(player, config)
    local speed, dir, angle = 0, 1, math.random()*math.pi*2
    return game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not config.IsActive() then return end
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        if not seat then return end
        
        if hum.Sit == false then hum.Sit = true end

        -- Ambil Root dari model motor (bukan root player)
        local motor = seat:FindFirstAncestorOfClass("Model")
        local motorRoot = motor and motor.PrimaryPart or seat

        speed += dir*(dt*(250-220)/8)
        if speed>=250 then speed=250 dir=-0.6 elseif speed<=220 then speed=220 dir=0.6 end

        angle += 0.35*dt
        local move = Vector3.new(math.cos(angle),0,math.sin(angle))
        
        -- Batas area agar tidak terbang terlalu jauh (radius 2000)
        if Vector3.new(motorRoot.Position.X,0,motorRoot.Position.Z).Magnitude > 2000 then
            move = move:Lerp((-Vector3.new(motorRoot.Position.X,0,motorRoot.Position.Z)).Unit,0.06)
        end
        
        motorRoot.AssemblyLinearVelocity = move*speed + Vector3.new(0, math.clamp((config.LockY-motorRoot.Position.Y)*40,-35,35), 0)
    end)
end

return Engine
