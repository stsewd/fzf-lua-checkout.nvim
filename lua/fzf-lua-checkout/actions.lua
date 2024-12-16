local fzf = require("fzf-lua")

local utils = require("fzf-lua-checkout.utils")

local M = {}

local function get_action_cmd(cmd, branches, format_opts)
  local result = {}
  -- Replace placeholders with values.
  for _, v in ipairs(cmd) do
    -- If we have a {branch} or {tag} placeholder,
    -- we need to expand the branches as separate arguments.
    -- otherwise, it there are several branches selected,
    -- it will be treated as a single branch.
    if v == "{branch}" or v == "{tag}" then
      for _, branch in ipairs(branches) do
        table.insert(result, branch)
      end
    else
      table.insert(result, utils.format(v, format_opts))
    end
  end
  return result
end

--- @param subcommand string branch or tag
--- @param cwd string
--- @param action string
--- @param config table
function M.make_action(subcommand, cwd, action, config)
  local action_opts = config[subcommand].actions[action]
  local desc = action_opts.desc or action
  local fn = function(selected, opts)
    local branches = {}
    for _, v in ipairs(selected) do
      table.insert(branches, vim.split(v, " ")[1])
    end

    local branch = ""
    if action_opts.multiple then
      branch = table.concat(branches, " ")
    else
      branch = branches[1]
    end

    local format_opts = {
      git = config.git_bin,
      cwd = cwd,
      branch = branch,
      tag = branch,
      input = opts.last_query,
    }

    -- Check required fields.
    for _, field in ipairs(action_opts.required or {}) do
      if not format_opts[field] or format_opts[field] == "" then
        local msg = string.format("A %s is required", field)
        vim.notify(msg, vim.log.levels.ERROR, { title = "fzf-lua-checkout" })
        return
      end
    end

    -- Ask for confirmation.
    if action_opts.confirm then
      local msg = string.format("Do you want to %s %s?", desc, branch)
      local confirm = vim.fn.confirm(msg, "&Yes\n&No", 2)
      if confirm ~= 1 then
        return
      end
    end

    -- Execute the command asynchronously.
    local cmd = get_action_cmd(action_opts.cmd, branches, format_opts)
    local onexit = function(result)
      local loglevel = result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
      vim.notify(result.stdout .. "\n" .. result.stderr, loglevel, { title = "fzf-lua-checkout" })
    end
    vim.system(cmd, { text = true }, vim.schedule_wrap(onexit))
  end
  fzf.config.set_action_helpstr(fn, desc)
  return fn
end

return M
