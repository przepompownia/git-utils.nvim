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

--- @class git-utils.config
local defaultOpts = {
  registerTelescopeExtension = false,
  telescopeAttachMappings = nil, --- @type fun(promptBuffer: string, map: fun()): boolean?
  currentBufferDirectory = GitUtils.currentBufferDirectory,
}

local config = nil

local function top()
  return require('git-utils.git').top(GitUtils.currentBufferDirectory())
end

function GitUtils.branches(opts)
  require('git-utils.telescope.branches').list(vim.tbl_deep_extend('keep', opts or {}, {cwd = top()}))
end

--- @param opts git-utils.config
function GitUtils.setup(opts)
  vim.validate({opts = {opts, 'table', false}})

  --- @type git-utils.config
  config = vim.tbl_extend('keep', opts, defaultOpts)

  if opts.currentBufferDirectory and type(opts.currentBufferDirectory) == 'function' then
    GitUtils.currentBufferDirectory = opts.currentBufferDirectory
  end

  if opts.registerTelescopeExtension then
    require('telescope').load_extension('git_utils')
  end
end

--- @return git-utils.config
function GitUtils.config()
  return config or defaultOpts
end

return GitUtils
