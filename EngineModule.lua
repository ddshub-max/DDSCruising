local Engine = {}

-- [ SYSTEM: ANTI-AFK STEALTH ]
-- Menggunakan VirtualInputManager (lebih sulit dideteksi daripada VirtualUser)
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
        while task.wait(math.random(45, 90)) do -- Jeda lebih manusiawi
            -- Simulasikan input keyboard acak (W, A, S, atau D)
            local keys = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D}
            local key = keys[math.random(1, #keys)]
            
            VIM:SendKeyEvent(true, key, false, game)
            task.wait(0.1)
            VIM:SendKeyEvent(false, key, false, game)
        end
    end)
    warn("✅ [Engine] Stealth Anti-AFK Active.")
end

-- [ SYSTEM: ANTI-VOID STEALTH ]
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
            base.Size = Vector3.new(10000, 2, 10000)
            -- Gunakan posisi Y yang sangat rendah agar tidak terlihat pemain lain
            base.Position = Vector3.new(root.Position.X, -500, root.Position.Z) 
            base.Anchored = true
            base.Transparency = 1 -- Sepenuhnya transparan agar tidak di-report moderator
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
            -- Teleport halus ke kursi
            root.CFrame = driveSeat.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.3)
            
            local prompt = driveSeat:FindFirstChildOfClass("ProximityPrompt") or driveSeat:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt) -- Gunakan fungsi executor jika tersedia
            else
                driveSeat:Sit(hum)
            end
        end
    end
end

-- [ SYSTEM: CRUISE LOGIC V2 - STEALTH MOVEMENT ]
function Engine:RunCruise(player, config)
    local currentSpeed = 0
    local angle = math.random() * math.pi * 2
    local runService = game:GetService("RunService")
    
    return runService.Heartbeat:Connect(function(dt)
        if not config.IsActive() then return end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local seat = hum and hum.SeatPart
        
        -- Auto re-sit jika terjatuh
        if not seat then
            self:RideMotor(player)
            return
        end

        local motor = seat:FindFirstAncestorOfClass("Model")
        local motorRoot = motor and motor.PrimaryPart or seat
        
        -- 1. Dinamika Kecepatan (Anti-Pattern)
        -- Menggunakan math.noise agar fluktuasi speed terlihat alami/random
        local speedNoise = math.noise(tick() * 0.2) * 25
        local targetMax = config.MaxSpeed or 200
        local targetMin = config.MinSpeed or 170
        local dynamicTarget = ((targetMax + targetMin) / 2) + speedNoise
        
        currentSpeed = currentSpeed + (dynamicTarget - currentSpeed) * (dt * 0.8)

        -- 2. Circular Motion Logic
        angle = angle + (0.15 * dt)
        local moveDirection = Vector3.new(math.cos(angle), 0, math.sin(angle))
        
        -- 3. CFrame & Velocity Hybrid
        -- Menggerakkan via CFrame lebih stabil, tapi kita beri sedikit Velocity
        -- agar physics server tidak mendeteksi keanehan (statik tapi berpindah)
        local targetY = config.LockY or -495 -- Sedikit di atas Anti-Void
        local nextPosition = motorRoot.Position + (moveDirection * currentSpeed * dt)
        local finalCFrame = CFrame.new(Vector3.new(nextPosition.X, targetY, nextPosition.Z), 
                                       Vector3.new(nextPosition.X + moveDirection.X, targetY, nextPosition.Z + moveDirection.Z))

        -- Interpolasi halus
        motorRoot.CFrame = motorRoot.CFrame:Lerp(finalCFrame, 0.2)
        
        -- Berikan Velocity kecil untuk "menipu" server physics
        motorRoot.AssemblyLinearVelocity = moveDirection * 5
        motorRoot.AssemblyAngularVelocity = Vector3.zero
        
        -- Paksa state sitting
        if hum.Sit == false then hum.Sit = true end
    end)
end

return Engine
