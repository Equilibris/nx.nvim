local readers = require 'nx.read-configs'

local w = vim.loop.new_fs_event()
local function on_change(err, fname, status)
	-- Do work...
	vim.api.nvim_command 'checktime'
	-- Debounce: stop/start.
	w:stop()

	_G.nx.log = _G.nx.log .. 'hello'

	_G.nx.watch_file(fname)
end
function _G.nx.watch_file(fname)
	local fullpath = vim.api.nvim_call_function('fnamemodify', { fname, ':p' })
	w:start(
		fullpath,
		{},
		vim.schedule_wrap(function(...)
			on_change(...)
		end)
	)
end
vim.api.nvim_command "command! -nargs=1 Watch call luaeval('_G.nx.watch_file(_A)', expand(''))"
