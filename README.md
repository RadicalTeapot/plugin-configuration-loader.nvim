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
- **plugins**: (`table`) List of plugins to load (merged with the list obtained for the file (**optional**))

Finally pass the result to lazy.nvim

```lua
require("lazy").setup(plugins, {})
```
