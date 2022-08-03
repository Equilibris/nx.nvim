# nx.nvim &mdash; the NX extention for nvim (no shit)

## Instalation

You know how to do this but on the off chance you dont here you go:

```lua
use {
    "Equilibris/nx.nvim",
    config = function()
        require("nx").setup {}
    end
}
```

## Features

| Feature name | Essential | Implemented |
| ------------ | --------- | ----------- |
| Task runner  | yes       | yes         |
| Generators   | yes       | no          |
| Run many     | yes       | no          |
| Affected     | yes       | no          |
| Reveal proj  | no        | no          |
| Migrate      | no        | no          |
| Graph        | no        | no          |
| List         | no        | no          |

