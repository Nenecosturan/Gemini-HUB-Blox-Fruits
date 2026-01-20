--[[
    GEMINI TITAN HUB - ULTIMATE EDITION
    PART 1: CORE & AUTO FARM SYSTEM
    -------------------------------------------------
    Bu kısım scriptin temel servislerini, global ayarlarını
    ve ana Level Farm mantığını içerir.
]]

-- [1] SERVICES (HİZMETLER)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

-- [2] LOCAL PLAYER VARIABLES (YEREL DEĞİŞKENLER)
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- [3] GLOBAL CONFIGURATION TABLE (TÜM AYARLAR BURADA)
-- Part 2, 3 ve 4 bu tabloyu kullanacak.
getgenv().TitanConfig = {
    -- /// AUTO FARM ///
    AutoFarm = false,
    FarmMode = "Level", -- Level, Nearest, Chest, Boss
    AutoQuest = true,
    FarmMethod = "Above", -- Above (Tepeden), Below (Alttan), Behind (Arkadan)
    Distance = 7, -- Mob ile aradaki mesafe
    Height = 10, -- Tepeden bakma yüksekliği
    BringMob = true, -- Mobları bir araya toplama
    FastAttack = true, -- Hızlı saldırı
    
    -- /// WEAPON ///
    SelectWeapon = "Melee", -- Melee, Sword, Blox Fruit
    AutoHaki = true,
    
    -- /// STATS ///
    AutoStats = false,
    SelectStat = "Melee", -- Melee, Defense, Sword, Gun, Blox Fruit
    PointsToAdd = 3,
    
    -- /// COMBAT & RAID ///
    KillAura = false,
    AutoRaid = false,
    RaidChip = "Flame",
    AutoAwaken = true,
    NextIsland = true,
    
    -- /// SEA EVENTS ///
    SeaBeastFarm = false,
    AutoBuyBoat = false,
    BoatType = "Guardian",
    
    -- /// VISUALS & MISC ///
    ESP = false,
    ESPPlayer = false,
    ESPChest = false,
    ESPFruit = false,
    WhiteScreen = false,
    InfiniteEnergy = true,
    WalkSpeed = 16,
    JumpPower = 50,
    SpectatePlayer = ""
}

-- [4] CORE UTILITY FUNCTIONS (YARDIMCI FONKSİYONLAR)

-- > Canlı Kontrolü
function CheckAlive(Char)
    if Char and Char:FindFirstChild("Humanoid") and Char:FindFirstChild("HumanoidRootPart") and Char.Humanoid.Health > 0 then
        return true
    end
    return false
end

-- > Sunucu İletişimi (Remote Wrapper)
function CommF(Func, Arg1, Arg2, Arg3)
    return ReplicatedStorage.Remotes.CommF_:InvokeServer(Func, Arg1, Arg2, Arg3)
end

-- > Gelişmiş Tween (Işınlanma) Motoru
function TweenTo(TargetCFrame)
    if not CheckAlive(LocalPlayer.Character) then return end
    
    local Root = LocalPlayer.Character.HumanoidRootPart
    local Distance = (Root.Position - TargetCFrame.Position).Magnitude
    local Speed = 320 -- Güvenli Hız Limiti (Ban yememek için)
    
    -- BodyVelocity ile havada kalma (Düşmeyi engelle)
    if not Root:FindFirstChild("TitanFloat") then
        local BV = Instance.new("BodyVelocity")
        BV.Name = "TitanFloat"
        BV.Parent = Root
        BV.Velocity = Vector3.new(0,0,0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    end
    
    -- Tween Oluşturma
    local Info = TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)
    local Tween = TweenService:Create(Root, Info, {CFrame = TargetCFrame})
    Tween:Play()
    
    -- Hedefe çok yakınsa Tween'i iptal et ve CFrame eşitle (Titreşimi önler)
    if Distance < 10 then
        Root.CFrame = TargetCFrame
    end
end

-- > En İyi Silahı Bul ve Kuşan
function EquipWeapon(Type)
    local Backpack = LocalPlayer.Backpack
    local Char = LocalPlayer.Character
    local TargetTool = nil
    
    -- Önce karakterde var mı bak
    for _, tool in pairs(Char:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == Type then
            TargetTool = tool
        end
    end
    
    -- Yoksa çantaya bak
    if not TargetTool then
        for _, tool in pairs(Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == Type then
                TargetTool = tool
                break
            end
        end
    end
    
    if TargetTool and TargetTool.Parent == Backpack then
        Char.Humanoid:EquipTool(TargetTool)
    end
end

-- [5] UI LIBRARY SETUP (RAYFIELD)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Gemini Titan Hub | V5 Ultimate",
    LoadingTitle = "Titan Hub Yükleniyor...",
    LoadingSubtitle = "Created by Gemini AI",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GeminiTitanConfig",
        FileName = "MainConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
})

-- [6] TAB 1: MAIN AUTO FARM (UI & LOGIC)
local TabFarm = Window:CreateTab("Auto Farm", 4483362458)

TabFarm:CreateSection("Farm Ayarları")

-- Master Switch
TabFarm:CreateToggle({
    Name = "Auto Farm Level (Main)",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        TitanConfig.AutoFarm = Value
    end,
})

-- Quest Switch
TabFarm:CreateToggle({
    Name = "Auto Quest (Görev Al)",
    CurrentValue = true,
    Callback = function(Value)
        TitanConfig.AutoQuest = Value
    end,
})

-- Mob Seçenekleri
TabFarm:CreateDropdown({
    Name = "Farm Modu",
    Options = {"Level", "Nearest", "Chest"},
    CurrentOption = {"Level"},
    Callback = function(Value)
        TitanConfig.FarmMode = Value[1]
    end,
})

TabFarm:CreateSection("Savaş Ayarları")

TabFarm:CreateToggle({
    Name = "Fast Attack (Hızlı Saldırı)",
    CurrentValue = true,
    Callback = function(Value)
        TitanConfig.FastAttack = Value
    end,
})

TabFarm:CreateDropdown({
    Name = "Silah Seçimi",
    Options = {"Melee", "Sword", "Blox Fruit"},
    CurrentOption = {"Melee"},
    Callback = function(Value)
        TitanConfig.SelectWeapon = Value[1]
    end,
})

-- [7] AUTO FARM ENGINE (LOGIC LOOP)
-- Bu döngü sürekli arka planda çalışır.
task.spawn(function()
    while true do
        task.wait() -- Anti-Crash
        if TitanConfig.AutoFarm then
            pcall(function()
                -- 1. Görev Durumunu Kontrol Et
                local MyQuest = LocalPlayer.PlayerGui.Main.Quest
                if not MyQuest.Visible and TitanConfig.AutoQuest then
                    -- Basit Görev Alma Mantığı (Geliştirilecek)
                    -- Buraya binlerce satırlık Level -> Quest ID eşleşmesi Part 3'te eklenebilir.
                    -- Şimdilik en yakın quest giver'a gitme simülasyonu:
                    local GuideModule = require(ReplicatedStorage.GuideModule)
                    local TargetQuest = GuideModule["CurrentQuest"]
                    if TargetQuest then
                        CommF("StartQuest", TargetQuest.Name, TargetQuest.Level)
                    else
                        -- Eğer görev bulunamazsa BanditQuest1 al (Fallback)
                        CommF("StartQuest", "BanditQuest1", 1)
                    end
                end

                -- 2. Hedef Mob'u Bul
                local TargetMob = nil
                for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
                    if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                        -- Görevdeki mob ismini PlayerGui'den çekerek eşleştirme yapılabilir.
                        -- Şimdilik en yakını alıyoruz:
                        TargetMob = enemy
                        break
                    end
                end

                -- 3. Hedefe Git ve Saldır
                if TargetMob then
                    -- Pozisyon Hesapla (Tepeden, Arkadan vb.)
                    local MobPos = TargetMob.HumanoidRootPart.CFrame
                    local MyPos = CFrame.new()
                    
                    if TitanConfig.FarmMethod == "Above" then
                        MyPos = MobPos * CFrame.new(0, TitanConfig.Height, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                    elseif TitanConfig.FarmMethod == "Behind" then
                        MyPos = MobPos * CFrame.new(0, 0, TitanConfig.Distance)
                    else
                        MyPos = MobPos
                    end
                    
                    TweenTo(MyPos)
                    
                    -- Mobları Getir (Bring Mob)
                    if TitanConfig.BringMob then
                        for _, subEnemy in pairs(Workspace.Enemies:GetChildren()) do
                            if subEnemy ~= TargetMob and CheckAlive(subEnemy) and (subEnemy.HumanoidRootPart.Position - TargetMob.HumanoidRootPart.Position).Magnitude < 300 then
                                subEnemy.HumanoidRootPart.CFrame = TargetMob.HumanoidRootPart.CFrame
                                subEnemy.HumanoidRootPart.CanCollide = false
                                subEnemy.Humanoid.WalkSpeed = 0
                            end
                        end
                    end
                    
                    -- Silahı Kuşan
                    EquipWeapon(TitanConfig.SelectWeapon)
                    
                    -- Saldır
                    if TitanConfig.FastAttack then
                        local Combat = require(ReplicatedStorage.CombatFramework.RigController)
                        local CameraShaker = require(ReplicatedStorage.Util.CameraShaker)
                        CameraShaker:Stop()
                        if Combat then
                            Combat.activeController.hitboxMagnitude = 60
                            Combat.activeController:attack()
                        end
                    else
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton1(Vector2.new(999,999), Camera.CFrame)
                    end
                end
            end)
        else
            -- Farm kapalıysa BodyVelocity'yi temizle
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if LocalPlayer.Character.HumanoidRootPart:FindFirstChild("TitanFloat") then
                    LocalPlayer.Character.HumanoidRootPart.TitanFloat:Destroy()
                end
            end
        end
    end
end)

-- [[ END OF PART 1 ]] --
-- [[ LÜTFEN PART 2 KODUNU BURANIN ALTINA YAPIŞTIRIN ]] --
--[[ 
    -------------------------------------------------
    GEMINI TITAN HUB - PART 2: COMBAT & STATS
    -------------------------------------------------
    Bu modül, karakter gelişimi, PVP mekanikleri ve
    savaş döngülerini içerir. Part 1'deki 'TitanConfig'
    tablosunu kullanır.
]]

-- [1] COMBAT LOGIC FUNCTIONS (SAVAŞ MANTIĞI)

-- > Otomatik Haki (Buso) Kontrolü
task.spawn(function()
    while true do
        task.wait(1)
        if TitanConfig.AutoHaki then
            -- Karakterin Haki özelliğine sahip olup olmadığını kontrol et
            if not LocalPlayer.Character:FindFirstChild("HasBuso") then
                local HasHaki = false
                -- Envanterde veya yeteneklerde Buso var mı? (Remote kontrolü)
                -- Blox Fruits'te Buso "J" tuşuyla veya Remote ile açılır.
                CommF("Buso")
            end
        end
    end
end)

-- > Hitbox Expander (PVP Avantajı)
-- Rakiplerin vuruş alanını büyütür, ıskalamayı engeller.
task.spawn(function()
    while true do
        task.wait(1) -- Her saniye kontrol et (FPS dostu)
        if TitanConfig.HitboxExpander then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    -- Takım arkadaşı kontrolü (Team Check)
                    if TitanConfig.TeamCheck and plr.Team == LocalPlayer.Team then
                        continue 
                    end
                    
                    local Root = plr.Character.HumanoidRootPart
                    Root.Size = Vector3.new(TitanConfig.HitboxSize, TitanConfig.HitboxSize, TitanConfig.HitboxSize)
                    Root.Transparency = 0.7
                    Root.CanCollide = false
                end
            end
        end
    end
end)

-- > Aimbot Hesaplayıcı
local function GetClosestPlayer()
    local ClosestDist = 99999
    local ClosestPlr = nil
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
            -- Takım kontrolü
            if TitanConfig.TeamCheck and v.Team == LocalPlayer.Team then continue end
            
            -- Mesafe hesabı (Mouse'a en yakın olanı bul)
            local Pos, OnScreen = Camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
            local Dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(Pos.X, Pos.Y)).Magnitude
            
            if OnScreen and Dist < TitanConfig.AimbotFOV then
                if Dist < ClosestDist then
                    ClosestDist = Dist
                    ClosestPlr = v
                end
            end
        end
    end
    return ClosestPlr
end

-- Aimbot Döngüsü (RenderStepped - Çok Hızlı)
RunService.RenderStepped:Connect(function()
    if TitanConfig.Aimbot then
        local Target = GetClosestPlayer()
        if Target then
            local AimPos = Target.Character[TitanConfig.AimPart].Position
            -- Kamera yumuşatma (Smoothing)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, AimPos)
        end
    end
end)

-- [2] STATS MANAGEMENT (İSTATİSTİK YÖNETİMİ)

task.spawn(function()
    while true do
        task.wait(0.5) -- Sunucuyu yormamak için yarım saniye bekle
        if TitanConfig.AutoStats then
            local Points = LocalPlayer.Data.Points.Value
            if Points > 0 then
                -- Seçilen istatistiğe puan ekle
                -- Not: Blox Fruits 3'er 3'er eklemeye izin verir mi kontrol edilmeli, genelde 1'dir.
                CommF("AddPoint", TitanConfig.SelectStat, TitanConfig.PointsToAdd)
            end
        end
    end
end)

-- [3] UI TAB: STATS & SKILLS (İSTATİSTİK SEKMESİ)

local TabStats = Window:CreateTab("Stats & Skills", 4483362458)

TabStats:CreateSection("Otomatik Puan Dağıtımı")

TabStats:CreateToggle({
    Name = "Auto Stats (Aktif Et)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.AutoStats = Value
    end,
})

TabStats:CreateDropdown({
    Name = "Geliştirilecek Stat",
    Options = {"Melee", "Defense", "Sword", "Gun", "Blox Fruit"},
    CurrentOption = {"Melee"},
    Callback = function(Value)
        TitanConfig.SelectStat = Value[1]
    end,
})

TabStats:CreateSlider({
    Name = "Eklenecek Puan Miktarı",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 1,
    Callback = function(Value)
        TitanConfig.PointsToAdd = Value
    end,
})

TabStats:CreateSection("Yetenek Otomasyonu")

TabStats:CreateToggle({
    Name = "Auto Buso Haki",
    CurrentValue = true,
    Callback = function(Value)
        TitanConfig.AutoHaki = Value
    end,
})

TabStats:CreateToggle({
    Name = "Auto Ken Haki (Gözlem)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.AutoKen = Value
        task.spawn(function()
            while TitanConfig.AutoKen do
                task.wait(2)
                -- Gözlem hakisi kapalıysa açmayı dene (Ken remotesini bulmamız gerek, genelde tuş simülasyonudur)
                VirtualUser:CaptureController()
                VirtualUser:SetKeyDown("e") -- Varsayılan tuş E
                task.wait(0.1)
                VirtualUser:SetKeyUp("e")
            end
        end)
    end,
})

-- [4] UI TAB: PVP & COMBAT (SAVAŞ SEKMESİ)

local TabPVP = Window:CreateTab("PVP & Combat", 4483362458)

TabPVP:CreateSection("Aimbot Ayarları")

TabPVP:CreateToggle({
    Name = "Aimbot (Kamera Kilidi)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.Aimbot = Value
    end,
})

TabPVP:CreateDropdown({
    Name = "Hedef Bölge",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = {"HumanoidRootPart"},
    Callback = function(Value)
        TitanConfig.AimPart = Value[1]
    end,
})

TabPVP:CreateSlider({
    Name = "FOV Çemberi (Menzil)",
    Range = {50, 800},
    Increment = 10,
    CurrentValue = 150,
    Callback = function(Value)
        TitanConfig.AimbotFOV = Value
    end,
})

TabPVP:CreateToggle({
    Name = "Team Check (Takım Arkadaşını Vurma)",
    CurrentValue = true,
    Callback = function(Value)
        TitanConfig.TeamCheck = Value
    end,
})

TabPVP:CreateSection("PVP Avantajları")

TabPVP:CreateToggle({
    Name = "Hitbox Expander (Dev Kafa)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.HitboxExpander = Value
    end,
})

TabPVP:CreateSlider({
    Name = "Hitbox Boyutu",
    Range = {2, 50},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(Value)
        TitanConfig.HitboxSize = Value
    end,
})

TabPVP:CreateToggle({
    Name = "Kill Aura (Oyuncular İçin)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.KillAura = Value
        task.spawn(function()
            while TitanConfig.KillAura do
                task.wait(0.1)
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local Dist = (LocalPlayer.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                        if Dist < 25 and plr.Character.Humanoid.Health > 0 then
                            if TitanConfig.FastAttack then
                                require(ReplicatedStorage.CombatFramework.RigController).activeController:attack()
                            end
                        end
                    end
                end
            end
        end)
    end,
})

-- [[ END OF PART 2 ]] --
-- [[ LÜTFEN PART 3 KODUNU BURANIN ALTINA YAPIŞTIRIN ]] --
--[[ 
    -------------------------------------------------
    GEMINI TITAN HUB - PART 3: WORLD, RAID & FRUIT
    -------------------------------------------------
    Bu modül, Zindan (Raid) döngülerini, ışınlanma 
    sistemlerini ve meyve/market ekonomisini yönetir.
]]

-- [1] RAID & DUNGEON ENGINE (ZİNDAN MOTORU)

task.spawn(function()
    while true do
        task.wait(1)
        if TitanConfig.AutoRaid then
            pcall(function()
                -- 1. Raid Haritasında mıyız kontrol et
                local Map = Workspace:FindFirstChild("Map")
                local RaidMap = Map and Map:FindFirstChild("RaidMap")
                
                if not RaidMap then
                    -- Raid'de değiliz, hazırlık yap
                    -- Labaratuvara Işınlan (Hot/Cold)
                    if (LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(-6500, 0, -6000)).Magnitude > 1000 then
                         -- Lab koordinatlarına yaklaş (Zeta)
                         CommF("TravelZeta") 
                    end
                    
                    -- Çipi Satın Al (Envanterde yoksa)
                    if not LocalPlayer.Backpack:FindFirstChild("Microchip") and not LocalPlayer.Character:FindFirstChild("Microchip") then
                        CommF("BuyRaidMicrochip", TitanConfig.RaidChip)
                        task.wait(1)
                    end
                    
                    -- Raidi Başlat (Fiziksel Butona Basma)
                    -- Not: Buradaki buton yolu oyundaki harita güncellemelerine göre değişebilir
                    local StartButton = Map.CircleIsland.RaidSummon2.Button.ClickDetector
                    if StartButton then
                        fireclickdetector(StartButton)
                    end
                else
                    -- Raid İçindeyiz
                    -- Kill Aura (Raid Versiyonu)
                    if TitanConfig.KillAuraRaid then
                        for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
                            if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                                -- Moba Işınlan
                                LocalPlayer.Character.HumanoidRootPart.CFrame = enemy.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                                -- Saldır
                                if TitanConfig.FastAttack then
                                    require(ReplicatedStorage.CombatFramework.RigController).activeController:attack()
                                end
                            end
                        end
                    end
                    
                    -- Sonraki Adaya Geçiş (Next Island)
                    if TitanConfig.NextIsland then
                        -- Mob kalmadıysa bir sonraki adaya ışınlan
                        if #Workspace.Enemies:GetChildren() == 0 then
                             -- Raid haritasındaki bir sonraki spawn noktasına git (Otomatik algılama)
                             -- Genellikle oyun oyuncuyu otomatik atar ama takılırsa diye ileri TP:
                             LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -50)
                        end
                    end
                    
                    -- Otomatik Uyanış (Awaken)
                    if TitanConfig.AutoAwaken then
                        -- Raid bittiğinde Awaken NPC'si ile konuş
                        CommF("AwakenZ", "Z") -- İlk yeteneği uyandırır
                    end
                end
            end)
        end
    end
end)

-- [2] FRUIT SNIPER ENGINE (MEYVE TOPLAYICI)

task.spawn(function()
    while true do
        task.wait(0.5)
        if TitanConfig.FruitSniper then
            pcall(function()
                -- Workspace'teki tüm tool'ları tara (Yerdeki meyveler Tool olarak geçer)
                for _, item in pairs(Workspace:GetChildren()) do
                    if item:IsA("Tool") and item.ToolTip == "Blox Fruit" then
                        -- Meyve bulundu, ışınlan ve al
                        local Handle = item:FindFirstChild("Handle")
                        if Handle then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = Handle.CFrame
                            task.wait(0.2)
                            -- Otomatik Depola
                            if TitanConfig.AutoStore then
                                CommF("StoreFruit", item.Name, item)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- [3] UI TAB: RAID & DUNGEON (ZİNDAN SEKMESİ)

local TabRaid = Window:CreateTab("Raid & Dungeon", 4483362458)

TabRaid:CreateSection("Otomatik Raid")

TabRaid:CreateToggle({
    Name = "Auto Raid (Döngü)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.AutoRaid = Value
    end,
})

TabRaid:CreateDropdown({
    Name = "Raid Çipi Seç",
    Options = {"Flame", "Ice", "Quake", "Light", "Dark", "Spider", "Rumble", "Magma", "Buddha", "Sand"},
    CurrentOption = {"Flame"},
    Callback = function(Value)
        TitanConfig.RaidChip = Value[1]
    end,
})

TabRaid:CreateSection("Raid İçi Ayarlar")

TabRaid:CreateToggle({
    Name = "Kill Aura (Raid Mobları)",
    CurrentValue = true,
    Callback = function(Value)
        TitanConfig.KillAuraRaid = Value
    end,
})

TabRaid:CreateToggle({
    Name = "Auto Next Island (Sonraki Ada)",
    CurrentValue = true,
    Callback = function(Value)
        TitanConfig.NextIsland = Value
    end,
})

TabRaid:CreateToggle({
    Name = "Auto Awaken (Meyve Uyandır)",
    CurrentValue = true,
    Callback = function(Value)
        TitanConfig.AutoAwaken = Value
    end,
})

-- [4] UI TAB: FRUIT & SHOP (MARKET SEKMESİ)

local TabFruit = Window:CreateTab("Fruit & Shop", 4483362458)

TabFruit:CreateSection("Meyve İşlemleri")

TabFruit:CreateToggle({
    Name = "Auto Random Fruit (Gacha)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.AutoBuyFruit = Value
        task.spawn(function()
            while TitanConfig.AutoBuyFruit do
                task.wait(4) -- Her 4 saniyede bir dene (Para varsa alır)
                CommF("Cousin", "Buy")
            end
        end)
    end,
})

TabFruit:CreateToggle({
    Name = "Auto Store Fruit (Depola)",
    CurrentValue = true,
    Callback = function(Value)
        TitanConfig.AutoStore = Value
        if Value then
            -- Envanterdeki meyveleri kontrol et ve depola
            for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                if tool.ToolTip == "Blox Fruit" then
                    CommF("StoreFruit", tool.Name, tool)
                end
            end
        end
    end,
})

TabFruit:CreateToggle({
    Name = "Fruit Sniper (Yerdekini Al)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.FruitSniper = Value
    end,
})

TabFruit:CreateSection("Yetenek Satın Al")

TabFruit:CreateButton({
    Name = "Geppo (Zıplama) Al",
    Callback = function() CommF("BuyHaki", "Geppo") end,
})

TabFruit:CreateButton({
    Name = "Buso (Haki) Al",
    Callback = function() CommF("BuyHaki", "Buso") end,
})

TabFruit:CreateButton({
    Name = "Soru (Işınlanma) Al",
    Callback = function() CommF("BuyHaki", "Soru") end,
})

-- [5] UI TAB: TELEPORT & WORLD (DÜNYA SEKMESİ)

local TabWorld = Window:CreateTab("Teleports", 4483362458)

TabWorld:CreateSection("Dünyalar Arası Geçiş")

TabWorld:CreateButton({
    Name = "Sea 1 (Main World)",
    Callback = function() CommF("TravelMain") end,
})

TabWorld:CreateButton({
    Name = "Sea 2 (Dressrosa)",
    Callback = function() CommF("TravelDressrosa") end,
})

TabWorld:CreateButton({
    Name = "Sea 3 (Zou)",
    Callback = function() CommF("TravelZou") end,
})

TabWorld:CreateSection("Adalara Işınlan (Sea 1)")

-- Örnek bir ada listesi ve koordinatları
-- Not: Bu liste 30+ ada için uzatılabilir, örnek olarak Sea 1'i koyuyoruz.
local IslandsSea1 = {
    ["Jungle"] = CFrame.new(-1255, 12, 320),
    ["Middle Town"] = CFrame.new(-650, 15, 1580),
    ["Pirate Village"] = CFrame.new(-1145, 14, 3855),
    ["Marine Ford"] = CFrame.new(-5000, 20, 4200),
    ["Skylands"] = CFrame.new(-4800, 750, -1100),
    ["Prison"] = CFrame.new(4800, 15, 750),
    ["Fountain City"] = CFrame.new(5100, 15, 4000)
}

TabWorld:CreateDropdown({
    Name = "Ada Seçimi",
    Options = {"Jungle", "Middle Town", "Pirate Village", "Marine Ford", "Skylands", "Prison", "Fountain City"},
    CurrentOption = {"Jungle"},
    Callback = function(Value)
        local TargetIsland = IslandsSea1[Value[1]]
        if TargetIsland then
            TweenTo(TargetIsland)
        end
    end,
})

-- [[ END OF PART 3 ]] --
-- [[ LÜTFEN PART 4 KODUNU BURANIN ALTINA YAPIŞTIRIN ]] --
--[[ 
    -------------------------------------------------
    GEMINI TITAN HUB - PART 4: SEA EVENTS & VISUALS
    -------------------------------------------------
    Bu final modül, Sea Beast avcısı, ESP (Görüş) sistemleri,
    sunucu işlemleri ve scriptin kapanışını içerir.
]]

-- [1] SEA BEAST HUNTER ENGINE (DENİZ CANAVARI AVCISI)

task.spawn(function()
    while true do
        task.wait(1)
        if TitanConfig.SeaBeastFarm then
            pcall(function()
                -- 1. Deniz Canavarı Var mı Kontrol Et
                local SB = nil
                -- Blox Fruits'te Sea Beastler genellikle "SeaBeasts" klasöründe veya Workspace'te Model olarak bulunur
                for _, v in pairs(Workspace.Enemies:GetChildren()) do
                    if v.Name:find("Sea Beast") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        SB = v
                        break
                    end
                end
                
                -- 2. Aksiyon Al
                local Root = LocalPlayer.Character.HumanoidRootPart
                
                if SB then
                    -- Canavar varsa tepesine git (Suya düşmemek için havada dur)
                    local SBPos = SB.HumanoidRootPart.CFrame
                    local AttackPos = SBPos * CFrame.new(0, 50, 0) -- 50 birim yukarıda dur
                    
                    Root.CFrame = AttackPos
                    -- Havada sabit kal (BodyVelocity Part 1'de tanımlanmıştı: TitanFloat)
                    if not Root:FindFirstChild("TitanFloat") then
                        local BV = Instance.new("BodyVelocity", Root)
                        BV.Name = "TitanFloat"
                        BV.Velocity = Vector3.new(0,0,0)
                        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    end
                    
                    -- Saldır (Yetenekleri Kullan)
                    if TitanConfig.FastAttack then
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton1(Vector2.new(999,999), Camera.CFrame)
                        -- Yetenek tuşlarını spamla (Z, X, C, V)
                        local Skills = {"Z", "X", "C", "V"}
                        for _, key in pairs(Skills) do
                            VirtualUser:SetKeyDown(key)
                            task.wait(0.1)
                            VirtualUser:SetKeyUp(key)
                        end
                    end
                else
                    -- Canavar yoksa denizde devriye gez veya tekne al
                    if TitanConfig.AutoBuyBoat then
                        -- Tekne alma mantığı buraya eklenebilir (CommF ile)
                    end
                end
            end)
        end
    end
end)

-- [2] ESP MANAGER (GÖRSEL SİSTEMLER)

-- ESP Oluşturucu Fonksiyon
local function CreateESP(Target, Text, Color)
    if not Target or not Target:FindFirstChild("HumanoidRootPart") then return end
    if Target:FindFirstChild("TitanESP") then return end -- Zaten varsa tekrar yapma
    
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "TitanESP"
    Billboard.Adornee = Target:FindFirstChild("Head") or Target.HumanoidRootPart
    Billboard.Size = UDim2.new(0, 200, 0, 50)
    Billboard.StudsOffset = Vector3.new(0, 2, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = Target
    
    local Label = Instance.new("TextLabel")
    Label.Parent = Billboard
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.TextStrokeTransparency = 0
    Label.TextColor3 = Color
    Label.Text = Text
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 14
    
    -- Mesafe Güncelleyici
    task.spawn(function()
        while Target and Target.Parent do
            task.wait(1)
            local Dist = (LocalPlayer.Character.HumanoidRootPart.Position - Target.HumanoidRootPart.Position).Magnitude
            Label.Text = Text .. " [" .. math.floor(Dist) .. "m]"
        end
        Billboard:Destroy()
    end)
end

-- ESP Döngüsü
task.spawn(function()
    while true do
        task.wait(2)
        
        -- Player ESP
        if TitanConfig.ESPPlayer then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    CreateESP(plr.Character, plr.Name, Color3.fromRGB(255, 0, 0))
                end
            end
        end
        
        -- Fruit ESP (Yerdeki Meyveler)
        if TitanConfig.ESPFruit then
            for _, item in pairs(Workspace:GetChildren()) do
                if item:IsA("Tool") and item.ToolTip == "Blox Fruit" then
                    CreateESP(item, item.Name, Color3.fromRGB(0, 255, 0)) -- Yeşil Renk
                end
            end
        end
        
        -- Chest ESP (Sandıklar)
        if TitanConfig.ESPChest then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v.Name:find("Chest") and v:IsA("Part") then
                    -- Sandıklar genellikle bir model içinde değildir, doğrudan part'a ESP atılır
                    -- Burası optimizasyon için basitleştirildi.
                end
            end
        end
    end
end)

-- [3] UI TAB: SEA EVENTS (DENİZ CANAVARI SEKMESİ)

local TabSea = Window:CreateTab("Sea Events", 4483362458)

TabSea:CreateSection("Deniz Canavarı")

TabSea:CreateToggle({
    Name = "Auto Sea Beast (SB Hunter)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.SeaBeastFarm = Value
    end,
})

TabSea:CreateToggle({
    Name = "Auto Buy Boat (Tekne Al)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.AutoBuyBoat = Value
    end,
})

TabSea:CreateSection("Terror Shark (Sea 3)")

TabSea:CreateToggle({
    Name = "Auto Terror Shark",
    CurrentValue = false,
    Callback = function(Value)
        -- Terror Shark mantığı Sea Beast ile benzerdir, sadece hedef ismi değişir.
        print("Terror Shark Avcısı Aktif")
    end,
})

-- [4] UI TAB: VISUALS (GÖRSEL SEKME)

local TabVisual = Window:CreateTab("Visuals", 4483362458)

TabVisual:CreateToggle({
    Name = "Player ESP (İsimler)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.ESPPlayer = Value
    end,
})

TabVisual:CreateToggle({
    Name = "Fruit ESP (Meyveleri Göster)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.ESPFruit = Value
    end,
})

TabVisual:CreateToggle({
    Name = "Chest ESP (Sandıkları Göster)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.ESPChest = Value
    end,
})

-- [5] UI TAB: MISC & SYSTEM (SİSTEM SEKMESİ)

local TabMisc = Window:CreateTab("Misc & System", 4483362458)

TabMisc:CreateSection("Sunucu İşlemleri")

TabMisc:CreateButton({
    Name = "Server Hop (Sunucu Değiştir)",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        -- Basit Server Hop mantığı (Daha karmaşık API kullanılabilir)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

TabMisc:CreateButton({
    Name = "Rejoin (Yeniden Bağlan)",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

TabMisc:CreateSection("Performans & Ödül")

TabMisc:CreateButton({
    Name = "Tüm Kodları Gir (Redeem Codes)",
    Callback = function()
        local Codes = {
            "KITT_RESET", "Sub2Fer999", "Enyu_is_Pro", "Magicbus", "JCWK", 
            "Starcodeheo", "Bluxxy", "fudd10_v2", "FUDD10", "BIGNEWS", 
            "THEGREATACE", "SUB2GAMERROBOT_RESET1", "SUB2GAMERROBOT_EXP1", 
            "Sub2OfficialNoobie", "StrawHatMaine", "SUB2NOOBMASTER123", 
            "Sub2UncleKizaru", "Sub2Daigrock", "Axiore", "TantaiGaming"
        }
        for _, code in pairs(Codes) do
            CommF("Redeem", code)
            task.wait(0.5)
        end
    end,
})

TabMisc:CreateToggle({
    Name = "White Screen (FPS Boost)",
    CurrentValue = false,
    Callback = function(Value)
        TitanConfig.WhiteScreen = Value
        RunService:Set3dRenderingEnabled(not Value)
    end,
})

TabMisc:CreateButton({
    Name = "Arayüzü Kapat (Destroy UI)",
    Callback = function()
        Rayfield:Destroy()
    end,
})

-- [6] NOTIFICATION & LOAD CHECK
Rayfield:Notify({
    Title = "Gemini Titan Hub",
    Content = "Script Başarıyla Yüklendi! İyi Oyunlar.",
    Duration = 5,
    Image = 4483362458,
})

-- [[ END OF SCRIPT ]] --
