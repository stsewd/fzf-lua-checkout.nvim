local fzf = require("fzf-lua")

local utils = require("fzf-lua-checkout.utils")

local M = {}

local function get_cwd_from_current_buffer()
  local cwd = vim.fn.expand("%:p:h")
  return cwd
end

--- @param cmd_placeholder string[]
--- @param action_opts {name: string, desc: string, required: string[]}
function M.custom(cmd_placeholder, action_opts)
  local desc = action_opts.desc or action_opts.name or "custom action"
  local fn = function(selected, opts)
    -- We are modifying the cmd_placeholder in place,
    -- so we need to make a copy
    local cmd = vim.deepcopy(cmd_placeholder)
    local cwd = vim.fn.getcwd()
    -- TODO: use the same cwd as the one used in the listing.
    -- if action_opts.use_current_buf_cwd then
    --   cwd = get_cwd_from_current_buffer()
    -- end
    local branch = ""
    local branches = {}
    if not action_opts.multiple and #selected > 0 then
      branch = vim.split(selected[1], " ")[1]
    else
      for _, v in ipairs(selected) do
        -- branch = branch .. " " .. vim.split(v, " ")[1]
        table.insert(branches, vim.split(v, " ")[1])
      end
    end
    if #branches > 0 then
      branch = table.concat(branches, " ")
    end

    local subs = {
      git = action_opts.git_bin or "git",
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
      if cmd[i] == "{branch}" and #branches > 0 then
        expand_branches_at = i
      else
        cmd[i] = utils.format(cmd[i], subs)
      end
    end

    if expand_branches_at > 0 then
      local a = vim.list_slice(cmd, 1, expand_branches_at - 1)
      local b = vim.list_slice(cmd, expand_branches_at + 1)
      vim.list_extend(a, branches)
      vim.list_extend(a, b)
      cmd = a
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
