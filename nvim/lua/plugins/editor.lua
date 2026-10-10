return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            layout = {
              layout = { position = "right", width = 0.2 },
            },
          },
          -- Include hidden dirs (.github, .claude, .planning, etc.) in grep.
          -- Exclude .git/ itself to avoid crawling git's object store.
          grep = {
            args = { "--hidden", "--glob=!.git/" },
          },
          -- Same for file picker (<leader>ff) so hidden files are findable too.
          files = {
            args = { "--hidden", "--glob=!.git/" },
          },
        },
      },
    },
  },
}
