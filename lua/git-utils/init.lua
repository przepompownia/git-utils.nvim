local GitUtils = {}

--- @return string
function GitUtils.currentBufferDirectory()
  local buf = vim.api.nvim_get_current_buf()
  local ok, fileDir = pcall(vim.uv.fs_realpath, vim.api.nvim_buf_get_name(buf))
  if not ok or fileDir == nil then
    return assert(vim.uv.cwd())
  end

  return vim.fs.dirname(fileDir)
end

--- @class git-utils.defaultOpts
local defaultOpts = {
  createCommands = false,
  registerTelescopeExtension = false,
  telescopeAttachMappings = nil, --- @type fun(promptBuffer: string, map: fun()): boolean?
  currentBufferDirectory = GitUtils.currentBufferDirectory,
}

local function top()
  return require('git-utils.git').top(GitUtils.currentBufferDirectory())
end

--- @param opts git-utils.defaultOpts
local function createCommands(opts)
  vim.api.nvim_create_user_command(
    'GDiff',
    function (cmdOpts)
      require('git-utils.telescope.gdiff').run({
        args = cmdOpts.fargs,
        cwd = top(),
        attach_mappings = opts.telescopeAttachMappings,
      })
    end,
    {
      nargs = '*',
      complete = function (argLead, _, _)
        local git = require('git-utils.git')
        return git.matchBranchesToRange(top(), argLead)
      end,
    }
  )
end

function GitUtils.branches(opts)
  require('git-utils.telescope.branches').list(vim.tbl_deep_extend('keep', opts or {}, {cwd = top()}))
end

--- @param opts git-utils.defaultOpts
function GitUtils.setup(opts)
  vim.validate({opts = {opts, 'table', false}})

  --- @type git-utils.defaultOpts
  opts = vim.tbl_extend('keep', opts, defaultOpts)

  if opts.currentBufferDirectory and type(opts.currentBufferDirectory) == 'function' then
    GitUtils.currentBufferDirectory = opts.currentBufferDirectory
  end

  if opts.createCommands then
    createCommands(opts)
  end

  if opts.registerTelescopeExtension then
    require('telescope').load_extension('git_utils')
  end
end

return GitUtils
