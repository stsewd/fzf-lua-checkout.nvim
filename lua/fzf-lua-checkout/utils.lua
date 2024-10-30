local M = {}

---Format a string with the given options.
---The options should be a table with key-value pairs.
---The keys can appear in the string as placeholders (e.g. {key}).
---@param str string
---@param opts table
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

function M.format_list(list, opts)
  local result = {}
  for _, v in ipairs(list) do
    table.insert(result, M.format(v, opts))
  end
  return result
end

return M
