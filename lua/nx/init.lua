_G.nx = {
	workspace = nil,
	nx = nil,
	package_json = nil,
	projects = {},

	generators = {
		workspace = {},
		external = {},
	},

	cache = { actions = {}, targets = {} },

	log = '',

	nx_cmd_root = 'nx',
	command_runner = require('nx.command-runners').terminal_command_runner(),
	form_renderer = require('nx.form-renderers').telescope_form_renderer(),
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
	if config.form_renderer ~= nil then
		_G.nx.form_renderer = config.form_renderer
	end

	if config.read_init or true then
		readers.read_nx_root()

		require 'nx.on-project-mod'()
	end
end

return { setup = setup }
