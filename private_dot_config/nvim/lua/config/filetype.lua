vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.html",
  callback = function()
    -- Only check the first 500 lines for performance
    local lines = vim.api.nvim_buf_get_lines(0, 0, 500, false)
    for _, line in ipairs(lines) do
      if line:match("{{") then
        vim.bo.filetype = "gohtmltmpl"
        break
      end
    end
  end,
  group = vim.api.nvim_create_augroup("GoHtmlTmplDetect", { clear = true }),
})
