local utils = require 'nx.utils'
-- logging.lua

local _M = {}

-- Specify the log file path
local log_file_path = (vim.fn.stdpath 'data') .. '/nx.log'

local write = function(message)
	_G.nx.log = _G.nx.log .. message

	local file = io.open(log_file_path, 'a')
	if file then
		file:write(message)
		file:close()
	else
		print 'Error: Unable to open the log file'
	end
end

local create_level_fn = function(level)
	return function(message)
		if type(message) ~= 'string' then
			message = utils.dump(message, 2)
		end

		local msg = '['
			.. (os.date '%Y-%m-%d %H:%M:%S ')
			.. level
			.. '] '
			.. message
			.. '\n'

		write(msg)
	end
end

-- Function to write log messages to the log file
_M.log = create_level_fn 'LOG'
_M.warn = create_level_fn 'WARN'
_M.error = create_level_fn 'ERROR'

function _M.open()
	vim.cmd('edit ' .. log_file_path)
end

function _M.print_current()
	print(_G.nx.log)
end

return _M
