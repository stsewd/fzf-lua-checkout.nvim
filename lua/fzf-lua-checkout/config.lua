local config = {
  git_bin = "git",
  preview = "{git} -C {cwd} show --color=always {1}",
  cmd = {
    "{git}",
    "-C",
    "{cwd}",
    "{subcommand}",
    "--color=always",
    "--sort={sort}",
    "--format={format}",
  },
  format = "%(color:yellow bold)%(refname:short)  "
    .. "%(color:reset)%(color:green)%(subject) "
    .. "%(color:reset)%(color:blue dim)• "
    .. "%(color:reset)%(color:blue dim italic)%(committerdate:relative)",
  sort = "-committerdate",
  list_previous_ref_first = true,
  -- use_current_buf_cwd = false,
  fzf_exec_opts = {},
  branch = {
    prompt = "Branches> ",
    filter = "all",
    actions = {
      checkout = {
        prompt = "Checkout> ",
        execute = { "{git}", "-C", "{cwd}", "checkout", "{branch}" },
        -- If empty, the name would be used.
        desc = nil,
        required = { "branch" },
        -- If not given, you can still use this action,
        -- but it won't be listed in the main listing.
        keymap = "enter",
        multiple = false,
        confirm = false,
      },
      create = {
        prompt = "Create> ",
        execute = { "{git}", "-C", "{cwd}", "checkout", "-b", "{input}" },
        required = { "input" },
        keymap = "ctrl-g",
        multiple = false,
        confirm = false,
      },
      delete = {
        prompt = "Delete> ",
        execute = { "{git}", "-C", "{cwd}", "branch", "--delete", "--force", "{branch}" },
        required = { "branch" },
        keymap = "ctrl-d",
        multiple = true,
        confirm = true,
      },
    },
  },
}
return config
