return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local util = require("lspconfig.util")
      opts.servers = opts.servers or {}
      opts.servers.ts_ls = {
        on_attach = function(client)
          client.server_capabilities.documentFormattingProvider = false
        end,
      }
      opts.servers.biome = {
        cmd = { "biome", "lsp-proxy" },
        filetypes = {
          "astro",
          "css",
          "graphql",
          "javascript",
          "javascriptreact",
          "json",
          "jsonc",
          "svelte",
          "typescript",
          "typescript.tsx",
          "typescriptreact",
          "vue",
        },
        root_dir = util.root_pattern("biome.json", "biome.jsonc"),
        single_file_support = false,
      }
    end,
  },
  {
    "davidmh/mdx.nvim",
    config = function() end,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  -- Disable Snacks.image (terminal image display)
  {
    "folke/snacks.nvim",
    opts = {
      image = { enabled = false },
    },
  },
}
