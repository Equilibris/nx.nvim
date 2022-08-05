local nx = require 'nx'

_G.dump = function(o, level)
	level = level or 1

	local indent = string.rep('  ', level)

	if type(o) == 'table' then
		local s = '{\n'
		for k, v in pairs(o) do
			if type(k) ~= 'number' then
				k = '"' .. k .. '"'
			end
			s = s .. indent .. '[' .. k .. '] = ' .. dump(v, level + 1) .. ',\n'
		end
		return s .. indent .. '}'
	else
		return tostring(o)
	end
end

_G.pd = function(o)
	print(dump(o))
end

nx.setup {}
