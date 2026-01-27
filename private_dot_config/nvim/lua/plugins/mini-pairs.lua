return {
  {
    "nvim-mini/mini.pairs",
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings['"'] = {
        action = "closeopen",
        pair = '""',
        -- Avoid duplicating when closing a string after word characters.
        neigh_pattern = "^[^%w\\]",
        register = { cr = false },
      }
    end,
  },
}
