return {
  "timseriakov/spamguard.nvim",
  event = "VeryLazy",
  config = function()
    local spamguard = require("spamguard")
    spamguard.setup({
      keys = {
        j = { threshold = 6, suggestion = "use s or f instead of spamming jjjj 😎" },
        k = { threshold = 6, suggestion = "try 10k instead of spamming kkkk 😎" },
        h = { threshold = 8, suggestion = "use 10h or b / ge 😎" },
        l = { threshold = 8, suggestion = "try w or e — it's faster! 😎" },
        w = { threshold = 5, suggestion = "use s or f — more precise and quicker! 😎" },
      },
    })
    vim.schedule(function()
      spamguard.enable()
    end)
  end,
}
