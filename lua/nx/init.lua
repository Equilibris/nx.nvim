_G.nx = {
	workspace = nil,
	nx = nil,
	log = ' ',
}

local readers = require 'nx.read-configs'

local setup = function(config)
	if config.read_init or false then
		readers.read_nx_root()
	end

	if config.register_tert or true then
		print 'hello world'
	end
end

return { setup = setup }
