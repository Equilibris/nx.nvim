local console = require 'nx.logging'

local _M = {}

function _M.toggleterm_runner(config)
	config = config
		or {
			direction = 'float',
			count = 1,
			close_on_exit = false,
		}

	local terms = {}

	return function(command)
		if terms[command] ~= nil then
			terms[command]:toggle()
		else
			local Terminal = require('toggleterm.terminal').Terminal
			local term = Terminal:new {
				cmd = command,
				on_close = function()
					terms[command] = nil
				end,
				config,
			}
			term:toggle()
		end
	end
end

function _M.terminal_cmd()
	return function(command)
		console.log 'Running command:'
		console.log(command)

		vim.cmd('terminal ' .. command)
	end
end

return _M
