# nx.nvim &mdash; the NX extention for nvim

## Installation

### Packer

```lua
use {
    'Equilibris/nx.nvim',
    requires = {
        'nvim-telescope/telescope.nvim',
    },
    config = function()
        require("nx").setup {}
    end
}
```

### Lazy

```lua
return {
  {
    "Equilibris/nx.nvim",

    dependencies = {
      "nvim-telescope/telescope.nvim",
    },

    opts  = {
      -- See below for config options
      nx_cmd_root = "npx nx",
    },

    -- Plugin will load when you use these keys
    keys = {
      { "<leader>nx", "<cmd>Telescope nx actions<CR>", desc = "nx actions"}
    },
  },
}
```

## Default config

```lua
require('nx.nvim').setup{
    -- Base command to run all other nx commands, some other values may be:
    -- - `npm nx`
    -- - `yarn nx`
    -- - `pnpm nx`
    nx_cmd_root = 'nx',

    -- Command running capabilities,
    -- see nx.m.command-runners for more details
    command_runner = require('nx.command-runners').terminal_cmd(),
    -- Form rendering capabilities,
    -- see nx.m.form-renderers for more detials
    form_renderer = require('nx.form-renderers').telescope(),

    -- Whether or not to load nx configuration,
    -- see nx.loading-and-reloading for more details
    read_init = true,
}
```

## Docs and refrence

Docs and a command refrence can be found with the command `:help nx.nvim` or in the file `doc/nx.txt`

## Features

| Feature name | Essential | Implemented |
| ------------ | --------- | ----------- |
| Task runner  | yes       | yes         |
| Generators   | yes       | yes         |
| Run many     | yes       | yes         |
| Affected     | yes       | yes         |
| Reveal proj  | no        | no          |
| Migrate      | no        | no          |
| Graph        | no        | no          |
| List         | no        | no          |
