local ENT_IsValid = FindMetaTable("Entity").IsValid
local SetVector = FindMetaTable("IMaterial").SetVector
local slotState, getState = ProxyColor.SlotState, ProxyColor.GetSlotState
local DEFAULT_COLOR = Vector(1, 1, 1)
local function addSlot(i)
	local function init(self, mat, values)
		self.Name = values.name
		self.Color = values.resultvar
		self.FColor = values.fcolor and util.StringToType(values.fcolor, "Vector") or DEFAULT_COLOR
	end

	local function bind(self, mat, ent)
		if !ent or !ENT_IsValid(ent) then return end

		local st = slotState[ent] or getState(ent)
		local colors = st.colors
		local color = colors[i]
		if !color then
			color = self.FColor
			colors[i] = color
		end

		st.names[i] = self.Name
		SetVector(mat, self.Color, color)
	end

	matproxy.Add({name = "ColorSlot" .. i, init = init, bind = bind})
end

for i = 1, NUM_SLOTS do
	addSlot(i)
end
