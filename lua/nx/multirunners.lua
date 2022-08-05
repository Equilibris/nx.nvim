local _M = {}

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values

local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local deepcopy =function (orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

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
					"$source": "argv",
					"index": 0
				}
			}
		},
		"projects": {
			"type": "array",
			"items": {
				"type": "string",
				"$default": {
					"$source": "argv",
					"index": 0
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
		"paralell": {
		"type": "number",
			"default": 3
		},
		"routing": {
			"type": "boolean",
			"default": false
		}
	}
}
]]

_M.run_many = function(opts)
	opts = opts or {}
	pickers.new(opts, {
		prompt_title = 'Pick target',
		finder = finders.new_table {
			results = _G.nx.cache.targets_flat,
		},
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry().value

				local config = multirun_schema

				local _configurations = _G.nx.cache.actions[selection]
				local configurations = {}

				for key, _ in pairs(_configurations) do
					table.insert(key)
				end

				-- print(vim.inspect(selection))

				-- _G.nx.command_runner(
				-- 	_G.nx.nx_cmd_root .. ' run ' .. selection[1]
				-- )
			end)
			return true
		end,
	}):find()
end

_G.test = function()
	_M.run_many()
end

return _M
