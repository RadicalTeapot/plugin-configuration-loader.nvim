local M = {}

--- Default options
M.default = {
    path = vim.fs.normalize("~/.plugin-configuration-loader"),
    suffix = {
        override = vim.fn.expand("$NVIM_APPNAME"),
        fallback = "default",
    },
    plugin_list_module = vim.fn.expand("plugin_list.$NVIM_APPNAME"),
    plugins = {},
    debug = false,
}

--- Get module path with appended suffixes
--- @param path string Base module path
--- @param ... string Suffix(es)
--- @return string Suffixed module path
local get_suffixed_module_path = function(path, ...)
    local suffixes = { ... }
    local suffixed_path = path .. "." .. table.concat(suffixes, ".")
    -- Clean up path (remove trailing dots and .lua)
    suffixed_path = suffixed_path:gsub("%.+$", ""):gsub("%.lua$", "")
    return suffixed_path
end

--- Load plugin config from module path
--- @param module_path string Module path
--- @return table|nil Plugin config or nil if not found
local load_plugin_config = function(module_path, debug)
    local ok, result = pcall(require, module_path)
    if ok then
        return result
    end
    if debug then
        vim.notify("Could not load plugin " .. module_path, vim.log.levels.WARN)
    end
    return nil
end

--- Get merged base and suffix plugin config from module path
--- @param opts table Options
--- @return table Merged plugin config or an empty table if not found
local get_merged_plugin_config = function(opts)
    -- Try require plugin init module
    local require_init = load_plugin_config(opts.module) or {} -- Plugins without init.lua file are supported

    -- Try require plugin suffixed module
    local module_path = get_suffixed_module_path(opts.module, opts.suffix.override)
    local require_suffix = load_plugin_config(module_path, opts.debug)

    -- Fallback if loading suffixed module failed
    if require_suffix == nil then
        module_path = get_suffixed_module_path(opts.module, opts.suffix.fallback)
        require_suffix = load_plugin_config(module_path, opts.debug) or {}
    end

    -- Merge tables recursively
    local plugin_config = vim.tbl_deep_extend("force", require_init, require_suffix)
    return plugin_config
end

--- Get plugin list from plugin_list_file and plugins
--- @param plugins table|nil List of plugins
--- @param plugin_list_file string|nil Path to plugin_list_file
--- @return table List of plugins or an empty table if not found
local get_plugin_list = function(plugin_list_file, plugins)
    local plugin_list = {}

    if plugin_list_file ~= nil then
        local ok, result = pcall(require, plugin_list_file)
        if ok then
            assert(type(result) == "table", "opts.plugin_list_module return type must be a table")
            plugin_list = vim.tbl_extend("force", plugin_list, result)
        end
    end

    assert(type(plugins) == "table", "opts.plugins must be a table")
    plugin_list = vim.tbl_extend("force", plugin_list, plugins)

    return plugin_list
end

--- Get plugin configs
--- @param opts table|nil Options
--- @return table List of plugin configs
M.get_plugin_configurations = function(opts)
    -- Merge tables recursively
    local merged_opts = vim.tbl_deep_extend("force", M.default, opts or {})

    -- Store and extend runtime path
    local rtp = vim.o.rtp
    assert(type(merged_opts.path) == "string", "path must be a string")
    vim.opt.rtp:prepend(merged_opts.path)

    local plugins = get_plugin_list(merged_opts.plugin_list_module, merged_opts.plugins)
    local configs = {}
    for _, p in ipairs(plugins) do
        local plugin_config_opts = {
            module = p,
            suffix = merged_opts.suffix,
            debug = merged_opts.debug,
        }
        -- Append to config list
        configs[#configs + 1] = get_merged_plugin_config(plugin_config_opts)
    end

    -- Restore runtime path
    vim.opt.rtp = rtp

    return configs
end

return M
