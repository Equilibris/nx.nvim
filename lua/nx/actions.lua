local _M = {}

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values

local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

---Runs designated action
---@param action string
function _M.run_action(action)
	_G.nx.command_runner(_G.nx.nx_cmd_root .. ' run ' .. action)
end

---Prompts user for actions
---@param opts table
function _M.actions_finder(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = 'Run Action',
			finder = finders.new_table {
				results = _G.nx.cache.actions,
			},
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					_M.run_action(selection[1])
					-- print(vim.inspect(selection))
				end)
				return true
			end,
		})
		:find()
end

return _M
