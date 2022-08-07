local generators = require 'nx.generators'
local multirunners = require 'nx.multirunners'

return require('telescope').register_extension {
	exports = {
		actions = require('nx.actions').actions_finder,
		run_many = multirunners.run_many,
		affected = multirunners.affected,
		generators = generators.generators,
		workspace_generators = generators.workspace_generators,
		external_generators = generators.external_generators,
	},
}
