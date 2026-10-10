-- Catppuccin Macchiato everywhere (WezTerm, tmux, starship, nvim).
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "macchiato",
      custom_highlights = function(c)
        -- Default inline `code` is bright on a high-contrast block; use a
        -- warm foreground on a background just above the editor's.
        local inline_code = { fg = c.peach, bg = c.surface0 }
        return {
          ["@markup.raw.markdown_inline"] = inline_code,
          RenderMarkdownCodeInline = inline_code,
        }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin" },
  },
}
