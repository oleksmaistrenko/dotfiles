return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        files = {
          hidden = true,
        },
        grep = {
          hidden = true,
       },
        explorer = {
          hidden = true,
          layout = {
            layout = {
              position = "right",
            },
          },
        },
      },
    },
    explorer = {
      replace_netrw = true,
    },
  },
}
