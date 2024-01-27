local function notify(msg, level)
  vim.notify(msg, level, {title = 'git commit'})
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
    return
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

local function displayCommitMessage(content, gitDir, confirmKey)
  local messageBuffer = vim.api.nvim_create_buf(false, true)

  confirmKey = confirmKey or '<C-CR>'

  vim.keymap.set({'n', 'i'}, confirmKey, function ()
    tryCommit(messageBuffer, gitDir)
  end, {buffer = messageBuffer})

  local lines = vim.split(content, '\n')
  local msgTemplate = '# Use %s (in insert and normal mode) to confirm the message and wipe this buffer.'

  table.insert(lines, 2, (msgTemplate):format(confirmKey))

  vim.api.nvim_buf_set_lines(messageBuffer, 0, #lines, false, lines)
  vim.bo[messageBuffer].filetype = 'gitcommit'
  vim.bo[messageBuffer].bufhidden = 'wipe'

  vim.cmd.sbuffer({args = {messageBuffer}, mods = {split = 'botright'}})
end

local function prepareCommitView(opts)
  opts = opts or {}
  local cwd = opts.gitDir or vim.uv.cwd()
  vim.system(
    {'git', 'commit'},
    {
      text = true,
      env = {GIT_EDITOR = 'cat'},
      cwd = cwd,
    },
    vim.schedule_wrap(function (obj)
      if 0 == #vim.trim(obj.stderr) then
        vim.print('Nothing to commit yet')
        return
      end
      displayCommitMessage(obj.stdout, cwd, opts.confirmKey)
    end)
  )
end

return setmetatable({}, {
  __call = function (_, ...)
    return prepareCommitView(...)
  end,
})
