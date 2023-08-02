local _M = {}

local console = require 'nx.logging'

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values

local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

---Make generator entry
---
---@param entry table
---@return table
local make_entry = function(entry)
	local x = entry.package .. ' ' .. entry.name
	return {
		value = entry,
		display = x,
		ordinal = x,
	}
end

---Run a given generator
---@param generator Generator
_M.run_generator = function(generator)
	console.log 'Executing generator'
	console.log(generator)

	local initial_config = {}
	local accessor = generator.package .. ':' .. generator.name

	if _G.nx.nx.generators[accessor] ~= nil then
		initial_config = _G.nx.nx.generators[accessor]
	end
	if
		_G.nx.nx.generators[generator.package] ~= nil
		and _G.nx.nx.generators[generator.package][generator.name] ~= nil
	then
		initial_config = _G.nx.nx.generators[generator.package][generator.name]
	end

	console.log('Loading initial_config for ' .. accessor)
	console.log(initial_config)

	_G.nx.form_renderer(generator.schema, nil, function(form_result)
		local s = _G.nx.nx_cmd_root .. ' ' .. generator.run_cmd

		for key, value in pairs(form_result) do
			if value ~= nil then
				s = s .. ' --' .. key .. '=' .. tostring(value)
			end
		end

		_G.nx.command_runner(s)
	end, initial_config)
end
---Constructs a generator builder with a source generator
---
---@alias GeneratorSourceFun fun(): Generator[]
---@param source GeneratorSourceFun
---
---@return function
local generator_builder = function(source)
	return function(opts)
		opts = opts or {}

		pickers
			.new(opts, {
				prompt_title = 'Generators',
				finder = finders.new_table {
					results = source(),
					entry_maker = make_entry,
				},
				sorter = conf.generic_sorter(opts),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection =
							action_state.get_selected_entry().value

						_M.run_generator(selection)
					end)
					return true
				end,
			})
			:find()
	end
end

---Prompts workspace generators
---
---@type function
_M.workspace_generators = generator_builder(function()
	return _G.nx.generators.workspace
end)

---Prompts external generators
---
---@type function
_M.external_generators = generator_builder(function()
	return _G.nx.generators.external
end)

---Prompts generators
---
---@type function
_M.generators = generator_builder(function()
	local x = {}
	for _, value in ipairs(_G.nx.generators.external) do
		table.insert(x, value)
	end
	for _, value in ipairs(_G.nx.generators.workspace) do
		table.insert(x, value)
	end
	return x
end)

return _M
