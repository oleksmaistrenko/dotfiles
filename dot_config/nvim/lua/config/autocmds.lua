-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function brighten_winsep()
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#7e9cd8", bold = true })
end
brighten_winsep()
vim.api.nvim_create_autocmd("ColorScheme", { callback = brighten_winsep })

local function clear_tree_bg()
  -- SnacksPickerTree links to LineNr (which has a grey bg).
  -- Re-define it standalone: keep LineNr's fg as the line color, drop the bg.
  local linenr = vim.api.nvim_get_hl(0, { name = "LineNr", link = false })
  vim.api.nvim_set_hl(0, "SnacksPickerTree", { fg = linenr.fg })
end
clear_tree_bg()
vim.api.nvim_create_autocmd("ColorScheme", { callback = clear_tree_bg })

vim.api.nvim_create_autocmd("VimEnter", {
  nested = true,
  callback = function()
    -- only auto-load when nvim was started with no file args and no piped input
    if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
      require("persistence").load()
    end
  end,
})
