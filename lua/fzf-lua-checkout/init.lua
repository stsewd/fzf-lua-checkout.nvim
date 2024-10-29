local config = require("fzf-lua-checkout.config")
local M = {}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

M.branches = require("fzf-lua-checkout.list").branches
M.tags = require("fzf-lua-checkout.list").tags

return M
