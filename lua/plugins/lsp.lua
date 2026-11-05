return {
  "neovim/nvim-lspconfig",

  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",

    -- Autocompletion
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "saadparwaiz1/cmp_luasnip",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-nvim-lua",

    -- Snippets
    "L3MON4D3/LuaSnip",
    "rafamadriz/friendly-snippets",
  },

  config = function()
    -- Reserve a space in the gutter
    vim.opt.signcolumn = "yes"

    -- Floating window borders
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
      vim.lsp.handlers.hover,
      { border = "rounded" }
    )

    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
      vim.lsp.handlers.signature_help,
      { border = "rounded" }
    )

    -- Diagnostics
    vim.diagnostic.config({
      virtual_text = true,
      severity_sort = true,

      float = {
        style = "minimal",
        border = "rounded",
        header = "",
        prefix = "",
      },

      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "✘",
          [vim.diagnostic.severity.WARN] = "▲",
          [vim.diagnostic.severity.HINT] = "⚑",
          [vim.diagnostic.severity.INFO] = "»",
        },
      },
    })

    -- Completion capabilities
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- LSP keybindings
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(event)
        local opts = { buffer = event.buf }

        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)
        vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)

        vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
        vim.keymap.set({ "n", "x" }, "<F3>", function()
          vim.lsp.buf.format({ async = true })
        end, opts)
        vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, opts)
      end,
    })

    -- Mason
    require("mason").setup()

    require("mason-lspconfig").setup({
      ensure_installed = {
        "lua_ls",
        "clangd",
        "pyright",
        "cmake",
      },

      handlers = {
        -- Default handler
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
          })
        end,

        -- Lua
        lua_ls = function()
          require("lspconfig").lua_ls.setup({
            capabilities = capabilities,

            settings = {
              Lua = {
                runtime = {
                  version = "LuaJIT",
                },

                diagnostics = {
                  globals = { "vim" },
                },

                workspace = {
                  library = {
                    vim.env.VIMRUNTIME,
                  },
                },
              },
            },
          })
        end,

        -- C / C++
        clangd = function()
          require("lspconfig").clangd.setup({
            capabilities = capabilities,

            cmd = {
              "clangd",
              "--background-index",
              "--clang-tidy",
              "--completion-style=detailed",
            },
          })
        end,

        -- Python
        pyright = function()
          require("lspconfig").pyright.setup({
            capabilities = capabilities,
          })
        end,

        -- CMake
        cmake = function()
          require("lspconfig").cmake.setup({
            capabilities = capabilities,
          })
        end,
      },
    })

    -- nvim-cmp
    local cmp = require("cmp")

    require("luasnip.loaders.from_vscode").lazy_load()

    vim.opt.completeopt = {
      "menu",
      "menuone",
      "noselect",
    }

    cmp.setup({
      preselect = "item",

      completion = {
        completeopt = "menu,menuone,noinsert",
      },

      window = {
        documentation = cmp.config.window.bordered(),
      },

      sources = {
        { name = "path" },
        { name = "nvim_lsp" },
        { name = "buffer", keyword_length = 3 },
        { name = "luasnip", keyword_length = 2 },
      },

      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },

      formatting = {
        fields = { "abbr", "menu", "kind" },

        format = function(entry, item)
          local n = entry.source.name

          if n == "nvim_lsp" then
            item.menu = "[LSP]"
          else
            item.menu = string.format("[%s]", n)
          end

          return item
        end,
      },

      mapping = cmp.mapping.preset.insert({
        -- Confirm completion
        ["<CR>"] = cmp.mapping.confirm({
          select = false,
        }),

        -- Scroll documentation
        ["<C-f>"] = cmp.mapping.scroll_docs(5),
        ["<C-u>"] = cmp.mapping.scroll_docs(-5),

        -- Toggle completion menu
        ["<C-e>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.abort()
          else
            cmp.complete()
          end
        end),

        -- Tab completion
        ["<Tab>"] = cmp.mapping(function(fallback)
          local col = vim.fn.col(".") - 1

          if cmp.visible() then
            cmp.select_next_item({
              behavior = "select",
            })
          elseif col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
            fallback()
          else
            cmp.complete()
          end
        end, { "i", "s" }),

        -- Previous completion
        ["<S-Tab>"] = cmp.mapping.select_prev_item({
          behavior = "select",
        }),

        -- Next snippet placeholder
        ["<C-d>"] = cmp.mapping(function(fallback)
          local luasnip = require("luasnip")

          if luasnip.jumpable(1) then
            luasnip.jump(1)
          else
            fallback()
          end
        end, { "i", "s" }),

        -- Previous snippet placeholder
        ["<C-b>"] = cmp.mapping(function(fallback)
          local luasnip = require("luasnip")

          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
    })
  end,
}
