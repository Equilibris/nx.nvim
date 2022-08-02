_G.nx = {
	workspace = nil,
	nx = nil,
	projects = {},

	cache = { actions = {} },
}

local readers = require 'nx.read-configs'

local setup = function(config)
	if config.read_init or true then
		readers.read_nx_root()

		require 'nx.on-project-mod'()
	end
end

return { setup = setup }
