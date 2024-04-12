# Plugin loader for lazy nvim

My solution to share plugin configuration across multiple [lazy.nvim](https://github.com/folke/lazy.nvim) installation.

## Requirements

- Using lazy.nvim plugin manager

## Usage

You can add the following Lua code to your `init.lua` to bootstrap the plugin loader:

```lua
local plugin_loader_path = vim.fn.stdpath("data") .. "/plugin-loader/plugin-loader"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "https://github.com/RadicalTeapot/plugin-loader.nvim.git",
        plugin_loader_path,
    })
end
vim.opt.rtp:prepend(plugin_loader_path)
```

Next step is to get plugin configurations below the code added in the prior step in `init.lua`:

```lua
local plugins = require("plugin-loader").get_plugin_configs({path, suffix, plugin_list_file, plugins})
```

- **path**: (`string`) Absolute path to the lua module folder where the plugin configurations are located
- **suffix**: (`string`) Name of suffix to use when loading plugin overrides (**optional**)
- **pluin_list_file**: (`string`) Absolute path to a lua file returning a table of plugins to load (**optional**)
- **plugins**: (`table`) List of plugins to load (merged with the list obtained from the plugin list file (**optional**))

Finally pass the result to lazy.nvim

```lua
require("lazy").setup(plugins, {})
```

## Plugin configuration

### Folder structure

Plugin configurations should be structured like a lua module:

```text
plugin_configurations/              <- Path passed to plugin loader
|- lua/
|   |- plugin_name/                 <- Name of the plugin configuration
|   |   |- init.lua                 <- Base configuration for the plugin (shared by all installations)
|   |   |- default.lua              <- Base configuration override (used by all installations without a suffix)
|   |   |- suffix-a.lua             <- suffix-a override configuration for the plugin
|   |   |- ...
|   |- other_plugin/                <- Name of another plugin configuration
|   |   |- init.lua
|   |   |- suffix-a.lua
|   |   |- ...
|   |- subfolder/
|   |   |- deeper_plugin/           <- Any depth is supported (using '.' as path separator in plugin list)
|   |   |   |- init.lua
```

Merging of the configurations is done following this pattern:

- Get plugin configuration from `init.lua` if it exists
- If a suffix was provided and the corresponding `<suffix>.lua` file exists
  - Merge and override its content with the current plugin configuration
  - Otherwise merge and override with the `default.lua` content if it exists

### Plugin configuration override

Content of the lua files are similar to what lazy.nvim expects, for example an `init.lua` file might contain:

```lua
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {},
      highlight = { enable = true },
    }
}
```

The corresponding `default.lua` might contain:

```lua
return {
    opts = {
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query" },
    },
}
```

And a `markdown-install.lua` might contain:

```lua
return {
    opts = {
      ensure_installed = { "mardown", "markdown_inline", "lua" },
    },
}
```

In this example, with no provided suffix, the resulting plugin configuration would be generated:

```lua
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query" },
      highlight = { enable = true },
    }
}
```

And the following if suffix was set to `markdown-install`:

```lua
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "mardown", "markdown_inline", "lua" },
      highlight = { enable = true },
    }
}
```

> [!TIP]
> Any and all entries in the returned table can be overriden by suffix configurations.

## Mentions and inspiration

- The amazing [lazy.nvim](https://github.com/folke/lazy.nvim) plugin manager
- [nvim-projectrc](https://github.com/BartSte/nvim-projectrc) for the general idea and some behavior
