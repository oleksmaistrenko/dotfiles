return {
  { import = "lazyvim.plugins.extras.lang.php" },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        php = {},
      },
    },
  },
}
