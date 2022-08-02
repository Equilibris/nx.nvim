return require('telescope').register_extension {
	setup = function(ext_config, config) end,
	exports = {
		actions = require('nx.actions').actions_finder,
	},
}
