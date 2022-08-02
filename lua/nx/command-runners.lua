local toggleterm_runner = function(config)
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

local terminal_command_runner = function()
	return function(command)
		vim.cmd('terminal ' .. command)
	end
end

return {
	toggleterm_runner = toggleterm_runner,
	terminal_command_runner = terminal_command_runner,
}
