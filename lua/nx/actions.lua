local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values

local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

-- our picker function: colors
local actions_finder = function(opts)
	opts = opts or {}
	pickers.new(opts, {
		prompt_title = 'Run Action',
		finder = finders.new_table {
			results = _G.nx.cache.actions,
		},
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				-- print(vim.inspect(selection))
				_G.nx.command_runner(
					_G.nx.nx_cmd_root .. ' run ' .. selection[1]
				)
			end)
			return true
		end,
	}):find()
end

return {
	actions_finder = actions_finder,
}
