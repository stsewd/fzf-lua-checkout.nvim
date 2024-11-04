# fzf-lua-checkout.nvim

Manage branches and tags with [fzf-lua](https://github.com/ibhagwan/fzf-lua/)

> This is a port of [fzf-checkout.vim](https://github.com/stsewd/fzf-checkout.vim) for fzf-lua.

## Installation

Install using your favorite package manager, for example with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  -- You must install fzf-lua somewhere in your config.
  { "ibhagwan/fzf-lua" },
  {
    "stsewd/fzf-lua-checkout.nvim",
    keys = {
      {
        "<leader>fb",
        function()
          require("fzf-lua-checkout").branches()
        end,
        { desc = "List git branches" },
      },
      {
        "<leader>ft",
        function()
          require("fzf-lua-checkout").tags()
        end,
        { desc = "List git tags" },
      },
    },
  },
}
```
