local on_project_mod = function()
	local actions = {}
	local targets = {}
	local targets_flat = {}

	for key, proj in pairs(_G.nx.projects) do
		for name, target in pairs(proj.targets or {}) do
			if targets[target] == nil then
				table.insert(targets_flat, name)
				targets[name] = {}
			end

			table.insert(actions, key .. ':' .. name)

			for config, _ in pairs(target.configurations or {}) do
				table.insert(actions, key .. ':' .. name .. ':' .. config)

				targets[name][config] = true
			end
		end
	end

	_G.nx.cache.actions = actions
	_G.nx.cache.targets = targets
	_G.nx.cache.targets_flat = targets_flat
end

return on_project_mod
