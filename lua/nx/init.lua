_G.nx = {
	workspace = nil,
	nx = nil,
	projects = {},

	cache = { actions = {} },

	log = '',

	nx_cmd_root = 'nx',
	command_runner = require('nx.command-runners').terminal_command_runner(),
}

local readers = require 'nx.read-configs'

local setup = function(config)
	config = config or {}

	if config.nx_cmd_root ~= nil then
		_G.nx.nx_cmd_root = config.nx_cmd_root
	end
	if config.command_runner ~= nil then
		_G.nx.command_runner = config.command_runner
	end

	if config.read_init or true then
		readers.read_nx_root()

		require 'nx.on-project-mod'()
	end
end

return { setup = setup }
