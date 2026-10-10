-- Builds on the LazyVim lang.markdown extra (enabled in lazyvim.json), which
-- provides marksman LSP and the <leader>um render toggle.

-- render-markdown only draws a separator under the header row, so rows of a
-- wrapped table blur together. Hook its table renderer (private API, recheck
-- after plugin updates) so each body row gets a separator built from the same
-- column widths, including tables it redraws as virtual lines when wider than
-- the window.
local function patch_table_row_separators()
  local Table = require("render-markdown.render.markdown.table")
  if Table._row_separators then
    return
  end
  Table._row_separators = true
  local draw_border = Table.border
  function Table:border(wrapped)
    draw_border(self, wrapped)
    local chars = self.config.border
    local parts = vim.tbl_map(function(col)
      return chars[11]:rep(col.width)
    end, self.data.cols)
    local text = chars[4] .. table.concat(parts, chars[5]) .. chars[6]
    local rows = self.data.rows
    -- rows[1] is the header, which already has the delimiter below it.
    for i = 2, #rows - 1 do
      local line = self:line():pad(self.data.layout.col):text(text, self.config.row)
      local virtual_line = self:indent():line(true):extend(line):get()
      if wrapped[i] then
        table.insert(wrapped[i], virtual_line)
      else
        self.marks:add(self.config, "virtual_lines", rows[i].node.start_row, 0, {
          virt_lines = { virtual_line },
        })
      end
    end
  end
end

-- Terminal can't show images reliably over SSH/tmux, so draw mermaid as
-- box-drawing text with mermaid-ascii (installed by install.sh). It only supports
-- graph/flowchart and sequenceDiagram.
local function preview_mermaid()
  local node = vim.treesitter.get_node({ ignore_injections = true })
  while node and node:type() ~= "fenced_code_block" do
    node = node:parent()
  end
  local info = node and node:child(1)
  local lang = info and info:type() == "info_string" and vim.treesitter.get_node_text(info, 0)
  if not lang or not vim.startswith(vim.trim(lang), "mermaid") then
    vim.notify("Cursor is not inside a ```mermaid block", vim.log.levels.WARN)
    return
  end
  local source
  for child in node:iter_children() do
    if child:type() == "code_fence_content" then
      source = vim.treesitter.get_node_text(child, 0)
    end
  end
  local result = vim.system({ "mermaid-ascii", "-f", "-", "-x", "3", "-y", "2" }, { stdin = source or "" }):wait()
  if result.code ~= 0 then
    vim.notify(vim.trim(result.stderr or ""), vim.log.levels.ERROR, { title = "mermaid-ascii" })
    return
  end
  local lines = vim.split(vim.trim(result.stdout), "\n")
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  Snacks.win({
    text = lines,
    title = " Mermaid ",
    border = "rounded",
    width = math.min(width + 2, vim.o.columns - 4),
    height = math.min(#lines, vim.o.lines - 6),
    wo = { wrap = false },
    bo = { modifiable = false },
  })
end

return {
  -- Browser preview is useless over SSH/tmux, and it would steal <leader>cp
  -- (copy path) in markdown buffers.
  { "iamcco/markdown-preview.nvim", enabled = false },

  -- markdownlint is too noisy for loosely formatted notes.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = { linters_by_ft = { markdown = {} } },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ["markdown"] = { "prettier", "markdown-toc" },
        ["markdown.mdx"] = { "prettier", "markdown-toc" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    -- LazyVim only loads Mason on :Mason or when a file is opened, so
    -- :MasonInstall is missing from a fresh dashboard session.
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "markdownlint-cli2"
      end, opts.ensure_installed or {})
    end,
  },

  -- render-markdown.nvim: renders markdown in-buffer (headings, tables,
  -- code blocks, checkboxes, callouts) without leaving nvim.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      -- Keep the cursor line rendered too; otherwise the row under the cursor
      -- drops to raw pipes and the table misaligns. Insert mode still shows raw
      -- text, and <leader>um toggles rendering off entirely.
      anti_conceal = { enabled = false },

      on = { attach = patch_table_row_separators },

      -- ── Tables ──────────────────────────────────────────────────────────
      -- Render pipe-table borders with box-drawing chars.
      -- Needs Nerd Font glyphs (WezTerm bundles a Nerd Font symbols fallback).
      pipe_table = {
        enabled = true,
        style   = "full",   -- draw all four borders
        cell    = "padded", -- pad cell content for alignment
        -- Draw top/bottom borders even when no blank line surrounds the table.
        border_virtual = true,
      },

      -- ── Headings ────────────────────────────────────────────────────────
      heading = {
        enabled = true,
        sign    = true, -- boolean switch; `signs` is the icon list
        icons   = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },

      -- ── Code blocks ─────────────────────────────────────────────────────
      code = {
        enabled   = true,
        style     = "full",
        sign      = true,
        language  = true, -- show language label
        width     = "block",
        right_pad = 1,
      },

      -- ── Checkboxes ──────────────────────────────────────────────────────
      checkbox = {
        enabled   = true,
        unchecked = { icon = "󰄱 " },
        checked   = { icon = "󰱒 " },
      },

      -- ── Bullet points ───────────────────────────────────────────────────
      bullet = { enabled = true },

      -- No latex parser/converter installed; avoids checkhealth warnings.
      latex = { enabled = false },

      -- ── Callouts / blockquotes (GitHub-style) ───────────────────────────
      -- [!NOTE], [!WARNING], [!TIP], etc.
      callout = {
        note    = { raw = "[!NOTE]",    rendered = "󰋽 Note",    highlight = "RenderMarkdownInfo"    },
        tip     = { raw = "[!TIP]",     rendered = "󰌶 Tip",     highlight = "RenderMarkdownSuccess" },
        warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn"    },
        caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError"   },
      },
    },
    keys = {
      { "<leader>mm", preview_mermaid, ft = "markdown", desc = "Mermaid Preview" },
    },
  },
}
