local fzf = require("fzf-lua")

local utils = require("fzf-lua-checkout.utils")

local M = {}

--- @param subcommand string branch or tag
--- @param cwd string
--- @param action string
--- @param config table
function M.make_action(subcommand, cwd, action, config)
  local action_opts = config[subcommand].actions[action]
  local desc = action_opts.desc or action
  local fn = function(selected, opts)
    -- We are modifying the command in place,
    -- so we need to make a copy
    local cmd = vim.deepcopy(action_opts.cmd)
    local branch = ""
    local branches = {}
    if not action_opts.multiple and #selected > 0 then
      branch = vim.split(selected[1], " ")[1]
    else
      for _, v in ipairs(selected) do
        table.insert(branches, vim.split(v, " ")[1])
      end
    end
    if #branches > 0 then
      branch = table.concat(branches, " ")
    end

    local subs = {
      git = config.git_bin or "git",
      cwd = cwd,
      branch = branch,
      tag = branch,
      input = opts.last_query,
    }

    -- Check required fields.
    for _, field in ipairs(action_opts.required or {}) do
      if not subs[field] or subs[field] == "" then
        local msg = string.format("A %s is required", field)
        vim.notify(msg, vim.log.levels.ERROR)
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

    local expand_branches_at = 0
    -- Replace placeholders with values.
    for i = 1, #cmd do
      if (cmd[i] == "{branch}" or cmd[i] == "{tag}") and #branches > 0 then
        expand_branches_at = i
      else
        cmd[i] = utils.format(cmd[i], subs)
      end
    end

    if expand_branches_at > 0 then
      table.remove(cmd, expand_branches_at)
      utils.extend_list_at(cmd, branches, expand_branches_at)
    end

    -- Execute the command asynchronously.
    local onexit = function(result)
      local loglevel = result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
      vim.notify(result.stdout .. "\n" .. result.stderr, loglevel)
    end
    vim.system(cmd, { text = true }, onexit)
  end
  fzf.config.set_action_helpstr(fn, desc)
  return fn
end

return M
