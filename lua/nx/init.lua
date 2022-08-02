_G.nx = {
	workspace = nil,
	nx = nil,
	projects = {},

	cache = { actions = {} },

	log = '',
}

_G.dump = function(o)
	if type(o) == 'table' then
		local s = '{ '
		for k, v in pairs(o) do
			if type(k) ~= 'number' then
				k = '"' .. k .. '"'
			end
			s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

local readers = require 'nx.read-configs'

local setup = function(config)
	config = config or {}

	if config.read_init or true then
		readers.read_nx_root()

		require 'nx.on-project-mod'()
	end
end

return { setup = setup }
