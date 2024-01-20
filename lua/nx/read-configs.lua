local scandir = require 'plenary.scandir'
local Job = require 'plenary.job'
local utils = require 'nx.utils'
local console = (require 'nx.logging')

local _M = {}

function _M.scandir(directory, callback)
	local current_directory = vim.loop.cwd()

	console.log('Scanning ' .. directory)

	local stat = vim.loop.fs_stat(directory)

	if not stat or not stat.type == 'directory' then
		console.log('Scanned ' .. directory)
		callback {}
	end

	scandir.scan_dir(current_directory, {
		on_exit = function(files)
			console.log('Scanned ' .. directory)
			local file_paths = {}

			for _, file in ipairs(files) do
				if not file.is_directory then
					table.insert(file_paths, file.path)
				end
			end

			callback(file_paths)
		end,
	})
end

function _M.rf(fname, callback)
	console.log('Reading ' .. fname)

	vim.loop.fs_open(fname, 'r', 438, function(_, fd)
		if not fd then
			callback({}, false)
			return
		end

		vim.loop.fs_fstat(fd, function(_, stat)
			if not stat then
				vim.loop.fs_close(fd)
				callback({}, false)
				return
			end

			vim.loop.fs_read(fd, stat.size, 0, function(_, data)
				if not data then
					vim.loop.fs_close(fd)
					callback({}, false)
					return
				end

				vim.loop.fs_close(fd, function()
					local table = vim.json.decode(data)
					callback(table, true)
				end)
			end)
		end)
	end)
end

function _M.read_nx(callback)
	_M.rf('./nx.json', function(data, found)
		_G.nx.nx = data
		callback(found)
	end)
end

function _M.read_package_json(callback)
	_M.rf('./package.json', function(data)
		_G.nx.package_json = data
		callback()
	end)
end

function _M.read_projects(callback)
	console.log 'Reading individual projects'
	local projects = _G.nx.graph.graph.nodes or {}
	local keys = utils.keys(projects)
	local count = #keys
	local loadedCount = 0

	for key, value in pairs(projects) do
		_M.rf(value.data.root .. '/project.json', function(v)
			_G.nx.projects[key] = v
			loadedCount = loadedCount + 1
			if loadedCount == count then
				callback()
			end
		end)
	end

	-- If the projects table is empty, call the callback directly
	if count == 0 then
		callback()
	end
end

--- Reads workspace generators
function _M.read_workspace_generators(callback)
	local gens = {}

	console.log 'Reading workspace generators'
	_M.scandir('./tools/generators', function(files)
		local count = #files
		local loadedCount = 0

		local function check_all_completed()
			if loadedCount == count then
				_G.nx.generators.workspace = gens
			end
		end

		for _, file in ipairs(files) do
			_M.rf(
				'./tools/generators/' .. file .. '/schema.json',
				function(schema)
					if schema then
						table.insert(gens, {
							schema = schema,
							name = file,
							run_cmd = 'workspace-generator ' .. file,
							package = 'workspace-generator',
						})
					end

					loadedCount = loadedCount + 1
					check_all_completed()
				end
			)
		end

		-- If the files table is empty, call the callback directly
		if count == 0 then
			_G.nx.generators.workspace = gens
			callback()
		end
	end)

	local function add_gen(gensTable, value, name, schema)
		if schema then
			table.insert(gensTable, {
				schema = schema,
				name = name,
				run_cmd = 'generate ' .. value .. ':' .. name,
				package = value,
			})
		end
	end

	local projects = _G.nx.graph.graph.nodes or {}
	for _, projectSchema in pairs(projects) do
		local path = projectSchema.data.root
		_M.rf(path .. '/package.json', function(f)
			local function handle_schematic_file(field)
				if field then
					_M.rf(path .. '/' .. field, function(schematics)
						if not schematics then
							console.log(
								'No schematics found in '
									.. path
									.. '/'
									.. field
							)
							return
						end

						local possibleGeneratorNames =
							{ 'generators', 'schematics' }
						for _, generators in pairs(possibleGeneratorNames) do
							if schematics and schematics[generators] then
								local genCount = 0
								local loadedGenCount = 0

								for name, gen in pairs(schematics[generators]) do
									genCount = genCount + 1

									_M.rf(
										path .. '/' .. gen.schema,
										function(schema)
											if schema then
												add_gen(
													gens,
													f.name,
													name,
													schema
												)
											else
												console.log(
													'Error reading schema for '
														.. name
														.. ' in '
														.. path
														.. '/'
														.. gen.schema
												)
											end

											loadedGenCount = loadedGenCount + 1
										end
									)
								end

								-- If no generators found for this package, update loadedCount directly
								if genCount == 0 then
									console.log(
										'No generators found in '
											.. path
											.. '/'
											.. field
									)
								end
							end
						end
					end)
				end
			end

			handle_schematic_file 'schematics'
			handle_schematic_file 'generators'
		end)
	end

	_G.nx.generators.workspace = gens
end
function _M.read_project_graph(callback)
	console.log 'Reading project graph'
	console.log '---------------------'

	local temp_file = _G.nx.graph_file_name

	local ls = utils.concat(
		utils.split_on_space(_G.nx.nx_cmd_root),
		{ 'graph', '--file=' .. temp_file }
	)

	local args = {}

	for i = 2, #ls do
		table.insert(args, ls[i])
	end

	local s = 'Running'
	for i = 1, #ls do
		s = s .. ' ' .. ls[i]
	end
	console.log(s)

	local job = Job:new {
		command = ls[1],
		args = args,
		capture_output = true,
		on_exit = function(j, return_val)
			assert(return_val, 0)

			_G.nx.graph = _M.rf(temp_file, function(data)
				_G.nx.graph = data

				console.log(_G.nx.graph)
				console.log '---------------------'

				callback()
			end)
		end,
	}

	job:start()
end

---Reads node_modules generators (only those specified in package.json, not lock)
function _M.read_external_generators(callback)
	local deps = {}
	for _, value in ipairs(utils.keys(_G.nx.package_json.dependencies)) do
		table.insert(deps, value)
	end
	for _, value in ipairs(utils.keys(_G.nx.package_json.devDependencies)) do
		table.insert(deps, value)
	end

	local gens = {}
	local count = #deps
	local loadedCount = 0

	local function maybe_continue()
		loadedCount = loadedCount + 1
		if loadedCount == count * 2 then
			_G.nx.generators.external = gens
			callback()
		end
	end

	local function add_gen(value, name, schema)
		if schema then
			table.insert(gens, {
				schema = schema,
				name = name,
				run_cmd = 'generate ' .. value .. ':' .. name,
				package = value,
			})
		end
	end

	for _, value in ipairs(deps) do
		_M.rf('./node_modules/' .. value .. '/package.json', function(f)
			local function handle_schematic_file(field)
				if f[field] then
					local schematics_path = './node_modules/'
						.. value
						.. '/'
						.. f[field]
					local schematics_dir =
						vim.fn.fnamemodify(schematics_path, ':p:h')
					_M.rf(schematics_path, function(schematics)
						local possibleGeneratorNames =
							{ 'generators', 'schematics' }
						for _, generators in pairs(possibleGeneratorNames) do
							if schematics and schematics[generators] then
								local genCount = 0
								local loadedGenCount = 0

								for name, gen in pairs(schematics[generators]) do
									genCount = genCount + 1

									_M.rf(
										schematics_dir .. '/' .. gen.schema,
										function(schema)
											add_gen(value, name, schema)

											loadedGenCount = loadedGenCount + 1
											if loadedGenCount == genCount then
												maybe_continue()
											end
										end
									)
								end

								-- If no generators found for this package, update loadedCount directly
								if genCount == 0 then
									maybe_continue()
								end
							else
								maybe_continue()
							end
						end
					end)
				else
					maybe_continue()
				end
			end

			handle_schematic_file 'schematics'
			handle_schematic_file 'generators'
		end)
	end

	-- If the dependencies table is empty, call the callback directly
	if count == 0 then
		_G.nx.generators.external = gens
		callback()
	end
end

function _M.read_nx_root(callback)
	console.log 'Starting reading'
	console.log '----------------'

	local function handle_nx_completed()
		if _G.nx.nx == nil then
			console.error 'Nx config was not found'
			console.log '----------------'
			return
		end

		_M.read_project_graph(function()
			console.log 'Read project graph completed.'
			_M.read_package_json(function()
				console.log 'Read package.json completed.'
				_M.read_projects(function()
					console.log 'Read projects completed.'
					-- _M.read_workspace_generators(function()
					-- 	console.log 'Read workspace generators completed.'
					_M.read_external_generators(function()
						console.log 'Read external generators completed.'
						console.log '----------------'
						callback()
					end)
					-- end)
				end)
			end)
		end)
	end

	_M.read_nx(function(found)
		console.log 'Read nx.json completed.'
		if found then
			handle_nx_completed()
		end
	end)
end

return _M
