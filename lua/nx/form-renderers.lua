-- Form renderers take a JSON schema as an input and must emit a table as an output
--
-- The telescope form renderer is composed of two components
--
-- 1. A general renderer;
--		a component that renders all the options viewed from coposition
-- 2. A component renderer;
--		a component that renders induvitual components standalone

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local utils = require 'nx.utils'
local console = require 'nx.logging'

local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local _M = {}

---Make entry for object handeler
---@param opts table
---@param internal_state table
---@return fun(entry: table): table
local make_entry = function(opts, internal_state)
	return function(entry)
		if entry.is_done then
			return { value = entry, display = 'Submit', ordinal = 'Submit' }
		else
			local x = entry.key
				.. (entry.required and '*' or '')
				.. ' :: '
				.. entry.type

			local mod = internal_state[entry.key] ~= nil
					and ' ( ' .. (tostring(internal_state[entry.key])) .. ' )'
				or ''
			return { value = entry, display = x .. mod, ordinal = x }
		end
	end
end

local get_enum_values_from_form = function(form)
	local enum_value = form.enum
		or (
			form['$default'] ~= nil
			and form['$default']['$source'] == 'projectName'
			and _G.nx.graph
			and utils.keys(_G.nx.graph.graph.nodes)
		)
	return enum_value
end

---Construct and bootstrap a form-renderer using telescope
---@param opts table | nil
---@return form_renderer
function _M.telescope(opts)
	---@type form_renderer
	local renderer

	local object_handeler = function(form, title, callback, state)
		local keys = {}

		local supplied_req = 0
		local required = form.required or {}
		local set = {}

		for _, value in ipairs(required) do
			set[value] = true
		end

		for key, value in pairs(form.properties) do
			table.insert(keys, {
				type = value.type,
				key = key,
				required = set[key] or false,
			})

			if state[key] == nil and value.default ~= nil then
				state[key] = value.default
			end
			if set[key] and state[key] then
				supplied_req = supplied_req + 1
			end
		end

		if supplied_req == #required then
			table.insert(keys, { is_done = true })
		end

		local object_picker = pickers.new(opts, {
			prompt_title = title,

			finder = finders.new_table {
				results = keys,
				entry_maker = make_entry(opts, state),
			},
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry().value

					if selection.is_done then
						callback(state)
					else
						renderer(
							form.properties[selection.key],
							title .. '.' .. selection.key,
							function(value)
								state[selection.key] = value

								renderer(form, title, callback, state)
							end,
							state[selection.key]
						)
					end
				end)

				return true
			end,
		})

		object_picker:find()
	end

	local string_handler = function(form, title, callback, state)
		local is_multi = form.is_arr_item or false

		local enum_value = get_enum_values_from_form(form)

		if enum_value then
			local enum_picker = pickers.new(opts, {
				prompt_title = title,
				finder = finders.new_table {
					results = enum_value,
				},
				sorter = conf.generic_sorter(opts),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						local selection = is_multi
								and action_state
									.get_current_picker(prompt_bufnr)
									:get_multi_selection()
							or action_state.get_selected_entry().value

						actions.close(prompt_bufnr)
						callback(selection)
					end)

					return true
				end,
			})
			enum_picker:find()
		else
			local value = vim.fn.input(title .. ': ', state or '')
			callback(value)
		end
	end

	local boolean_handeler = function(form, title, callback, state)
		local bool_picker = pickers.new(opts, {
			prompt_title = title,
			finder = finders.new_table {
				results = { true, false },
				entry_maker = function(entry)
					if entry then
						return {
							value = entry,
							display = 'true',
							ordinal = 'trueyes1',
						}
					else
						return {
							value = entry,
							display = 'false',
							ordinal = 'falseno0',
						}
					end
				end,
			},
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry().value
					callback(selection)
				end)

				return true
			end,
		})
		bool_picker:find()
	end

	renderer = function(form, title, callback, state)
		title = title or form['$id'] or 'MISSING TITLE'

		console.log('Executing form renderer for form ' .. title)
		console.log 'Initial State:'
		console.log(state)

		console.log 'Form config:'
		console.log(form)

		local type = form.type

		if type == 'object' then
			object_handeler(form, title, callback, state)
		elseif type == 'string' then
			string_handler(form, title, callback, state)
		elseif type == 'number' then
			local value = vim.fn.input(title .. ' (numeric): ', state or '')

			callback(tonumber(value))
		elseif type == 'array' then
			local nf = form.items
			nf.is_arr_item = true

			renderer(nf, title, callback, {})
		elseif type == 'boolean' then
			boolean_handeler(form, title, callback, state)
		end
	end

	return renderer
end

return _M
