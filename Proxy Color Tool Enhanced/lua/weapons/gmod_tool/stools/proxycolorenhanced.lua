TOOL.Category = "Render"
TOOL.Name = "Proxy Color Tool Enhanced"
TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "right" },
	{ name = "reload" }
}

local CHANNELS = { "r", "g", "b" }
local slotState = ProxyColor.SlotState
local SLOT_CVARS = {}
for i = 1, NUM_SLOTS do
	local cvars_i = {}
	for c = 1, 3 do
		local name = "cs" .. i .. "_" .. CHANNELS[c]
		cvars_i[c] = name
		TOOL.ClientConVar[ name ] = 255
	end
	SLOT_CVARS[i] = cvars_i
end

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

function TOOL:RightClick( trace )
	local ent = ResolveEntity( trace )
	if !IsValid( ent ) then return end

	local CT = ent:GetProxyColor()
	if !CT then return end

	local owner = self:GetOwner()
	for i = 1, NUM_SLOTS do
		local vec = CT[i] or Vector( 1, 1, 1 )
		local cv = SLOT_CVARS[i]
		owner:ConCommand( "proxycolorenhanced_" .. cv[1] .. " " .. vec.x * 255 )
		owner:ConCommand( "proxycolorenhanced_" .. cv[2] .. " " .. vec.y * 255 )
		owner:ConCommand( "proxycolorenhanced_" .. cv[3] .. " " .. vec.z * 255 )
	end

	return true
end

function TOOL:Reload( trace )
	if CLIENT then return true end

	local ent = ResolveEntity( trace )
	if !IsValid( ent ) then return end

	local ColorTable = {}
	for i = 1, NUM_SLOTS do
		ColorTable[i] = Color( 255, 255, 255 )
	end

	ent:SetProxyColor( ColorTable )
	return true
end

function TOOL:Think()
	if SERVER then return end

	local ent = self:GetWeapon():GetNWEntity( "CurEntity" )
	local st = slotState[ent]
	local count = 0
	if st then
		local names = st.names
		for i = 1, NUM_SLOTS do
			if names[i] then count = count + 1 end
		end
	end

	if ent == self.CurEntity and count == self.SlotCount then return end
	self.CurEntity, self.SlotCount = ent, count
	self:UpdateControlPanel()
end

function TOOL:UpdateControlPanel()
	local CPanel = controlpanel.Get( "proxycolorenhanced" )
	CPanel:ClearControls()
	self.BuildCPanel( CPanel, self.CurEntity )
end

local function AddColorSlotPanel( i, CPanel, name )
	local collapse = vgui.Create( "DCollapsibleCategory" )
	collapse:SetLabel( name )
	CPanel:AddItem( collapse )

	local list = vgui.Create( "DPanelList", collapse )
	list:SetHeight( 250 )
	list:SetPadding( 10 )
	list:Dock( TOP )
	collapse:InvalidateLayout( true )

	local cv = SLOT_CVARS[i]
	local mixer = vgui.Create( "DColorMixer" )
	mixer:SetLabel( name )
	mixer:SetPalette( true )
	mixer:SetAlphaBar( false )
	mixer:SetWangs( true )
	mixer:SetConVarR( "proxycolorenhanced_" .. cv[1] )
	mixer:SetConVarG( "proxycolorenhanced_" .. cv[2] )
	mixer:SetConVarB( "proxycolorenhanced_" .. cv[3] )
	list:AddItem( mixer )
	collapse:SetExpanded( true )
end

local ConVarsDefault = TOOL:BuildConVarList()
function TOOL.BuildCPanel( CPanel, Selected )
	CPanel:AddControl( "Header", { Description = "#tool.proxycolorenhanced.desc" } )
	CPanel:AddControl( "ComboBox", { MenuButton = 1, Folder = "proxycolorenhanced", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )

	local st = Selected and slotState[Selected]
	if !st then return end

	local names = st.names
	for i = 1, NUM_SLOTS do
		if names[i] then
			AddColorSlotPanel( i, CPanel, names[i] )
		end
	end
end

if SERVER then
	local function onApply( len, ply )
		local tool = ply:GetTool( "proxycolorenhanced" )
		if !tool then return end

		local ent = tool:GetWeapon():GetNWEntity( "CurEntity" )
		if !IsValid( ent ) then return end

		local ColorTable = {}
		for i = 1, NUM_SLOTS do
			local cv = SLOT_CVARS[i]
			ColorTable[i] = Color( tool:GetClientNumber( cv[1], 0 ), tool:GetClientNumber( cv[2], 0 ), tool:GetClientNumber( cv[3], 0 ) )
		end

		ent:SetProxyColor( ColorTable )
	end

	util.AddNetworkString( "NAKProxyColorApply" )
	net.Receive( "NAKProxyColorApply", onApply )
else
	language.Add( "tool.proxycolorenhanced.name", "Proxy Color Tool Enhanced" )
	language.Add( "tool.proxycolorenhanced.desc", "Set colors for a supported object" )
	language.Add( "tool.proxycolorenhanced.reload", "Reset color scheme" )
	language.Add( "tool.proxycolorenhanced.right", "Copy color scheme" )
	language.Add( "tool.proxycolorenhanced.left", "Select object" )

	local function sendApply()
		net.Start( "NAKProxyColorApply" )
		net.SendToServer()
	end

	local function requestApply()
		timer.Create( "ProxyColorApply", 0, 1, sendApply )
	end

	for i = 1, NUM_SLOTS do
		local cv = SLOT_CVARS[i]
		for c = 1, 3 do
			cvars.AddChangeCallback( "proxycolorenhanced_" .. cv[c], requestApply, "proxycolor_live" )
		end
	end
end
