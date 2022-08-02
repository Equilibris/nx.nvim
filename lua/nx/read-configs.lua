local rf = function(fname)
	local f = io.open(fname, 'r')

	if f == nil then
		return nil
	end

	local s = f:read 'a'

	local table = vim.json.decode(s)

	return table
end

local read_nx = function()
	_G.nx.nx = rf './nx.json'
end

local read_workspace = function()
	_G.nx.nx = rf './workspace.json'
end

local read_projects = function()
	for key, value in pairs(_G.nx.workspace.projects or {}) do
		local v = rf(value .. '/project.json')

		_G.nx.projects[key] = v
	end
end

local read_nx_root = function()
	read_nx()
	read_workspace()

	read_projects()
end

return {
	rf = rf,
	read_workspace = read_workspace,
	read_nx = read_nx,
	read_projects = read_projects,

	read_nx_root = read_nx_root,
}
