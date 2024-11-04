local fzf = require("fzf-lua")
local actions = require("fzf-lua-checkout.actions")
local utils = require("fzf-lua-checkout.utils")

local M = {}

local function get_actions(subcommand, cwd, opts)
  local local_opts = opts[subcommand]
  local result = {}
  for action_name, action_opts in pairs(local_opts.actions) do
    -- TODO: support action as a function?
    local fn = actions.make_action(subcommand, cwd, action_name, opts)
    result[action_opts.keymap] = fn
  end
  return result
end

local function get_list_cmd(subcommand, opts, format_opts)
  -- TODO: maybe also accept a function as cmd?
  local local_opts = opts[subcommand]
  local cmd = utils.format_list(opts.cmd, format_opts)

  if subcommand == "branch" and local_opts.filter then
    local filter = local_opts.filter
    if filter == "all" then
      filter = "--all"
    elseif filter == "remotes" then
      filter = "--remotes"
    elseif filter == "locals" then
      filter = nil
    end
    if filter then
      table.insert(cmd, filter)
    end
  end
  return cmd
end

---Remove a reference from a list of branch entries.
---@param ref string The reference to remove.
---@param list table The list of branch entries.
local function remove_ref_from_list(ref, list)
  -- Matches ANSI escape codes like:
  -- \27[1;33mmain
  -- \27[m\27[32mmain
  local pattern = "\27%[[0-9;]*m%s*([^%s]+)"
  for i, v in ipairs(list) do
    local _, _, match = v:find(pattern)
    if match == ref then
      return table.remove(list, i)
    end
  end
  return nil
end

local function remove_matching_pattern_from_list(pattern, list)
  for i, v in ipairs(list) do
    if v:find(pattern) then
      return table.remove(list, i)
    end
  end
  return nil
end

local function get_current_ref(format_opts)
  local cmd = utils.format_list({
    "{git}",
    "-C",
    "{cwd}",
    "symbolic-ref",
    "--short",
    "-q",
    "HEAD",
  }, format_opts)
  local result = vim.system(cmd, { text = true }):wait()
  local ref = vim.trim(result.stdout)
  if ref ~= "" then
    return ref
  end

  cmd = utils.format_list({
    "{git}",
    "-C",
    "{cwd}",
    "rev-parse",
    "--short",
    "HEAD",
  }, format_opts)
  result = vim.system(cmd, { text = true }):wait()
  return vim.trim(result.stdout)
end

local function get_previous_ref(format_opts)
  local cmd = utils.format_list({
    "{git}",
    "-C",
    "{cwd}",
    "rev-parse",
    "-q",
    "--abbrev-ref",
    "--symbolic-full-name",
    "@{-1}",
  }, format_opts)
  local result = vim.system(cmd, { text = true }):wait()
  local ref = vim.trim(result.stdout)
  if result.code == 0 and ref ~= "" then
    return ref
  end

  cmd = utils.format_list({
    "{git}",
    "-C",
    "{cwd}",
    "rev-parse",
    "--short",
    "-q",
    "@{-1}",
  }, format_opts)
  result = vim.system(cmd, { text = true }):wait()
  return vim.trim(result.stdout)
end

---@param subcommand string "branch" or "tag"
---@param opts table? Options that will be merged with the current config.
---@param action string? If given, only this action will be shown.
local function list(subcommand, opts, action)
  local global_config = require("fzf-lua-checkout.config")
  opts = vim.tbl_deep_extend("force", global_config, opts or {})
  local local_opts = opts[subcommand] or {}
  local prompt = local_opts.prompt

  -- If action is given, we only show that action.
  if action then
    for k, v in pairs(local_opts.actions) do
      if k == action then
        prompt = v.prompt or prompt
        local_opts.actions[k].keymap = "enter"
      else
        local_opts.actions[k] = nil
      end
    end
  end

  local git = opts.git_bin
  local cwd = vim.fn.getcwd()
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
  if result.code ~= 0 then
    local msg = string.format("Error running list command.\n%s\n%s", result.stdout, result.stderr)
    vim.notify(msg, vim.log.levels.ERROR, { title = "fzf-lua-checkout" })
    return
  end
  local results = vim.split(vim.trim(result.stdout), "\n", { trimempty = true })

  -- Remove thing that aren't valid branches or tags.
  -- (HEAD detached at origin/main)
  remove_matching_pattern_from_list("%(HEAD detached at [/%w]+%)", results)

  local header = nil
  if opts.show_current_ref_in_header then
    local current_ref = get_current_ref(format_opts)
    remove_ref_from_list(current_ref, results)
    header = current_ref
  end

  if opts.list_previous_ref_first then
    local previous_ref = get_previous_ref(format_opts)
    if previous_ref ~= "" then
      local previous_ref_entry = remove_ref_from_list(previous_ref, results)
      -- We should always have a previous ref, but just in case.
      if previous_ref_entry then
        table.insert(results, 1, previous_ref_entry)
      end
    end
  end

  local fzf_exec_opts = {
    prompt = prompt,
    preview = preview,
    header = header,
    fzf_opts = {
      ["--multi"] = true,
      ["--nth"] = 1,
    },
    actions = get_actions(subcommand, cwd, opts),
  }
  fzf_exec_opts = vim.tbl_deep_extend("force", fzf_exec_opts, opts.fzf_exec_opts or {})
  fzf.fzf_exec(results, fzf_exec_opts)
end

---List git branches.
---@param opts table? Options that will be merged with the current config.
---@param action string? If given, only this action will be shown.
function M.branches(opts, action)
  list("branch", opts, action)
end

---List git tags.
---@param opts table? Options that will be merged with the current config.
---@param action string? If given, only this action will be shown.
function M.tags(opts, action)
  list("tag", opts, action)
end

return M
