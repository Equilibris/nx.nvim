local _M = {}

local utils = require 'nx.utils'

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values

local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local multirun_schema = vim.json.decode [[
{
  "$schema": "http://json-schema.org/schema",
  "cli": "nx",
  "$id": "app",
  "type": "object",
  "properties": {
		"exclude": {
			"type": "array",
			"items": {
				"type": "string",
				"$default": {
					"$source": "projectName"
				}
			}
		},
		"projects": {
			"type": "array",
			"items": {
				"type": "string",
				"$default": {
					"$source": "projectName"
				}
			}
		},
		"all": {
			"type": "boolean"
		},
		"only-failed": {
			"type": "boolean"
		},
		"verbose": {
			"type": "boolean"
		},
		"skip-nx-cache": {
			"type": "boolean"
		},
		"parallel": {
			"type": "number",
			"default": 3
		}
	}
}
]]

local multi_builder = function(title, cmd)
	return function(opts)
		opts = opts or {}
		pickers.new(opts, {
			prompt_title = 'Pick target for ' .. title,
			finder = finders.new_table {
				results = utils.keys(_G.nx.cache.targets),
			},
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry().value

					local config = multirun_schema

					local configs = utils.keys(_G.nx.cache.targets[selection])
					if #configs > 0 then
						config.properties.configuration = {
							type = 'string',
							enum = configs,
						}
					end

					_G.nx.form_renderer(
						config,
						title .. ' options',
						function(form_result)
							if form_result.exclude then
								form_result.exclude = table.concat(
									form_result.exclude,
									','
								)
							end
							if form_result.exclude then
								form_result.projects = table.concat(
									form_result.projects,
									','
								)
							end

							local s = _G.nx.nx_cmd_root
								.. ' '
								.. cmd
								.. ' --target='
								.. selection

							for key, value in pairs(form_result) do
								if value ~= nil then
									s = s
										.. ' --'
										.. key
										.. '='
										.. tostring(value)
								end
							end

							_G.nx.command_runner(s)
						end,
						{}
					)
				end)
				return true
			end,
		}):find()
	end
end

_M.run_many = multi_builder('Run many', 'run-many')
_M.affected = multi_builder('Run many', 'affected')

return _M
