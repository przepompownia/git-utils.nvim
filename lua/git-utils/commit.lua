local function tryCommit(messageBuffer, gitDir)
  if not vim.api.nvim_buf_is_valid(messageBuffer) then
    vim.notify('Invalid message buffer', vim.log.levels.ERROR, {title = 'git commit'})
    return
  end

  local messageIt = vim.iter(vim.api.nvim_buf_get_lines(messageBuffer, 0, -1, true))
    :filter(function (line)
      return not vim.startswith(line, '#')
    end)

  while messageIt:peek() and #vim.trim(messageIt:peek()) == 0 do
    messageIt:next()
  end

  local title = messageIt:next()
  local description = messageIt:join('\n')

  if nil == title then
    vim.notify('Cannot commit with empty message', vim.log.levels.ERROR, {title = 'git commit'})
    return
  end

  vim.system(
    {'git', 'commit', '-m', title, '-m', description},
    {text = true, cwd = gitDir},
    vim.schedule_wrap(function (obj)
      if #obj.stderr > 0 then
        vim.notify(obj.stderr, vim.log.levels.ERROR, {title = 'git commit'})
      end
      if #obj.stdout > 0 then
        vim.notify(obj.stdout, vim.log.levels.INFO, {title = 'git commit'})
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
