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
  -- TODO: support some of these options to be a function?
  format = "%(color:yellow bold)%(refname:short)  "
    .. "%(color:reset)%(color:green)%(subject) "
    .. "%(color:reset)%(color:blue dim)• "
    .. "%(color:reset)%(color:blue dim italic)%(committerdate:relative)",
  sort = "-committerdate",
  list_previous_ref_first = true,
  show_current_ref_in_header = true,
  -- TODO: implement this
  use_current_buf_cwd = false,
  fzf_exec_opts = {},
  branch = {
    prompt = "Branches> ",
    -- TODO: implement a "smart" filter that filters remote branches that are not already tracked locally?
    -- Or one that shows only the name of the branch, without the remote,
    -- and then it automatically tracks the remote branch on checkout?
    filter = "all", -- all, locals, remotes, smart?
    actions = {
      checkout = {
        prompt = "Checkout> ",
        cmd = { "{git}", "-C", "{cwd}", "checkout", "{branch}" },
        -- If empty, the name would be used.
        desc = nil,
        required = { "branch" },
        -- If not given, you can still use this action,
        -- but it won't be listed in the main listing.
        keymap = "enter",
        multiple = false,
        confirm = false,
      },
      track = {
        prompt = "Track> ",
        cmd = { "{git}", "-C", "{cwd}", "checkout", "--track", "{branch}" },
        required = { "branch" },
        keymap = "alt-enter",
        multiple = false,
        confirm = false,
      },
      create = {
        prompt = "Create> ",
        cmd = { "{git}", "-C", "{cwd}", "checkout", "-b", "{input}" },
        required = { "input" },
        keymap = "ctrl-g",
        multiple = false,
        confirm = false,
      },
      delete = {
        prompt = "Delete> ",
        cmd = { "{git}", "-C", "{cwd}", "branch", "--delete", "--force", "{branch}" },
        required = { "branch" },
        keymap = "ctrl-d",
        multiple = true,
        confirm = true,
      },
      -- TODO: maybe just don't include these by default?
      -- merge = {
      --   prompt = "Merge> ",
      --   cmd = { "{git}", "-C", "{cwd}", "merge", "{branch}" },
      --   required = { "branch" },
      --   -- keymap = "ctrl-e",
      --   multiple = false,
      --   confirm = true,
      -- },
      -- rebase = {
      --   prompt = "Rebase> ",
      --   cmd = { "{git}", "-C", "{cwd}", "rebase", "{branch}" },
      --   required = { "branch" },
      --   -- keymap = "ctrl-r",
      --   multiple = false,
      --   confirm = true,
      -- },
    },
  },
  tag = {
    prompt = "Tags> ",
    actions = {
      checkout = {
        prompt = "Checkout> ",
        cmd = { "{git}", "-C", "{cwd}", "checkout", "{tag}" },
        required = { "tag" },
        keymap = "enter",
        multiple = false,
        confirm = false,
      },
      create = {
        prompt = "Create> ",
        cmd = { "{git}", "-C", "{cwd}", "tag", "{input}" },
        required = { "input" },
        keymap = "ctrl-g",
        multiple = false,
        confirm = false,
      },
      delete = {
        prompt = "Delete> ",
        cmd = { "{git}", "-C", "{cwd}", "tag", "--delete", "{tag}" },
        required = { "tag" },
        keymap = "ctrl-d",
        multiple = true,
        confirm = true,
      },
    },
  },
}
return config
