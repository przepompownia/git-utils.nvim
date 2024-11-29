local api = vim.api

--- @alias git-utils.commit.opts {confirmKey: string, gitDir: string, amend: boolean, resetAuthor: boolean}

local function notify(msg, level)
  vim.notify(vim.trim(msg), level, {title = 'git commit'})
end

local function notifyError(msg)
  notify(msg, vim.log.levels.ERROR)
end

local function parseMessageBuffer(messageBuffer)
  local messageIt = vim.iter(api.nvim_buf_get_lines(messageBuffer, 0, -1, true))
    :filter(function (line)
      return not vim.startswith(line, '#')
    end)

  while messageIt:peek() and #vim.trim(messageIt:peek()) == 0 do
    messageIt:next()
  end

  return messageIt:next(), messageIt:join('\n')
end

---@param opts git-utils.commit.opts
local function tryCommit(messageBuffer, opts)
  if not api.nvim_buf_is_valid(messageBuffer) then
    notifyError('Invalid message buffer')
    return
  end

  local title, description = parseMessageBuffer(messageBuffer)

  if nil == title then
    notifyError('Cannot commit with empty message')
    return false
  end

  local command = {'git', 'commit', '-m', title, '-m', description}

  if opts.amend then
    command[#command + 1] = '--amend'
  end

  if true == opts.resetAuthor then
    command[#command + 1] = '--reset-author'
  end

  vim.system(
    command,
    {text = true, cwd = opts.gitDir},
    vim.schedule_wrap(function (obj)
      if #obj.stderr > 0 then
        notifyError(obj.stderr)
      end
      if #obj.stdout > 0 then
        notify(obj.stdout, vim.log.levels.INFO)
      end

      if obj.code ~= 0 then
        return
      end
      api.nvim_buf_delete(messageBuffer, {force = true})
    end)
  )
end

local function absoluteGitDir(gitDir)
  local cmdResult = vim.system({'git', 'rev-parse', '--absolute-git-dir'}, {cwd = gitDir}):wait()
  if cmdResult.code ~= 0 then
    notifyError('Cannot find git dir here: ' .. cmdResult.stderr)
  end

  return vim.trim(cmdResult.stdout)
end

local function getCommitMessagePath(gitDir)
  return vim.fs.joinpath(absoluteGitDir(gitDir), 'COMMIT_EDITMSG')
end

local function displayCommitMessage(opts, content)
  local commitMessagePath = getCommitMessagePath(opts.gitDir)
  local messageBuffer = vim.fn.bufadd(commitMessagePath)

  local bufDelete = api.nvim_create_autocmd('BufDelete', {
    buffer = messageBuffer,
    callback = function ()
      tryCommit(messageBuffer, opts)
    end,
  })

  vim.keymap.set({'n', 'i'}, opts.confirmKey, function ()
    api.nvim_del_autocmd(bufDelete)
    tryCommit(messageBuffer, opts)
  end, {buffer = messageBuffer})

  if content.title then
    api.nvim_buf_set_lines(messageBuffer, 0, 1, false, {content.title})
  end

  if #vim.trim(content.description) > 0 then
    local description = vim.split(content.description, '\n')
    api.nvim_buf_set_lines(messageBuffer, 1, #description, false, description)
  end

  api.nvim_open_win(messageBuffer, true, {
    relative = 'editor',
    width = vim.go.columns,
    height = math.floor(math.min(20, vim.go.lines / 2)),
    anchor = 'SE',
    row = vim.go.lines - 1,
    col = 0,
    border = 'single',
    style = 'minimal',
    title = 'Git Commit',
    title_pos = 'center',
  })

  vim.cmd.normal('gg')
  vim.cmd.edit()
end

---@param opts git-utils.commit.opts
local function prepareCommitView(opts)
  opts = opts or {}
  opts.gitDir = opts.gitDir or vim.uv.cwd()
  opts.confirmKey = opts.confirmKey or '<A-CR>'

  local command = {'git', 'commit'}

  if opts.amend then
    command[#command + 1] = '--amend'
  end

  vim.system(
    command,
    {
      text = true,
      env = {GIT_EDITOR = 'false'},
      cwd = opts.gitDir,
    },
    vim.schedule_wrap(function (obj)
      if 0 == #vim.trim(obj.stderr) then
        vim.print('Nothing to commit yet')
        return
      end

      local commitMessagePath = getCommitMessagePath(opts.gitDir)
      local oldMessageBuffer = vim.fn.bufadd(commitMessagePath)
      local title, description = parseMessageBuffer(oldMessageBuffer)
      displayCommitMessage(opts, {title = title, description = description})
    end)
  )
end

--- @class git-utils.commit
return setmetatable({}, {
  __call = function (_, opts)
    return prepareCommitView(opts)
  end,
})
