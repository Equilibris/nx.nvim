local scandir = require 'plenary.scandir'
local a = require 'plenary.async'

local utils = require 'nx.utils'
local console = (require 'nx.logging')

local _M = {}

function _M.scandir(directory)
	local current_directory = vim.loop.cwd()
	local files = scandir.scan_dir(current_directory)
	local file_paths = {}

	for _, file in ipairs(files) do
		if not file.is_directory then
			table.insert(file_paths, file.path)
		end
	end

	return file_paths
end

function _M.rf(fname)
	console.log('Reading ' .. fname)

	local err, fd = a.uv.fs_open(fname, 'r', 438)
	if err then
		return {}
	end

	local err, stat = a.uv.fs_fstat(fd)
	if err then
		return {}
	end

	local err, data = a.uv.fs_read(fd, stat.size, 0)
	if err then
		return {}
	end

	local err = a.uv.fs_close(fd)
	if err then
		return {}
	end

	local table = vim.json.decode(data)

	console.log(table)

	return table
end

---Reads nx.json and sets its global var
function _M.read_nx()
	_G.nx.nx = _M.rf './nx.json'
end

---Reads workspace.json and sets its global var
function _M.read_workspace()
	_G.nx.workspace = _M.rf './workspace.json'
end

---Reads package.json and sets its global var
function _M.read_package_json()
	_G.nx.package_json = _M.rf './package.json'
end

---Reads all projects configurations
function _M.read_projects()
	console.log 'Reading individual projects'
	for key, value in pairs(_G.nx.workspace.projects or {}) do
		local v = _M.rf(value .. '/project.json')

		_G.nx.projects[key] = v
	end
end

---Reads workspace generators
function _M.read_workspace_generators()
	local gens = {}

	console.log 'Reading workspace generators'
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

---Reads node_modules generators (only those specified in package.json, not lock)
function _M.read_external_generators()
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
			local schematics =
				_M.rf('./node_modules/' .. value .. '/' .. f.schematics)

			if schematics and schematics.generators then
				for name, gen in pairs(schematics.generators) do
					local schema =
						_M.rf('./node_modules/' .. value .. '/' .. gen.schema)
					if schema then
						table.insert(gens, {
							schema = schema,
							name = name,
							run_cmd = 'generate ' .. value .. ':' .. name,
							package = value,
						})
					end
				end
			end
		end
	end

	_G.nx.generators.external = gens
end

---Reads all configs
function _M.read_nx_root()
	console.log 'Starting reading'
	console.log '----------------'

	_M.read_nx()

	if _G.nx.nx == nil or _G.nx.nx['$schema'] == nil then
		console.error 'Nx config was not found'
		console.log '----------------'
		return
	end

	_M.read_workspace()
	_M.read_package_json()

	if _G.nx.workspace ~= nil then
		_M.read_projects()
	end

	_M.read_workspace_generators()
	if _G.nx.package_json ~= nil then
		_M.read_external_generators()
	end
	console.log '----------------'
end

return _M
