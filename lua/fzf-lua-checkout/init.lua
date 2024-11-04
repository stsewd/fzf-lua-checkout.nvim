local config = require("fzf-lua-checkout.config")
local M = {}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

return M
