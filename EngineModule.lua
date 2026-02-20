local Engine = {}

-- [ SYSTEM: ANTI-AFK ]
function Engine:InitAntiAFK(player)
    local GC = getconnections or get_signal_cons
    if GC then
        for i, v in pairs(GC(player.Idled)) do
            if v["Disable"] then v["Disable"](v) elseif v["Disconnect"] then v["Disconnect"](v) end
        end
    else
        player.Idled:Connect(function() end)
    end
end

-- [ SYSTEM: ANTI-VOID BASE ]
function Engine:CreateAntiVoid(player)
    local function setup(char)
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if root then
            task.wait(1)
            -- Hapus base lama jika ada
            if game.Workspace:FindFirstChild("AntiVoidBase_DDS") then
                game.Workspace.AntiVoidBase_DDS:Destroy()
            end
            
            local base = Instance.new("Part")
            base.Name = "AntiVoidBase_DDS"
            base.Size = Vector3.new(1500, 1, 1500)
            base.Position = root.Position - Vector3.new(0, 8, 0)
            base.Anchored = true
            base.Transparency = 0.6
            base.BrickColor = BrickColor.new("Electric blue")
            base.Material = Enum.Material.Neon
            base.Parent = game.Workspace
        end
    end

    -- Jalankan saat karakter masuk atau respawn
    player.CharacterAdded:Connect(setup)
    if player.Character then task.spawn(setup, player.Character) end
end

-- [ SYSTEM: CLEAR WORLD ]
function Engine:ClearWorld(player)
    for _, obj in ipairs(game.Workspace:GetChildren()) do
        -- Jangan hapus Terrain, Kamera, Diri sendiri, Anti-Void, dan Montors
        if obj:IsA("Terrain") or obj:IsA("Camera") or obj.Name == player.Name or obj.Name == "AntiVoidBase_DDS" then 
            continue 
        end
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
        
        -- Memaksa duduk jika terpental
        if hum.Sit == false then hum.Sit = true end

        local root = seat:FindFirstAncestorOfClass("Model") and seat:FindFirstAncestorOfClass("Model").PrimaryPart
        if not root then return end

        speed += dir*(dt*(250-220)/8)
        if speed>=250 then speed=250 dir=-0.6 elseif speed<=220 then speed=220 dir=0.6 end

        angle += 0.35*dt
        local move = Vector3.new(math.cos(angle),0,math.sin(angle))
        if Vector3.new(root.Position.X,0,root.Position.Z).Magnitude > 2000 then
            move = move:Lerp((-Vector3.new(root.Position.X,0,root.Position.Z)).Unit,0.06)
        end
        root.AssemblyLinearVelocity = move*speed + Vector3.new(0, math.clamp((config.LockY-root.Position.Y)*40,-35,35), 0)
    end)
end

return Engine
