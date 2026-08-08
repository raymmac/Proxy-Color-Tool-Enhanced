TOOL.Category = "Render"
TOOL.Name = "Proxy Color Tool Enhanced"

local NUM_SLOTS = 10
local TickKey = {}
for i = 1, NUM_SLOTS do
	TickKey[i] = "ColorSlot"..i.."Tick"
end

for i = 1, NUM_SLOTS do
	TOOL.ClientConVar[ "cs"..i.."_r" ] = 255
	TOOL.ClientConVar[ "cs"..i.."_g" ] = 255
	TOOL.ClientConVar[ "cs"..i.."_b" ] = 255
end
TOOL.CurEntity = nil

if CLIENT then
	language.Add("tool.proxycolorenhanced.name", "Proxy Color Tool Enhanced")
	language.Add("tool.proxycolorenhanced.desc", "Set colors for a supported object")
	language.Add("tool.proxycolorenhanced.Color multiplier.help", "Easy shade/intensity")
	language.Add("tool.proxycolorenhanced.reload", "Reset color scheme")
	language.Add("tool.proxycolorenhanced.right", "Copy color scheme")
	language.Add("tool.proxycolorenhanced.left", "Select object")

	local function RequestApply()
		if timer.Exists("ProxyColorApply") then return end
		timer.Create("ProxyColorApply", 0, 1, function()
			net.Start("NAKProxyColorApply")
			net.SendToServer()
		end)
	end

	for i = 1, NUM_SLOTS do
		for channel in ("rgb"):gmatch(".") do
			cvars.AddChangeCallback( "proxycolorenhanced_cs"..i.."_"..channel, RequestApply, "proxycolor_live" )
		end
	end
end

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "right" },
	{ name = "reload" }
}

local function ResolveEntity( trace )
	local ent = trace.Entity
	if IsValid( ent.AttachedEntity ) then ent = ent.AttachedEntity end

	if ent:GetClass() == "gmod_sent_vehicle_fphysics_wheel" then
		ent = ent:GetChildren()[2]
	end

	return ent
end

function TOOL:LeftClick( trace )
	local ent = ResolveEntity( trace )
	if !IsValid( ent ) then return end

	self:GetWeapon():SetNWEntity( "CurEntity", ent )
	if CLIENT then
		self:GetWeapon():EmitSound( "garrysmod/content_downloaded.wav", 75, 100, 1, CHAN_WEAPON )
	end
	return true
end

if SERVER then
	util.AddNetworkString("NAKProxyColorApply")
	net.Receive("NAKProxyColorApply", function(len, ply)
		local tool = ply:GetTool("proxycolorenhanced")
		if !tool then return end

		local ent = tool:GetWeapon():GetNWEntity("CurEntity")
		if !IsValid(ent) then return end

		local ColorTable = {}
		for i = 1, NUM_SLOTS do
			ColorTable[i] = Color(
				tool:GetClientNumber( "cs"..i.."_r", 0 ),
				tool:GetClientNumber( "cs"..i.."_g", 0 ),
				tool:GetClientNumber( "cs"..i.."_b", 0 )
			)
		end

		ent:SetProxyColor( ColorTable )
	end)
end

function TOOL:RightClick( trace )
	local ent = ResolveEntity( trace )
	if !IsValid( ent ) then return end

	local CT = ent:GetProxyColor()
	if !CT then return end

	for i = 1, NUM_SLOTS do
		local vec = CT[i] or Vector(1,1,1)
		self:GetOwner():ConCommand( "proxycolorenhanced_cs"..i.."_r " .. vec.x*255 )
		self:GetOwner():ConCommand( "proxycolorenhanced_cs"..i.."_g " .. vec.y*255 )
		self:GetOwner():ConCommand( "proxycolorenhanced_cs"..i.."_b " .. vec.z*255 )
	end

	return true
end

function TOOL:Reload( trace )
	if CLIENT then return true end

	local ent = ResolveEntity( trace )
	if !IsValid( ent ) then return end

	local ColorTable = {}
	for i = 1, NUM_SLOTS do
		ColorTable[i] = Color(255,255,255)
	end

	ent:SetProxyColor( ColorTable )
	return true
end

function TOOL:Think()
	if !CLIENT then return end

	local ent = self:GetWeapon():GetNWEntity("CurEntity")
	if ent != self.CurEntity then
		self.CurEntity = ent
		self.SlotMask = nil
		self:UpdateControlPanel()
		return
	elseif !IsValid(ent) then return end

	local now = CurTime()
	local mask = {}
	local changed = false

	for i = 1, NUM_SLOTS do
		local last = ent[TickKey[i]]
		mask[i] = last and (now - last < .1) or false
		if !self.SlotMask or mask[i] != self.SlotMask[i] then changed = true end
	end

	if changed then
		self.SlotMask = mask
		self:UpdateControlPanel()
	end
end

function TOOL:UpdateControlPanel()
	local CPanel = controlpanel.Get( "proxycolorenhanced" )
	CPanel:ClearControls()
	self.BuildCPanel( CPanel, self.CurEntity, self.SlotMask )
end

local function AddColorSlotPanel( i, CPanel, name )
	if !name then return end

	local collapse = vgui.Create("DCollapsibleCategory")
	collapse:SetLabel(name)
	CPanel:AddItem(collapse)

	local list = vgui.Create("DPanelList", collapse)
	list:SetHeight(250)
	list:SetPadding(10)
	list:Dock(TOP)
	collapse:InvalidateLayout(true)

	local mixer = vgui.Create( "DColorMixer" )
	mixer:SetLabel(name)
	mixer:SetPalette( true )
	mixer:SetAlphaBar( false )
	mixer:SetWangs( true )
	mixer:SetConVarR("proxycolorenhanced_cs"..i.."_r")
	mixer:SetConVarG("proxycolorenhanced_cs"..i.."_g")
	mixer:SetConVarB("proxycolorenhanced_cs"..i.."_b")
	list:AddItem(mixer)
	collapse:SetExpanded(true)
end

local ConVarsDefault = TOOL:BuildConVarList()
function TOOL.BuildCPanel( CPanel, Selected, Mask )
	CPanel:AddControl( "Header", { Description = "#tool.proxycolorenhanced.desc" } )
	CPanel:AddControl( "ComboBox", { MenuButton = 1, Folder = "proxycolorenhanced", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )

	if !Selected or !Mask then return end

	for i = 1, NUM_SLOTS do
		if Mask[i] then
			AddColorSlotPanel( i, CPanel, Selected["ColorSlot"..i.."Name"] )
		end
	end
end