# git-utils.nvim

- open `git commit` dialog without using nested nvim instance and tools like [flatten.nvim](https://github.com/willothy/flatten.nvim):
```lua
require('git-utils.commit')()
require('git-utils.commit')({gitDir = vim.uv.cwd()})
require('git-utils.commit')({gitDir = vim.uv.cwd(), confirmKey = '<C-CR>'}) -- default values
```

Use `confirmKey` to override the mapping inside message buffer. Probably it won't work on Windows because the commit message template is obtained in some hacky way i.e. using `cat` as `GIT_EDITOR`.
