local M = require('lualine.component'):extend()

local defaultOptions = {
  on_click = function (_numberOfClicks, button, _modifiers)
    if 'r' == button then
      require('git-utils').branches()
    end
  end
}

function M.init(self, options)
  options = vim.tbl_deep_extend('keep', options or {}, defaultOptions)
  require('lualine.components.branch').init(self, options)
end

M.update_status = function (_, is_focused)
  return require('lualine.components.branch').update_status(_, is_focused)
end

return M
