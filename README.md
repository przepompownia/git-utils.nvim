# git-utils.nvim

Utils moved from https://github.com/przepompownia/nvim-arctgx

## Commit
- open `git commit` dialog without using nested nvim instance and tools like [flatten.nvim](https://github.com/willothy/flatten.nvim) (and while `--remote-wait` [is not implemented](https://github.com/neovim/neovim/issues/24788)):
```lua
require('git-utils.commit')()
require('git-utils.commit')({gitDir = vim.uv.cwd()})
require('git-utils.commit')({gitDir = vim.uv.cwd(), confirmKey = '<C-CR>'}) -- default values (`<C-CR>` may not work in tmux)
```

Use `confirmKey` to override the mapping inside message buffer. 

Probably `require('git-utils.commit')()` won't work on Windows because the commit message template is obtained in some hacky way i.e. using `cat` as `GIT_EDITOR`.

## Telescope extensions
Enable [Telescope]() extensions:
```lua
require('telescope').load_extension('git_utils')
```

### Grep git diff 
```lua
require'telescope'.extensions.git_utils.grep_git_diff({args = {'master'}})
require'telescope'.extensions.git_utils.grep_git_diff({args = {'master...HEAD'}})
```
```vim
Telescope git_utils grep_git_diff args=master...HEAD
```
