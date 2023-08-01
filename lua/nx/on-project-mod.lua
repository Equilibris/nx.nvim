local console = require 'nx.logging'
--
---Reloads actions and targets config
local function on_project_mod()
	console.log 'On Project Mod'
	console.log '--------------'

	local actions = {}
	local targets = {}

	for key, node in pairs(_G.nx.graph.graph.nodes or {}) do
		local proj = node.data
		console.log('Handeling node ' .. key .. ' with:')
		console.log(proj)

		for name, target in pairs(proj.targets or {}) do
			if targets[name] == nil then
				targets[name] = {}
			end

			local target_name = key .. ':' .. name

			console.log('Inserting ' .. target_name)

			table.insert(actions, target_name)

			for config, _ in pairs(target.configurations or {}) do
				local config_name = target_name .. ':' .. config

				console.log('Inserting ' .. config_name)

				table.insert(actions, config_name)

				targets[name][config] = true
			end
		end
	end

	_G.nx.cache.actions = actions
	_G.nx.cache.targets = targets

	console.log(_G.nx.cache)

	console.log '--------------'
end

return on_project_mod
