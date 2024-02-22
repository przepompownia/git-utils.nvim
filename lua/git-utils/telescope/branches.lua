local Branches = {}

local function makeEntry(entry)
  local display = ('%s %s %s'):format(entry.head, entry.branch, entry.desc)
  return {
    value = entry,
    display = display,
    ordinal = entry.branch,
  }
end

function Branches.list(opts)
  opts = opts or {}
  require('telescope.pickers').new(opts, {
    prompt_title = 'Git branches',
    finder = require('telescope.finders').new_table({
      results = require('git-utils.git').branches(opts.cwd, true, true),
      entry_maker = makeEntry,
    }),
    sorter = require('telescope.config').values.generic_sorter(opts),
    attach_mappings = function (promptBufnr)
      require('telescope.actions').select_default:replace(function ()
        require('telescope.actions').close(promptBufnr)
        local selection = require('telescope.actions.state').get_selected_entry()
        local branch = selection.value.branch
        require('git-utils.git').switchToBranch(branch, opts.cwd)
      end)
      return true
    end,
  }):find()
end

return Branches
