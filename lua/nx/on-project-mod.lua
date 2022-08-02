local on_project_mod = function()
	local actions = {}
	for key, proj in pairs(_G.nx.projects) do
		for name, target in pairs(proj.targets or {}) do
			table.insert(actions, proj .. ':' .. name)

			for config, _ in pairs(target.configurations or {}) do
				table.insert(actions, proj .. ':' .. name .. ':' .. config)
			end
		end
	end

	_G.nx.cache.actions = actions
end

return on_project_mod
