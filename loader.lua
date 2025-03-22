if getgenv().gxxkware then
	print('script already running');
	return
end

local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

local Cam = workspace.CurrentCamera
local LocalPlr = Players.LocalPlayer
local LocalChar = LocalPlr.Character

local CustomWeaponGames = {
	10228136016, --Fallen
	5208655184, --Rogue
	7336302630; 7353845952, --Project Delta
}

local Script = {
	Connections = {},
	DrawingCache = {},
	Settings = {
		AccentColor = Color3.fromRGB(178, 139, 255),
		Font = Drawing.Fonts.Monospace,
		RenderDistance = 3000
	},
}

if not LocalChar then
	repeat
		task.wait();
		LocalChar = LocalPlr.Character
	until LocalChar ~= nil
end

function NewDrawing(Type, Props)
	local Drawing = Drawing.new(Type)

	for i, v in next, Props do
		Drawing[i] = v
	end

	return Drawing
end

function NewPlayerDrawing(EnemyPlr)
	Script.DrawingCache[EnemyPlr] = {
		Box = NewDrawing('Square', {
			Color = Script.Settings.AccentColor or Color3.new(1, 1, 1),
			Thickness = 1,
			ZIndex = 2
		}),
		BoxOutline = NewDrawing('Square', {
			Thickness = 3
		}),
		HealthBar = NewDrawing('Square', {
			Thickness = 1,
			ZIndex = 2
		}),
		HealthBarOutline = NewDrawing('Square', {
			Thickness = 3
		}),
		Name = NewDrawing('Text', {
			Color = Color3.new(1, 1, 1),
			Center = true,
			Font = Script.Settings.Font or Drawing.Fonts.Plex,
			Outline = true,
			Text = EnemyPlr.Name
		}),
		Distance = NewDrawing('Text', {
			Color = Color3.new(1, 1, 1),
			Center = true,
			Font = Script.Settings.Font or Drawing.Fonts.Plex,
			Outline = true
		}),
		Weapon = NewDrawing('Text', {
			Color = Color3.new(1, 1, 1),
			Center = true,
			Font = Script.Settings.Font or Drawing.Fonts.Plex,
			Outline = true
		})
	}
end

function RemovePlayerDrawing(EnemyPlr)
	if Script.DrawingCache[EnemyPlr] then
		for _, v in next, Script.DrawingCache[EnemyPlr] do
			v:Destroy()
		end

		Script.DrawingCache[EnemyPlr] = nil
	end
end

function ToggleDrawings(Drawings, State)
	for _, v in next, Drawings do
		v.Visible = State
	end
end

function HasWeapon(EnemyChar)
	--Fallen
	if game.PlaceId == 10228136016 then
		for _, v in next, EnemyChar:GetChildren() do
			if v:IsA('Model') and (v:FindFirstChild('Attachments') or v:FindFirstChild('Handle') and v.Name ~= 'HolsterModel') then
				return v.Name
			end
		end
	end
	--Rogue
	if game.PlaceId == 5208655184 then
		for _, v in next, EnemyChar:GetChildren() do
			if v:IsA('Tool') and (v:FindFirstChild('PrimaryWeapon') or v:FindFirstChild('Spell') or v:FindFirstChild('Skill')) then
				return v.Name
			end
		end
	end
	--Project Delta
	if game.PlaceId == 7336302630 or game.PlaceId == 7353845952 then
		for _, v in next, EnemyChar:GetChildren() do
			if v:IsA('Model') and v:FindFirstChild('ItemRoot') then
				return v.Name
			end
		end
	end

	return 'None'
end

function UpdateDrawings()
	for EnemyPlr, Drawings in next, Script.DrawingCache do
		if EnemyPlr ~= LocalPlr and EnemyPlr.Parent and EnemyPlr.Character and EnemyPlr.Character.Parent then
			local EnemyHum = EnemyPlr.Character:FindFirstChildOfClass('Humanoid')
			local EnemyRoot = EnemyPlr.Character:FindFirstChild('HumanoidRootPart')

			if EnemyHum.Parent and EnemyRoot.Parent and EnemyHum.Health >= 0 then
				local Distance = math.floor((Cam.CFrame.Position - EnemyRoot.Position).Magnitude + 0.5)
				local RootPos, InView = Cam:WorldToViewportPoint(EnemyRoot.Position)
				local DistanceScaling = 12 * 1 / (RootPos.Z * math.tan(math.rad(Cam.FieldOfView / 2)) * 2) * 100

				if not InView or Distance >= Script.Settings.RenderDistance then
					ToggleDrawings(Drawings, false);
					continue
				else
					ToggleDrawings(Drawings, true)
				end

				Drawings.Box.Position = Vector2.new(RootPos.X - DistanceScaling * 2, RootPos.Y - DistanceScaling * 3)
				Drawings.Box.Size = Vector2.new(DistanceScaling * 4, DistanceScaling * 6)

				Drawings.BoxOutline.Position = Drawings.Box.Position
				Drawings.BoxOutline.Size = Drawings.Box.Size

				Drawings.HealthBar.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), EnemyHum.Health / EnemyHum.MaxHealth)
				Drawings.HealthBar.Position = Vector2.new(Drawings.Box.Position.X - 8, (RootPos.Y + DistanceScaling * 3) - Drawings.HealthBar.Size.Y)
				Drawings.HealthBar.Size = Vector2.new(2, Drawings.Box.Size.Y * (EnemyHum.Health / EnemyHum.MaxHealth))

				Drawings.HealthBarOutline.Position = Drawings.Box.Position - Vector2.new(8, 0)
				Drawings.HealthBarOutline.Size = Vector2.new(2, Drawings.Box.Size.Y)

				Drawings.Name.Position = Vector2.new(RootPos.X, (RootPos.Y - DistanceScaling * 3) - Drawings.Name.TextBounds.Y)

				Drawings.Distance.Position = Vector2.new(RootPos.X, RootPos.Y + DistanceScaling * 3)
				Drawings.Distance.Text = Distance .. ' m'

				if table.find(CustomWeaponGames, game.PlaceId) then
					Drawings.Weapon.Position = Drawings.Distance.Position + Vector2.new(0, Drawings.Distance.TextBounds.Y)
					Drawings.Weapon.Text = HasWeapon(EnemyPlr.Character)
				else
					Drawings.Weapon.Visible = false
				end
			else
				ToggleDrawings(Drawings, false)
			end
		end
	end
end

for _, v in next, Players:GetPlayers() do
	NewPlayerDrawing(v)
end

table.insert(Script.Connections, Players.PlayerAdded:Connect(NewPlayerDrawing))
table.insert(Script.Connections, Players.PlayerRemoving:Connect(RemovePlayerDrawing))
table.insert(Script.Connections, RunService.RenderStepped:Connect(UpdateDrawings))

getgenv().gxxkware = {
	Disconnect = function()
		for _, v in next, Script.Connections do
			v:Disconnect()
		end
		
		cleardrawcache()
		getgenv().gxxkware = nil
	end,
	Script = Script
}
