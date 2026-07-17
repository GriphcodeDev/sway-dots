-- ========================================================================== --
-- 1. CORE SYSTEM SETTINGS
-- ========================================================================== --
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.smartindent = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.signcolumn = "yes" -- Reserves screen space to prevent LSP layout jitter

-- Stark Minimalist Colorscheme Tweaks with Transparency
vim.cmd([[
  highlight Normal guibg=NONE ctermbg=NONE guifg=#ffffff
  highlight LineNr guibg=NONE ctermbg=NONE guifg=#444444
  highlight CursorLineNr guibg=NONE ctermbg=NONE guifg=#ffffff
  highlight StatusLine guibg=#ffffff guifg=#000000
  highlight StatusLineNC guibg=#222222 guifg=#888888
  highlight VertSplit guibg=NONE ctermbg=NONE guifg=#ffffff
  highlight SignColumn guibg=NONE ctermbg=NONE
]])

-- ========================================================================== --
-- 2. AUTOMATIC LAZY.NVIM BOOTSTRAPPER
-- ========================================================================== --
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ========================================================================== --
-- 3. PLUGIN DEFINITIONS & CONFIGURATION
-- ========================================================================== --
require("lazy").setup({
  -- Sharp File Icons Manager
  { "nvim-tree/nvim-web-devicons", lazy = false },

  -- Stark Discord Rich Presence
  {
    "andweeb/presence.nvim",
    opts = {
      auto_update         = true,
      editing_text        = "Editing %s",
      workspace_text      = "Working on %s",
      buttons             = false, -- Minimal text profile
    }
  },

  -- Core LSP Suite
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim", config = true },
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Automatically hook capabilities setup to modern completion engines
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      require("mason-lspconfig").setup({
        -- Standard language servers auto-boot loader
        ensure_installed = { "lua_ls" }, 
        handlers = {
          function(server_name)
            require("lspconfig")[server_name].setup({
              capabilities = capabilities,
            })
          end,
        }
      })

      -- Keybindings when an active LSP server anchors to a file buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        end,
      })
    end
  }
})

-- ========================================================================== --
-- 4. ULTRA-CUSTOM MONOCHROME STATUS BAR
-- ========================================================================== --
-- Fetch system info once globally to prevent CPU polling strain
local system_os = vim.loop.os_uname().sysname:upper()

local function get_statusline()
  -- A. Fetch the local icon relative to the open layout extension format
  local file_name = vim.fn.expand("%:t")
  local file_ext = vim.fn.expand("%:e")
  local icon = ""
  
  local has_icons, devicons = pcall(require, "nvim-web-devicons")
  if has_icons and file_name ~= "" then
    local ic, _ = devicons.get_icon(file_name, file_ext, { default = true })
    if ic then icon = ic .. " " end
  end

  -- B. File details path configuration
  local display_path = (file_name == "") and "[No Name]" or vim.fn.expand("%:.")
  local modified_flag = vim.bo.modified and " [+" .. "]" or ""

  -- C. Dynamic text alignments parsing
  local left_block   = string.format(" %s%s%s ", icon, display_path, modified_flag)
  local center_split = "%="
  local right_block  = string.format(" [ %s ] [ %s ] [ %%l/%%L ] ", vim.bo.filetype:upper(), system_os)

  return left_block .. center_split .. right_block
end

-- Force global rendering line updates
_G.get_custom_statusline = get_statusline
vim.opt.statusline = "%!v:lua.get_custom_statusline()"

