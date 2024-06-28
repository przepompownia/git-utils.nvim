local function createCommands()
  vim.api.nvim_create_user_command(
    'GDiff',
    function (cmdOpts)
      require('git-utils.telescope.gdiff').run({
        args = cmdOpts.fargs,
        cwd = require('git-utils.git').top(require('git-utils').currentBufferDirectory()),
        attach_mappings = require('git-utils').config().telescopeAttachMappings,
      })
    end,
    {
      nargs = '*',
      complete = function (argLead, _, _)
        local git = require('git-utils.git')
        return git.matchBranchesToRange(require('git-utils.git').top(require('git-utils').currentBufferDirectory()), argLead)
      end,
    }
  )
end

return setmetatable({}, {
  __call = function (_, _)
    return createCommands()
  end,
})
