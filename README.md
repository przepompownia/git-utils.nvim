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
Enable [Telescope]() extensions manually:
```lua
require('telescope').load_extension('git_utils')
```
or enable `registerTelescopeExtension` option in `setup`.

### Grep git diff 
```lua
require'telescope'.extensions.git_utils.grep_git_diff({args = {'master'}})
require'telescope'.extensions.git_utils.grep_git_diff({args = {'master...HEAD'}})
```
```vim
:Telescope git_utils grep_git_diff args=master...HEAD
```
or (if enabled `createCommands`)
```vim
:GDiff master...HEAD
```
(try `<TAB>` to complete branches or tags).

### Push
```lua
require 'git-utils.git'.push(require('git-utils').currentBufferDirectory(), 'origin')
require 'git-utils.git'.pushToAllRemoteRepos(require('git-utils').currentBufferDirectory())
```

# Setup
```lua
require('git-utils').setup(opts)
```
where default opts are:
```lua
--- @class git-utils.defaultOpts
local defaultOpts = {
  createCommands = false, -- if true define GDiff command
  registerTelescopeExtension = false,
  telescopeAttachMappings = nil, --- @type fun(promptBuffer: string, map: fun()): boolean?
  currentBufferDirectory = require('git-utils').currentBufferDirectory, -- function used to return the directory of the current buffer to determine git dir
}
```
