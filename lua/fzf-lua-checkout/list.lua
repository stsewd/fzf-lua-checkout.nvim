local fzf = require("fzf-lua")
local actions = require("fzf-lua-checkout.actions")
local config = require("fzf-lua-checkout.config")
local utils = require("fzf-lua-checkout.utils")

local M = {}

local function get_actions(subcommand, opts)
  local local_opts = opts[subcommand]
  local result = {}
  for action_name, action_opts in pairs(local_opts.actions) do
    -- TODO: support action as a function.
    local fn = actions.custom(action_opts.execute, vim.tbl_deep_extend("force", { name = action_name }, action_opts))
    result[action_opts.keymap] = fn
  end
  return result
end

local function get_list_cmd(subcommand, opts, format_opts)
  -- TODO: maybe also accept a function as cmd?
  local local_opts = opts[subcommand]
  local cmd = vim.deepcopy(opts.cmd)
  for i, v in ipairs(cmd) do
    cmd[i] = utils.format(v, format_opts)
  end

  if subcommand == "branch" and local_opts.filter then
    local filter = local_opts.filter
    if filter == "all" then
      filter = "--all"
    end
    table.insert(cmd, filter)
  end
  return cmd
end

local function list(subcommand, opts)
  opts = vim.tbl_deep_extend("force", vim.deepcopy(config), opts or {})
  local git = opts.git_bin
  local cwd = vim.fn.getcwd()
  local local_opts = opts[subcommand]
  -- if opts.use_current_buf_cwd then
  --   cwd = vim.fn.expand("%:p:h")
  -- end

  local format_opts = {
    git = git,
    cwd = cwd,
    subcommand = subcommand,
    format = opts.format,
    sort = opts.sort,
  }
  local preview = opts.preview
  if type(preview) == "string" then
    preview = utils.format(preview, format_opts)
  end

  local cmd = get_list_cmd(subcommand, opts, format_opts)
  local result = vim.system(cmd, { text = true }):wait()
  local results = vim.split(vim.trim(result.stdout), "\n")

  local fzf_exec_opts = {
    prompt = local_opts.prompt,
    preview = preview,
    fzf_opts = {
      ["--multi"] = true,
      ["--nth"] = 1,
    },
    actions = get_actions(subcommand, opts),
  }
  fzf_exec_opts = vim.tbl_deep_extend("force", fzf_exec_opts, opts.fzf_exec_opts or {})
  fzf.fzf_exec(results, fzf_exec_opts)
end

function M.branches(opts)
  list("branch", opts)
end

function M.tags(opts)
  list("tag", opts)
end

return M
