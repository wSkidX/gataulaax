loadstring(game:HttpGet("https://raw.githubusercontent.com/wSkidX/gataulaax/refs/heads/master/lowgfx.lua"))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua'))()

local MAIN = "jumgcx"
local DUMMIES = {"rcmly", "ILoveDoingAssHard69", "dummy3"}
local WEAPON_PRIORITY = {"SP", "SCARL", "Pistol", "Pistol .50", "Combat_P", "Carbine R", "AK47"}
local SLOT_KEYS = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five}
local PLATFORM_POS = Vector3.new(395, 3573, 3202)
local PLATFORM_SIZE = Vector3.new(50, 1, 50)
local PLATFORM_RADIUS = 5
local MAIN_OFFSET = Vector3.new(0, 3, 10)

local BLACKLIST_USERIDS = {
    [4434546189] = true,
    [2329879469] = true,
    [516665441] = true,
    [3814759052] = true,
    [4475347268] = true,
    [7686777574] = true
}

local players = game:GetService("Players")
local run_service = game:GetService("RunService")
local replicated = game.ReplicatedStorage
local equip_event = replicated:WaitForChild("inventoryShared"):WaitForChild("commEvents"):WaitForChild("inventoryEvents"):WaitForChild("equipped")
local local_player = players.LocalPlayer
local camera = workspace.CurrentCamera

local function get_quick_slots()
    for _, v in next, getgc(true) do
        if type(v) == "table" and rawget(v, "ItemUsed12345") then
            local arr = v.ItemUsed12345:get()
            if type(arr) == "table" then return arr end
        end
    end
end

local function get_char(username)
    local chars = workspace:FindFirstChild("Characters")
    if chars then
        local char = chars:FindFirstChild(username)
        if char and char:IsA("Model") and char:FindFirstChild("HumanoidRootPart") then
            return char
        end
    end
    local char = workspace:FindFirstChild(username)
    if char and char:IsA("Model") and char:FindFirstChild("HumanoidRootPart") then
        return char
    end
end

local function is_on_platform(char)
    return char and char:FindFirstChild("HumanoidRootPart") and (char.HumanoidRootPart.Position - PLATFORM_POS).Magnitude <= PLATFORM_RADIUS
end

local function teleport_to_platform(char, offset)
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:PivotTo(CFrame.new(PLATFORM_POS + (offset or Vector3.new())))
    end
end

local function set_safezone_false(username)
    local plr = players:FindFirstChild(username)
    if plr and plr:FindFirstChild("Stats") and plr.Stats:FindFirstChild("SafeZone") then
        plr.Stats.SafeZone.Value = false
    end
end

local function create_platform()
    local part = Instance.new("Part")
    part.Size = PLATFORM_SIZE
    part.Position = PLATFORM_POS
    part.Anchored = true
    part.Name = "ScriptPlatform"
    part.Parent = workspace
    return part
end

local function get_body(character)
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
end

local function check_and_leave()
    for _, player in ipairs(players:GetPlayers()) do
        if BLACKLIST_USERIDS[player.UserId] then
            pcall(function()
                game:Shutdown()
            end)
            break
        end
    end
end

local function auto_blacklist()
    players.PlayerAdded:Connect(function()
        check_and_leave()
    end)
    spawn(function()
        while true do
            check_and_leave()
            wait(2)
        end
    end)
end

auto_blacklist()

local function setup_platform_and_main()
    create_platform()
    local main_char = get_char(MAIN)
    if main_char and not is_on_platform(main_char) then
        teleport_to_platform(main_char, MAIN_OFFSET)
    end
end

setup_platform_and_main()

local function spawn_dummies_loop()
    spawn(function()
        while true do
            for i, dummy in ipairs(DUMMIES) do
                local dummy_char = get_char(dummy)
                local offset = Vector3.new((i-1)*6, 0, 0)
                if dummy_char and not is_on_platform(dummy_char) then
                    teleport_to_platform(dummy_char, offset)
                end
                set_safezone_false(dummy)
            end
            set_safezone_false(MAIN)
            wait(0.1)
        end
    end)
end

spawn_dummies_loop()

local function auto_equip_weapon()
    spawn(function()
        while true do
            local slots = get_quick_slots()
            if slots then
                for _, weapon in ipairs(WEAPON_PRIORITY) do
                    for i = 1, 5 do
                        if slots[i] == weapon then
                            equip_event:FireServer(SLOT_KEYS[i])
                            break
                        end
                    end
                end
            end
            wait(0.5)
        end
    end)
end

auto_equip_weapon()

local function aimbot_main()
    local dummy_index = 1
    run_service.RenderStepped:Connect(function()
        if #DUMMIES == 0 then return end
        local char = get_char(MAIN)
        local holding_weapon = false
        if char then
            for _, obj in ipairs(char:GetChildren()) do
                if obj:IsA("Tool") then
                    holding_weapon = true
                    break
                end
            end
        end
        if not holding_weapon then return end
        local checked = 0
        local found = false
        while checked < #DUMMIES do
            local target_name = DUMMIES[dummy_index]
            local target_char = get_char(target_name)
            local is_dead = false
            if target_char then
                if target_char:FindFirstChild("Highlight") then
                    is_dead = true
                end
            else
                is_dead = true
            end
            if not is_dead and target_char then
                local part = get_body(target_char)
                if part then
                    local cam_pos = camera.CFrame.Position
                    local aim_cframe = CFrame.new(cam_pos, part.Position)
                    camera.CFrame = camera.CFrame:Lerp(aim_cframe, 0.2)
                    found = true
                    break
                end
            end
            dummy_index = dummy_index % #DUMMIES + 1
            checked = checked + 1
        end
        if not found then
            dummy_index = dummy_index % #DUMMIES + 1
        end
    end)
end

aimbot_main()

local function auto_aim_and_shoot()
    spawn(function()
        local virtual_input = game:GetService("VirtualInputManager")
        while true do
            local char = get_char(MAIN)
            if char then
                for _, obj in ipairs(char:GetChildren()) do
                    if obj:IsA("Tool") then
                        virtual_input:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                        virtual_input:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        wait(0.15)
                        virtual_input:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                        virtual_input:SendMouseButtonEvent(0, 0, 1, false, game, 0)
                    end
                end
            end
            wait(0.1)
        end
    end)
end

auto_aim_and_shoot()
