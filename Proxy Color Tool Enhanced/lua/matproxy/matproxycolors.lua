for i = 1, 10 do
	local slotName = "ColorSlot" .. i
	local nameKey, tickKey = slotName .. "Name", slotName .. "Tick"

	matproxy.Add( {
		name = slotName,
		init = function( self, mat, values )
			self.Name = values.name
			self.Color = values.resultvar
			self.FColor = values.fcolor and util.StringToType( values.fcolor, "Vector" )
		end,
		bind = function( self, mat, ent )
			if !IsValid( ent ) then return end
			if !ent[slotName] then ent[slotName] = self.FColor or Vector( 1, 1, 1 ) end
			ent[nameKey] = self.Name
			ent[tickKey] = CurTime()
			mat:SetVector( self.Color, ent[slotName] )
		end
	} )
end