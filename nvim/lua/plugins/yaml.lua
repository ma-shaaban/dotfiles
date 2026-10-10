-- K8s-friendly YAML formatting (indentless arrays) instead of prettier.
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { yaml = { "yamlfmt" } },
      formatters = {
        yamlfmt = { prepend_args = { "-formatter", "basic", "-indentless_arrays=true" } },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "yamlfmt" } },
  },
}
