local _, telescope = pcall(require, 'telescope')

return telescope.register_extension {
  exports = {
    grep_git_diff = require('git-utils.telescope.gdiff').run,
    branches = require('git-utils.telescope.branches').list,
  },
}
