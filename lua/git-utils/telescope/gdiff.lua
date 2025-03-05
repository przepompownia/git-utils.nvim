local gdiff = {}

---@param command git-utils.cmd.diff
---@return function
local function makeRequest(command)
  command:switchNamesOnly()

  return function (query)
    if ('' ~= query) then
      command:setQuery('-S', query)
    else
      command:unsetShortOptionWithValue('-S')
    end

    local sysObj = vim.system(command, {}):wait()

    return vim.split(sysObj.stdout, '\n', {trimempty = true})
  end
end

---Stolen from telescope
---@param opts table
---@param command git-utils.cmd.diff
---@return table
local function previewer(opts, command)
  return require('telescope.previewers.buffer_previewer').new_buffer_previewer {
    title = 'Grep git diff Preview',
    get_buffer_by_name = function (_, entry) return entry.value end,

    define_preview = function (self, entry, _status)
      local conf = require('telescope.config').values
      if entry.status and (entry.status == '??' or entry.status == 'A ') then
        local p = require('telescope.from_entry').path(entry, true)
        if p == nil or p == '' then return end
        conf.buffer_previewer_maker(p, self.state.bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
        })
      else
        local newCommand = command:clone()
        newCommand:switchNamesOnly()
        newCommand:appendArgument(entry.value)

        local putils = require('telescope.previewers.utils')

        putils.job_maker(newCommand, self.state.bufnr, {
          value = entry.value,
          bufname = self.state.bufname,
          cwd = opts.cwd
        })
        putils.regex_highlighter(self.state.bufnr, 'diff')
      end
    end
  }
end

function gdiff.run(opts)
  opts.args = opts.args or {}

  if type(opts.args) == 'string' then
    opts.args = {opts.args}
  end

  local command = require('git-utils.cmd.diff'):newCommand('GDiff', opts.args, opts.cwd or vim.uv.cwd())

  opts = opts or {}
  require('telescope.pickers').new(opts, {
    prompt_title = 'GDiff',
    finder = require('telescope.finders').new_dynamic({
      fn = makeRequest(command),
      entry_maker = require('telescope.make_entry').gen_from_file(opts),
    }),
    sorter = require('telescope.sorters').empty(),
    previewer = previewer(opts, command),
  }):find()
end

return gdiff
