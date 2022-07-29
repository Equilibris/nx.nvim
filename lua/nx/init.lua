_G.nx = {}

local setup = function(config)
	if config.register_tert or true then
		print 'hello world'
	end
end

return { setup = setup }
