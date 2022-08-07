---@alias form_renderer fun(form: table, title: string | nil, callback: function, state: table)
---@class Config
---@field public nx_cmd_root string
---@field public command_runner function
---@field public form_renderer function
---@field public read_init boolean
local default_config = {
	nx_cmd_root = 'nx',
	command_runner = require('nx.command-runners').terminal_cmd(),
	form_renderer = require('nx.form-renderers').telescope(),
}

---@alias Generator { schema: table, name: string, run_cmd: string, package: string}
---@alias Generators { workspace: Generator[], external: Generator[] }
---@alias Cache { actions: table, targets: table }
---
---@class NxGlobal : Config
---@field public nx table
---@field public workspace table
---@field public package_json table
---@field public projects table
---@field public generators Generators
---@field public cache Cache
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
}

local readers = require 'nx.read-configs'

--- Setup NX and set its defaults
--- @param config table
local setup = function(config)
	config = config or {}

	if config.nx_cmd_root ~= nil then
		_G.nx.nx_cmd_root = config.nx_cmd_root
	else
		_G.nx.nx_cmd_root = default_config.nx_cmd_root
	end

	if config.command_runner ~= nil then
		_G.nx.command_runner = config.command_runner
	else
		_G.nx.command_runner = default_config.command_runner
	end

	if config.form_renderer ~= nil then
		_G.nx.form_renderer = config.form_renderer
	else
		_G.nx.form_renderer = default_config.form_renderer
	end

	if config.read_init or true then
		readers.read_nx_root()

		require 'nx.on-project-mod'()
	end
end

return { setup = setup }
