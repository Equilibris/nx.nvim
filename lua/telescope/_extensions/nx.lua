return require('telescope').register_extension {
	exports = {
		actions = require('nx.actions').actions_finder,
	},
}
