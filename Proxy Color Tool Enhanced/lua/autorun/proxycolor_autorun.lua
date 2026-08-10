ProxyColor = istable(ProxyColor) and ProxyColor or {}
NUM_SLOTS = 10

if SERVER then
	AddCSLuaFile("matproxy/matproxycolors.lua")
	AddCSLuaFile("weapons/gmod_tool/stools/proxycolorenhanced.lua")
	util.AddNetworkString("NAKProxyColorSync")
else
	include("matproxy/matproxycolors.lua")
end

local Entity = FindMetaTable("Entity")

local function ApplyColorSlots(ent, ct)
	ent.ColorTable = ct
	for i = 1, NUM_SLOTS do
		if ct[i] then ent["ColorSlot" .. i] = ct[i] end
	end
end

function Entity:GetProxyColor()
	return self.ColorTable
end

function Entity:SetProxyColor(ColorTable)
	if !ColorTable then return end

	for i = 1, NUM_SLOTS do
		if IsColor(ColorTable[i]) then ColorTable[i] = ColorTable[i]:ToVector() end
	end

	ApplyColorSlots(self, ColorTable)

	if SERVER then
		net.Start("NAKProxyColorSync")
			net.WriteUInt(self:EntIndex(), 16)
			net.WriteTable(ColorTable)
		net.Broadcast()

		duplicator.StoreEntityModifier(self, "proxycolor", ColorTable)
	end
end

duplicator.RegisterEntityModifier("proxycolor", function(ply, ent, ct)
	ent:SetProxyColor(ct)
end)

if CLIENT then
	net.Receive("NAKProxyColorSync", function()
		local entID = net.ReadUInt(16)
		local ct = net.ReadTable()
		local ent = ents.GetByIndex(entID)

		if IsValid(ent) then
			ApplyColorSlots(ent, ct)
			return
		end

		local timerName = "PrxyClr_" .. entID
		timer.Create(timerName, 0.1, 30, function()
			ent = ents.GetByIndex(entID)
			if !IsValid(ent) then return end

			timer.Remove(timerName)
			ApplyColorSlots(ent, ct)
		end)
	end)
end

function ProxyColor.RandFromTable(ent, ctable, spawnonly)
	if spawnonly and ent.ColorTable then return end
	ent:SetProxyColor(ctable[math.random(1, #ctable)])
end

function ProxyColor.Random(ent, spawnonly)
	if spawnonly and ent.ColorTable then return end
	local ColorTable = {}
	for i = 1, NUM_SLOTS do
		local vect = VectorRand(0, 255)
		vect:Normalize()
		ColorTable[i] = vect:ToColor()
	end
	ent:SetProxyColor(ColorTable)
end
