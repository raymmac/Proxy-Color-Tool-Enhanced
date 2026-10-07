ProxyColor = istable(ProxyColor) and ProxyColor or {}
NUM_SLOTS = 10
local ENTITY = FindMetaTable("Entity")
local slotState = ProxyColor.SlotState or setmetatable({}, {__mode = "k"})
ProxyColor.SlotState = slotState
local function getState(ent)
	local st = slotState[ent]
	if !st then
		st = {colors = {}, names = {}}
		slotState[ent] = st
	end
	return st
end

local function applyColorSlots(ent, ct)
	ent.ColorTable = ct
	local colors = getState(ent).colors
	for i = 1, NUM_SLOTS do
		if ct[i] then colors[i] = ct[i] end
	end
end

local function getProxyColor(self)
	return self.ColorTable
end

local function setProxyColor(self, ColorTable)
	if !ColorTable then return end

	for i = 1, NUM_SLOTS do
		if IsColor(ColorTable[i]) then ColorTable[i] = ColorTable[i]:ToVector() end
	end

	applyColorSlots(self, ColorTable)

	if SERVER then
		net.Start("NAKProxyColorSync")
			net.WriteUInt(self:EntIndex(), 16)
			net.WriteTable(ColorTable)
		net.Broadcast()

		duplicator.StoreEntityModifier(self, "proxycolor", ColorTable)
	end
end

local function onDupe(ply, ent, ct)
	ent:SetProxyColor(ct)
end

local function onSync()
	local entID = net.ReadUInt(16)
	local ct = net.ReadTable()
	local ent = Entity(entID)

	if IsValid(ent) then
		applyColorSlots(ent, ct)
		return
	end

	local timerName = "PrxyClr_" .. entID
	timer.Create(timerName, 0.1, 30, function()
		ent = Entity(entID)
		if !IsValid(ent) then return end

		timer.Remove(timerName)
		applyColorSlots(ent, ct)
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

ProxyColor.GetSlotState = getState
ENTITY.GetProxyColor = getProxyColor
ENTITY.SetProxyColor = setProxyColor
duplicator.RegisterEntityModifier("proxycolor", onDupe)

if SERVER then
	AddCSLuaFile("matproxy/matproxycolors.lua")
	AddCSLuaFile("weapons/gmod_tool/stools/proxycolorenhanced.lua")
	util.AddNetworkString("NAKProxyColorSync")
else
	net.Receive("NAKProxyColorSync", onSync)
	include("matproxy/matproxycolors.lua")
end
