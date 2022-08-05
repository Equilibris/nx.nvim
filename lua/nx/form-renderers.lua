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

local entry_display = require 'telescope.pickers.entry_display'

local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local _M = {}

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
					and ' ( ' .. tostring(internal_state[entry.key]) .. ' )'
				or ''
			return { value = entry, display = x .. mod, ordinal = x }
		end
	end
	-- local displayer = entry_display.create {
	-- 	separator = ' ',
	-- 	items = {
	-- 		{ width = 8 },
	-- 		{ remaining = true },
	-- 	},
	-- }

	-- return function(entry)
	-- 	if entry.is_done then
	-- 		return displayer {
	-- 			{ '', 'TelescopeResultsIdentifier' },
	-- 			'submit',
	-- 		}
	-- 	else
	-- 		return displayer {
	-- 			{ entry.type, 'TelescopeResultsIdentifier' },
	-- 			entry.key,
	-- 		}
	-- 	end
	-- end
end

_M.telescope_form_renderer = function(opts)
	local renderer

	renderer = function(form, title, callback, state)
		title = title or form['$id']

		local type = form.type

		if type == 'object' then
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
						local selection =
							action_state.get_selected_entry().value

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
		elseif type == 'string' then
			if
				form['$default'] ~= nil
				and _G.nx.workspace
				and form['$default']['$source'] == 'projectName'
			then
				local projects = {}
				for key, _ in pairs(_G.nx.projects) do
					table.insert(projects, key)
				end

				local project_picker = pickers.new(opts, {
					prompt_title = title,
					finder = finders.new_table {
						results = projects,
					},
					sorter = conf.generic_sorter(opts),
					attach_mappings = function(prompt_bufnr, map)
						actions.select_default:replace(function()
							actions.close(prompt_bufnr)
							local selection =
								action_state.get_selected_entry().value
							callback(selection)
						end)

						return true
					end,
				})
				project_picker:find()
			else
				local value = vim.fn.input(title .. ': ', state or '')
				callback(value)
			end
		elseif type == 'number' then
			local value = vim.fn.input(title .. ' (numeric): ', state or '')

			callback(tonumber(value))
		elseif type == 'boolean' then
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
						local selection =
							action_state.get_selected_entry().value
						callback(selection)
					end)

					return true
				end,
			})
			bool_picker:find()
		end
	end

	return renderer
end

return _M
