local function notify(msg, level)
  vim.notify(vim.trim(msg), level, {title = 'git commit'})
end

local function notifyError(msg)
  notify(msg, vim.log.levels.ERROR)
end

local function parseMessageBuffer(messageBuffer)
  local messageIt = vim.iter(vim.api.nvim_buf_get_lines(messageBuffer, 0, -1, true))
    :filter(function (line)
      return not vim.startswith(line, '#')
    end)

  while messageIt:peek() and #vim.trim(messageIt:peek()) == 0 do
    messageIt:next()
  end

  return messageIt:next(), messageIt:join('\n')
end

local function tryCommit(messageBuffer, gitDir)
  if not vim.api.nvim_buf_is_valid(messageBuffer) then
    notifyError('Invalid message buffer')
    return
  end

  local title, description = parseMessageBuffer(messageBuffer)

  if nil == title then
    notifyError('Cannot commit with empty message')
    return false
  end

  vim.system(
    {'git', 'commit', '-m', title, '-m', description},
    {text = true, cwd = gitDir},
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
      vim.api.nvim_buf_delete(messageBuffer, {force = true})
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

local function displayCommitMessage(gitDir, confirmKey, content)
  local commitMessagePath = getCommitMessagePath(gitDir)
  local messageBuffer = vim.fn.bufadd(commitMessagePath)

  local bufDelete = vim.api.nvim_create_autocmd('BufDelete', {
    buffer = messageBuffer,
    callback = function ()
      tryCommit(messageBuffer, gitDir)
    end,
  })

  confirmKey = confirmKey or '<C-CR>'

  vim.keymap.set({'n', 'i'}, confirmKey, function ()
    vim.api.nvim_del_autocmd(bufDelete)
    tryCommit(messageBuffer, gitDir)
  end, {buffer = messageBuffer})

  vim.cmd.sbuffer({args = {messageBuffer}, mods = {split = 'botright'}})
  vim.cmd.edit()

  if content.title then
    vim.api.nvim_buf_set_lines(messageBuffer, 0, 1, false, {content.title})
  end

  if #vim.trim(content.description) > 0 then
    local description = vim.split(content.description, '\n')
    vim.api.nvim_buf_set_lines(messageBuffer, 1, #description, false, description)
  end

  vim.api.nvim_win_set_cursor(0, {1, 0})
end

local function prepareCommitView(opts)
  opts = opts or {}
  local gitDir = opts.gitDir or vim.uv.cwd()

  local commitMessagePath = getCommitMessagePath(gitDir)
  local oldMessageBuffer = vim.fn.bufadd(commitMessagePath)
  local title, description = parseMessageBuffer(oldMessageBuffer)

  vim.system(
    {'git', 'commit'},
    {
      text = true,
      env = {GIT_EDITOR = 'cat'},
      cwd = gitDir,
    },
    vim.schedule_wrap(function (obj)
      if 0 == #vim.trim(obj.stderr) then
        vim.print('Nothing to commit yet')
        return
      end
      displayCommitMessage(gitDir, opts.confirmKey, {title = title, description = description})
    end)
  )
end

return setmetatable({}, {
  __call = function (_, ...)
    return prepareCommitView(...)
  end,
})
