local git = {}

local function gsplit(text)
  return vim.gsplit(text, '\n', {trimempty = true})
end

---@param command string[]
---@param opts vim.SystemOpts
---@return string[]
local function system(command, opts)
  local out = {}
  local function prepareOutput(_, data)
    if nil == data then
      return
    end
    for line in gsplit(data) do
      out[#out + 1] = line
    end
  end

  opts.stdout = prepareOutput
  local job = vim.system(command, opts)
  job:wait()

  return out
end

function git.top(relativeDir)
  local out = vim.system({'git', 'rev-parse', '--show-toplevel'}, {cwd = relativeDir}):wait()

  if out.code > 0 then
    vim.notify(('Cannot determine top level directory for %s'):format(relativeDir), vim.log.levels.WARN, {title = 'git'})

    return relativeDir
  end

  return vim.trim(out.stdout)
end

function git.remote(relativeDir, gitRemoteOpts)
  return system({'git', 'remote', unpack(gitRemoteOpts or {})}, {cwd = relativeDir, text = false})
end

function git.push(relativeDir, remoteRepo)
  local stdout = {}
  local stderr = {}
  local logLevel = vim.log.levels.INFO

  local function printMessages(data, level)
    if 0 == #data then
      return
    end

    local out = table.concat(data, '\n')
    vim.schedule(function ()
      vim.notify(('%s: %s'):format(remoteRepo, out), level, {title = 'git push'})
    end)
  end

  local function insertOutput(storage)
    return function (_, data)
      if nil == data then
        return
      end
      table.insert(storage, vim.trim(data))
    end
  end

  vim.system(
    {'git', 'push', remoteRepo},
    {
      cwd = relativeDir,
      stdout = insertOutput(stdout),
      stderr = insertOutput(stderr),
      detach = true,
    },
    function (obj)
      if 0 < obj.code then
        logLevel = vim.log.levels.ERROR
      end

      printMessages(stdout, logLevel)
      printMessages(stderr, logLevel)
    end
  )
end

function git.pushToAllRemoteRepos(relativeDir)
  local repos = git.remote(relativeDir)
  for _, repo in ipairs(repos) do
    git.push(relativeDir, repo)
  end
end

function git.commandFiles()
  return {'git', 'ls-files'}
end

function git.isTracked(path, gitDir, workTree)
  local cmd = {
    'git',
    '--git-dir', gitDir,
    '--work-tree', workTree,
    'ls-files',
    '--error-unmatch',
    path,
  }
  local obj = vim.system(cmd):wait()

  return 0 == obj.code
end

local function trimHead(text)
  text = vim.trim(text or '')
  if #text == 0 then
    return nil
  end
  return text
end

---@return {branch: string, desc: string, head: string?}[]
function git.branches(gitDir, withRelativeDate, keepEmpty)
  local relativeDatePart = withRelativeDate and ';%09%(committerdate:relative)' or ''
  local function formatArgs(strip)
    return ('%%(committerdate:unix);%%(HEAD);%%(refname:strip=%s)%s'):format(strip, relativeDatePart)
  end
  local emptyValue = nil
  if true == keepEmpty then
    emptyValue = ''
  end

  local out = {}

  local function prepareOutput(_, data)
    if nil == data then
      return
    end
    for line in gsplit(data) do
      local timestamp, head, branch, desc = unpack(vim.split(line, ';'))
      if out[branch] then
        return
      end
      out[branch] = {
        timestamp = tonumber(timestamp),
        branch = branch,
        desc = trimHead(desc) or emptyValue,
        head = trimHead(head) or emptyValue,
      }
    end
  end

  vim.system({
    'git',
    'for-each-ref',
    '--format',
    formatArgs(2),
    '--sort',
    'committerdate:relative',
    'refs/tags/*',
    'refs/tags/*/**',
    'refs/heads/*',
    'refs/heads/*/**',
  }, {cwd = gitDir, stdout = prepareOutput}):wait()
  vim.system({
    'git',
    'for-each-ref',
    '--format',
    formatArgs(3),
    '--sort',
    'committerdate:relative',
    'refs/remotes/*/*',
    'refs/remotes/*/*/**',
  }, {cwd = gitDir, stdout = prepareOutput}):wait()

  local result = vim.tbl_values(out)
  table.sort(result, function (a, b)
    return (a.timestamp or 0) > (b.timestamp or 0)
  end)

  return result
end

---@param range string
---@return {lead: string, part: string}
local function splitRange(range)
  local separators = {
    ['..'] = '\\.\\.',
    ['...'] = '\\.\\.\\.',
  }
  for separator, separatorPattern in pairs(separators) do
    local separatorStart, _separatorEnd = range:find(separator, 1, true)
    if nil ~= separatorStart then
      local lead, part = unpack(vim.fn.split(range, separatorPattern, 1))
      return {
        lead = lead .. separator,
        part = part,
      }
    end
  end

  return {
    lead = '',
    part = range,
  }
end

function git.matchBranchesToRange(topDir, range)
  local branches = git.branches(topDir, false)
  local split = splitRange(range)
  local result = {}

  for _, branch in pairs(branches) do
    if branch.branch:find(split.part, 1, true) then
      table.insert(result, split.lead .. branch.branch)
    end
  end

  return result
end

function git.switchToBranch(branch, cwd, _noHooks)
  local cmd = {'git', '-c', 'core.hooksPath=', 'switch', branch}
  local _stdout, exitCode, stderr = require('telescope.utils').get_os_command_output(cmd, cwd)

  if {} ~= stderr then
    vim.notify(table.concat(stderr, '\n'), vim.log.levels.INFO, {title = 'git switch'})
  end

  if 0 ~= exitCode then
    return
  end
  vim.schedule(function ()
    vim.api.nvim_cmd({cmd = 'checktime'}, {})
  end)
end

return git
