# diagflow.nvim

**diagflow.nvim** is a Neovim plugin that displays LSP diagnostics in a floating window at the top right of your screen. This plugin only displays diagnostics for the line under your cursor, providing a clean and distraction-free coding environment.
It is similar to how helix does the diagnostics management.

## Installation

To install **diagflow.nvim**, use your preferred Neovim package manager.
For example, if you're using packer.nvim, you can add this line to your plugin list:

```lua
-- Packer
use {'dgagn/diagflow.nvim'}
-- Lazy
{
    'dgagn/diagflow.nvim',
    opts = {
        max_width = 60,  -- The maximum width of the diagnostic messages
        severity_colors = {  -- The highlight groups to use for each diagnostic severity level
            error = "DiagnosticFloatingError",
            warning = "DiagnosticFloatingWarning",
            info = "DiagnosticFloatingInfo",
            hint = "DiagnosticFloatingHint",
        }
    }
}
```

## Configuration

**Note** if you are using the `opts` with `lazy.nvim`, you don't need to run the setup, it does it for you.

```lua
-- you can just require it, it has sane defaults
require('diagflow').setup()
```

```lua
require('diagflow').setup({
    max_width = 60,  -- The maximum width of the diagnostic messages
    severity_colors = {  -- The highlight groups to use for each diagnostic severity level
        error = "DiagnosticFloatingError",
        warning = "DiagnosticFloatingWarning",
        info = "DiagnosticFloatingInfo",
        hint = "DiagnosticFloatingHint",
    }
})
```

## FAQ

1. How do I change the colors of the virtual text?

You can setup your custom colors by changing the highlight group in the config. For example, in this
default config, the `:hi Hint` is the color of the hints. You can change the hint color to blue by 
`:hi Hint guifg=blue`

