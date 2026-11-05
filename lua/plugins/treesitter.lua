return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",

  config = function()
    require("nvim-treesitter").setup({
      ensure_installed = {
        "lua",
        "python",
        "cmake",
        "cpp",
      },

      auto_install = true,
    })
  end,
}

