local M = {}

--- Default options
M.default = {
    path = "~",
    suffix = "default",
    plugins = nil,
    plugin_list_file = nil,
}

--- Get module path with appended suffixes
--- @param path string Base module path
--- @param ... string|table Suffix(es)
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
local load_plugin_config = function(module_path)
    local ok, result = pcall(require, module_path)
    if ok then
        return result
    end
    vim.notify("Could not load plugin " .. module_path, vim.log.levels.WARN)
    return nil
end

--- Get merged base and suffix plugin config from module path
--- @param module_path string Module path
--- @param suffix string|nil Suffix to load to override base plugin config
--- @param fallback_suffix string|nil Fallback suffix to use if suffix is not found
--- @return table Merged plugin config or an empty table if not found
local get_merged_plugin_config = function(module_path, suffix, fallback_suffix)
    -- Try require plugin init module
    local require_init = load_plugin_config(module_path) or {} -- Plugins without init.lua file are supported

    -- Try require plugin suffixed module
    local require_suffix = load_plugin_config(get_suffixed_module_path(module_path, suffix))

    -- Fallback
    if require_suffix == nil then
        print("Fallback to loading plugin " .. module_path .. " " .. fallback_suffix)
        require_suffix = load_plugin_config(get_suffixed_module_path(module_path, fallback_suffix)) or {}
    end

    -- Merge tables recursively
    local plugin_config = vim.tbl_deep_extend("force", require_init, require_suffix)
    return plugin_config
end

--- Get plugin list from plugin_list_file and plugins
--- @param plugins table|nil List of plugins
--- @param plugin_list_file string|nil Path to plugin_list_file
--- @return table List of plugins or an empty table if not found
local get_plugin_list = function(plugins, plugin_list_file)
    local plugin_list = {}

    if plugin_list_file ~= nil then
        local ok, result = pcall(dofile, plugin_list_file)
        if ok then
            assert(type(result) == "table", "plugin_list_file must be a table")
            plugin_list = vim.tbl_extend("force", plugin_list, result)
        end
    end

    if plugins ~= nil then
        plugin_list = vim.tbl_extend("force", plugin_list, plugins)
    end

    return plugin_list
end

--- Get plugin configs
--- @param opts table|nil Options
--- @return table List of plugin configs
M.get_plugin_configs = function(opts)
    -- Merge tables recursively
    local merged_opts = vim.tbl_deep_extend("force", M.default, opts or {})

    -- Store and extend runtime path
    local rtp = vim.o.rtp
    vim.opt.rtp:prepend(merged_opts.path)

    local plugins = get_plugin_list(merged_opts.plugins, merged_opts.plugin_list_file)
    local configs = {}
    for _, p in ipairs(plugins) do
        -- Append to config list
        configs[#configs + 1] = get_merged_plugin_config(p, merged_opts.suffix, M.default.suffix)
    end

    -- Restore runtime path
    vim.opt.rtp = rtp

    return configs
end

return M
