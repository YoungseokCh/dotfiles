-- Load core configuration
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.lazy")
require("config.options")

local ok, _ = pcall(require, "config.local")
