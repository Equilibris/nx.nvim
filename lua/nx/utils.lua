local _M = {}

_M.deepcopy = function(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[_M.deepcopy(orig_key)] = _M.deepcopy(orig_value)
		end
		setmetatable(copy, _M.deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

_M.keys = function(orig)
	local out = {}

	for key, _ in pairs(orig) do
		table.insert(out, key)
	end

	return out
end

return _M
