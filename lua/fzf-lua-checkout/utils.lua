local M = {}

function M.format(str, opts)
  -- We build a replacement table,
  -- since the replacements can contain %
  -- which lua ignores when replacing.
  local replacement_table = {}
  for k, v in pairs(opts) do
    replacement_table["{" .. k .. "}"] = v
  end

  for k, _ in pairs(opts) do
    str = str:gsub("{" .. k .. "}", replacement_table)
  end
  return str
end

return M
