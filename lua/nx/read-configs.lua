local utils = require 'nx.utils'
local _M = {}

_M.scandir = function(directory)
	local t, popen = {}, io.popen
	local pfile = popen('ls -a "' .. directory .. '"')
	if pfile == nil then
		return {}
	end

	for filename in pfile:lines() do
		table.insert(t, filename)
	end
	pfile:close()

	return t
end

_M.rf = function(fname)
	local f = io.open(vim.fn.resolve(fname), 'r')

	if f == nil then
		return nil
	end

	local s = f:read 'a' -- a = all

	local table = vim.json.decode(s)

	return table
end

_M.read_nx = function()
	_G.nx.nx = _M.rf './nx.json'
end

_M.read_workspace = function()
	_G.nx.workspace = _M.rf './workspace.json'
end

_M.read_package_json = function()
	_G.nx.package_json = _M.rf './package.json'
end

_M.read_projects = function()
	for key, value in pairs(_G.nx.workspace.projects or {}) do
		local v = _M.rf(value .. '/project.json')

		_G.nx.projects[key] = v
	end
end

_M.read_workspace_generators = function()
	local gens = {}

	for _, value in ipairs(_M.scandir './tools/generators') do
		local schema = _M.rf('./tools/generators/' .. value .. '/schema.json')
		if schema then
			table.insert(gens, {
				schema = schema,
				name = value,
				run_cmd = 'workspace-generator ' .. value,
				package = 'workspace-generator',
			})
		end
	end

	_G.nx.generators.workspace = gens
end

_M.read_external_generators = function()
	local deps = {}
	for _, value in ipairs(utils.keys(_G.nx.package_json.dependencies)) do
		table.insert(deps, value)
	end
	for _, value in ipairs(utils.keys(_G.nx.package_json.devDependencies)) do
		table.insert(deps, value)
	end

	local gens = {}

	for _, value in ipairs(deps) do
		local f = _M.rf('./node_modules/' .. value .. '/package.json')
		if f ~= nil and f.schematics ~= nil then
			local schematics = _M.rf(
				'./node_modules/' .. value .. '/' .. f.schematics
			)

			if schematics and schematics.generators then
				for name, gen in pairs(schematics.generators) do
					local schema = _M.rf(
						'./node_modules/' .. value .. '/' .. gen.schema
					)
					if schema then
						table.insert(gens, {
							schema = schema,
							name = name,
							run_cmd = 'genetator ' .. value .. ':' .. name,
							package = value,
						})
					end
				end
			end
		end
	end

	_G.nx.generators.external = gens
end

_M.read_nx_root = function()
	_M.read_nx()
	_M.read_workspace()
	_M.read_package_json()

	if _G.nx.workspace ~= nil then
		_M.read_projects()
	end

	_M.read_workspace_generators()
	if _G.nx.package_json ~= nil then
		_M.read_external_generators()
	end
end

return _M
