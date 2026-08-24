-- Interactive snippet creation, no Lua required: `:SnippetNew` first asks what kind
-- of snippet you want —
--   - Static text: the classic case. Asks filetype/trigger/name, then opens a
--     floating buffer to type the body (VSCode-style $1 / ${1:default} / $0
--     placeholders). Saved as VSCode-format JSON in lua/snippets/vscode/<ft>.json
--     (the same format/loader friendly-snippets itself uses).
--   - Smart: treesitter / Smart: regex: snippets that look at the buffer and
--     generate content from what they find (e.g. grab a function's parameter names).
--     Asks a few extraction-config questions (see lua/snippet_engine.lua for what
--     they mean — :SnippetInspectNode helps fill them in), then opens a structured
--     editor for the header/line-template/footer. Saved to
--     lua/snippets/smart/<ft>.json, built into a real snippet by snippet_engine.lua.
-- Either way it's registered live immediately, no restart needed.
--
-- Creating a snippet whose trigger already exists (including friendly-snippets'
-- bundled ones) offers to override it: the old trigger is removed from the live
-- session and recorded in lua/snippets/vscode/_excluded.json so the override still
-- applies after a restart, once that filetype's snippets are (re)loaded. Works the
-- same regardless of which kind is doing the overriding.
--
-- :SnippetEdit [filetype] / :SnippetEditSmart [filetype] open the respective
-- personal JSON file directly for hand-editing — the picker's edit action only
-- covers the body (plain) or header/template/footer (smart); changing a trigger,
-- name, or a smart snippet's extraction config means editing the file.
--
-- :SnippetList browses everything — personal (plain + smart) and friendly-snippets'
-- full bundled set — in one Snacks picker. <CR> edits/clones depending on source
-- (a friendly-snippets item clones into an editable override, skipping the
-- prompts). <C-x> deletes/restores, <C-n> starts :SnippetNew. See its own comment
-- further down for full details.
--
-- :SnippetInspectNode — treesitter node/field inspector, for authoring "smart"
-- snippets. See its own comment further down.

local util = require 'snippet_util'
local read_json = util.read_json

local snippet_dir = util.vscode_dir
local excluded_file = util.excluded_file
local manifest_file = snippet_dir .. '/package.json'

-- entries: { [name] = { prefix = str, body = {line, ...}, description = str } }
local function serialize_snippet_file(entries)
  local names = vim.tbl_keys(entries)
  table.sort(names)
  if #names == 0 then
    return '{}\n'
  end
  local parts = {}
  for _, name in ipairs(names) do
    local e = entries[name]
    local body_lines = {}
    for _, line in ipairs(e.body) do
      table.insert(body_lines, '      ' .. vim.json.encode(line))
    end
    table.insert(
      parts,
      table.concat({
        '  ' .. vim.json.encode(name) .. ': {',
        '    "prefix": ' .. vim.json.encode(e.prefix) .. ',',
        '    "body": [',
        table.concat(body_lines, ',\n'),
        '    ],',
        '    "description": ' .. vim.json.encode(e.description or ''),
        '  }',
      }, '\n')
    )
  end
  return '{\n' .. table.concat(parts, ',\n') .. '\n}\n'
end

local function write_file(path, text)
  util.write_file(vim.fn.fnamemodify(path, ':h'), path, text)
end

local function serialize_manifest(languages)
  table.sort(languages)
  local parts = {}
  for _, lang in ipairs(languages) do
    table.insert(parts, ('    { "language": %s, "path": %s }'):format(vim.json.encode(lang), vim.json.encode('./' .. lang .. '.json')))
  end
  return table.concat({
    '{',
    '  "contributes": {',
    '    "snippets": [',
    table.concat(parts, ',\n'),
    '    ]',
    '  }',
    '}',
  }, '\n') .. '\n'
end

-- from_vscode (unlike the lua loader) requires a package.json manifest listing which
-- file provides which language's snippets — this keeps it in sync whenever a new
-- filetype gets its first personal snippet.
local function ensure_manifest_entry(ft)
  local manifest = read_json(manifest_file, { contributes = { snippets = {} } })
  local languages = {}
  local have_ft = false
  for _, entry in ipairs((manifest.contributes or {}).snippets or {}) do
    table.insert(languages, entry.language)
    if entry.language == ft then
      have_ft = true
    end
  end
  if have_ft then
    return
  end
  table.insert(languages, ft)
  write_file(manifest_file, serialize_manifest(languages))
end

local invalidate = util.invalidate
local exclude_trigger = util.exclude_trigger
local unexclude_trigger = util.unexclude_trigger
util.ensure_exclusion_hook()

-- Upserts entries[name] (keyed by name — renaming isn't supported via the editor UI,
-- only body edits are; use :SnippetEdit for that). Invalidates any prior live copy of
-- our own for this exact ft+trigger first, so editing never leaves a stale duplicate.
--
-- `was_override`: excludes the non-personal original at save time (not before) — so
-- opening the editor for an override and then cancelling (q) never leaves the
-- original suppressed with nothing to replace it.
local function save_snippet(ft, trigger, name, body_lines, was_override)
  invalidate(ft, trigger, true)
  if was_override then
    exclude_trigger(ft, trigger)
  end

  ensure_manifest_entry(ft)
  local path = snippet_dir .. '/' .. ft .. '.json'
  local entries = read_json(path, {})
  entries[name] = { prefix = trigger, body = body_lines, description = name }
  write_file(path, serialize_snippet_file(entries))

  local ok, snip = pcall(require('luasnip.util.parser').parse_snippet, { trig = trigger, name = name }, table.concat(body_lines, '\n'))
  if ok then
    snip.personal_override = true
    require('luasnip').add_snippets(ft, { snip })
    vim.notify(('Snippet "%s" (%s) saved for %s'):format(name, trigger, ft), vim.log.levels.INFO)
  else
    vim.notify('Saved to disk, but failed to parse for live use: ' .. tostring(snip), vim.log.levels.WARN)
  end
end

-- Generic floating scratch-buffer editor: :w saves (calls on_save with the buffer's
-- lines), q cancels. Used for both the plain snippet body and the smart-snippet
-- sections editor below.
local function open_floating_editor(opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = opts.filetype or ''
  vim.bo[buf].buftype = 'acwrite'
  vim.bo[buf].bufhidden = 'wipe'
  vim.api.nvim_buf_set_name(buf, 'snippet://edit/' .. (opts.filetype or 'text') .. '/' .. os.time())
  if opts.initial_lines and #opts.initial_lines > 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, opts.initial_lines)
  end

  local width = math.floor(vim.o.columns * (opts.width_pct or 0.6))
  local height = math.floor(vim.o.lines * (opts.height_pct or 0.4))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = opts.title,
    title_pos = 'center',
  })

  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      vim.bo[buf].modified = false
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      opts.on_save(lines)
    end,
  })
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, desc = 'Cancel' })
end

--- Smart snippets (lua/snippets/smart/<ft>.json, see lua/snippet_engine.lua) ------

local function json_array(list, indent)
  if #list == 0 then
    return '[]'
  end
  local pad = string.rep('  ', indent)
  local pad2 = string.rep('  ', indent + 1)
  local parts = {}
  for _, v in ipairs(list) do
    table.insert(parts, pad2 .. vim.json.encode(v))
  end
  return '[\n' .. table.concat(parts, ',\n') .. '\n' .. pad .. ']'
end

local function serialize_smart_file(entries)
  local names = vim.tbl_keys(entries)
  table.sort(names)
  if #names == 0 then
    return '{}\n'
  end
  local parts = {}
  for _, name in ipairs(names) do
    local cfg = entries[name]
    local fields = {
      '    "trigger": ' .. vim.json.encode(cfg.trigger) .. ',',
      '    "kind": ' .. vim.json.encode(cfg.kind) .. ',',
      '    "direction": ' .. vim.json.encode(cfg.direction) .. ',',
    }
    if cfg.kind == 'treesitter' then
      vim.list_extend(fields, {
        '    "node_types": ' .. json_array(cfg.node_types, 2) .. ',',
        '    "field": ' .. vim.json.encode(cfg.field) .. ',',
        '    "item_field": ' .. vim.json.encode(cfg.item_field or '') .. ',',
      })
    else
      vim.list_extend(fields, {
        '    "pattern": ' .. vim.json.encode(cfg.pattern) .. ',',
        '    "max_lines": ' .. vim.json.encode(cfg.max_lines or 20) .. ',',
        '    "multi": ' .. vim.json.encode(cfg.multi and true or false) .. ',',
      })
    end
    vim.list_extend(fields, {
      '    "header": ' .. json_array(cfg.header or {}, 2) .. ',',
      '    "line_template": ' .. vim.json.encode(cfg.line_template) .. ',',
      '    "footer": ' .. json_array(cfg.footer or {}, 2) .. ',',
      '    "empty_message": ' .. vim.json.encode(cfg.empty_message or 'Nothing found'),
    })
    table.insert(parts, '  ' .. vim.json.encode(name) .. ': {\n' .. table.concat(fields, '\n') .. '\n  }')
  end
  return '{\n' .. table.concat(parts, ',\n') .. '\n}\n'
end

-- The structured sections editor: header/footer (multi-line, static text around the
-- generated block) and line_template/empty_message (one line each) all live in one
-- floating buffer, separated by marker comment lines, so editing a smart snippet
-- feels like editing one file rather than answering a string of separate prompts.
local SECTION_ORDER = { 'header', 'line_template', 'footer', 'empty_message' }
local SECTION_MARKERS = {
  header = '-- HEADER (static lines before the generated ones; delete this line for none) --',
  line_template = '-- LINE TEMPLATE (one line: {{field}} substitutions + optional ${1:default}) --',
  footer = '-- FOOTER (static lines after the generated ones; delete this line for none) --',
  empty_message = '-- MESSAGE WHEN NOTHING IS FOUND --',
}

local function sections_to_lines(sections)
  local lines = {}
  for _, key in ipairs(SECTION_ORDER) do
    table.insert(lines, SECTION_MARKERS[key])
    if key == 'header' or key == 'footer' then
      vim.list_extend(lines, sections[key] or {})
    else
      table.insert(lines, sections[key] or '')
    end
  end
  return lines
end

local function lines_to_sections(lines)
  local marker_to_key = {}
  for key, marker in pairs(SECTION_MARKERS) do
    marker_to_key[marker] = key
  end
  local sections = { header = {}, line_template = '', footer = {}, empty_message = '' }
  local current
  for _, line in ipairs(lines) do
    if marker_to_key[line] then
      current = marker_to_key[line]
    elseif current == 'header' or current == 'footer' then
      table.insert(sections[current], line)
    elseif current == 'line_template' or current == 'empty_message' then
      if sections[current] == '' then
        sections[current] = line
      end
    end
  end
  -- an untouched, deliberately-empty header/footer collects one blank line — drop it
  for _, key in ipairs { 'header', 'footer' } do
    if #sections[key] == 1 and sections[key][1] == '' then
      sections[key] = {}
    end
  end
  return sections
end

local function open_sections_editor(ft, sections, on_save)
  open_floating_editor {
    filetype = '',
    initial_lines = sections_to_lines(sections),
    width_pct = 0.7,
    height_pct = 0.5,
    title = ' Smart snippet template — :w to save, q to cancel ',
    on_save = function(lines)
      on_save(lines_to_sections(lines))
    end,
  }
end

-- was_override: same meaning/timing as save_snippet's — excludes the non-personal
-- original at save time, not before, so cancelling never leaves it suppressed.
local function save_smart_snippet(ft, trigger, name, meta, sections, was_override)
  invalidate(ft, trigger, true)
  if was_override then
    exclude_trigger(ft, trigger)
  end

  local path = util.smart_dir .. '/' .. ft .. '.json'
  local entries = read_json(path, {})
  local cfg = vim.tbl_extend('force', { trigger = trigger }, meta, sections)
  entries[name] = cfg
  write_file(path, serialize_smart_file(entries))

  local engine = require 'snippet_engine'
  local ok, snip = pcall(engine.build_snippet, vim.tbl_extend('force', { name = name }, cfg))
  if ok then
    require('luasnip').add_snippets(ft, { snip })
    vim.notify(('Smart snippet "%s" (%s) saved for %s'):format(name, trigger, ft), vim.log.levels.INFO)
  else
    vim.notify('Saved to disk, but failed to build for live use: ' .. tostring(snip), vim.log.levels.WARN)
  end
end

local function open_body_editor(ft, initial_lines, on_save)
  open_floating_editor {
    filetype = ft,
    initial_lines = initial_lines,
    title = ' Snippet body — $1 / ${1:default} / $0, :w to save, q to cancel ',
    on_save = on_save,
  }
end

-- Prompts for a treesitter smart-snippet's extraction config. Run :SnippetInspectNode
-- on real code first if you don't already know the node_types/field/item_field values.
local function prompt_treesitter_meta(on_done)
  vim.ui.select({ 'below', 'above' }, { prompt = 'Search direction (relative to cursor):' }, function(direction)
    if not direction then
      return
    end
    vim.ui.input({ prompt = 'Node type(s), comma-separated (e.g. function_declaration,arrow_function): ' }, function(types_str)
      if not types_str or types_str == '' then
        return
      end
      vim.ui.input({ prompt = 'Field to read on that node (e.g. parameters): ' }, function(field)
        if not field or field == '' then
          return
        end
        vim.ui.input({ prompt = 'Field to read on each item (e.g. pattern; blank = use the item itself): ' }, function(item_field)
          on_done {
            kind = 'treesitter',
            direction = direction,
            node_types = vim.split(types_str, '%s*,%s*'),
            field = field,
            item_field = (item_field and item_field ~= '') and item_field or nil,
          }
        end)
      end)
    end)
  end)
end

-- Prompts for a regex smart-snippet's extraction config.
local function prompt_regex_meta(on_done)
  vim.ui.select({ 'below', 'above' }, { prompt = 'Search direction (relative to cursor):' }, function(direction)
    if not direction then
      return
    end
    vim.ui.input({ prompt = [[Vim-regex pattern (\(...\) for capture groups): ]] }, function(pattern)
      if not pattern or pattern == '' then
        return
      end
      vim.ui.input({ prompt = 'Max lines to search: ', default = '20' }, function(max_lines_str)
        vim.ui.select({ 'Only nearest match', 'All matches in range' }, { prompt = 'How many matches?' }, function(multi_choice)
          if not multi_choice then
            return
          end
          on_done {
            kind = 'regex',
            direction = direction,
            pattern = pattern,
            max_lines = tonumber(max_lines_str) or 20,
            multi = multi_choice == 'All matches in range',
          }
        end)
      end)
    end)
  end)
end

local DEFAULT_SECTIONS = {
  header = {},
  line_template = ' * {{name}}: ${1:value}',
  footer = {},
  empty_message = 'Nothing found',
}

local function snippet_new()
  vim.ui.select({ 'Static text', 'Smart: treesitter', 'Smart: regex' }, { prompt = 'Snippet kind:' }, function(kind_choice)
    if not kind_choice then
      return
    end

    vim.ui.input({ prompt = 'Filetype: ', default = vim.bo.filetype }, function(ft)
      if not ft or ft == '' then
        return
      end
      vim.ui.input({ prompt = 'Trigger: ' }, function(trigger)
        if not trigger or trigger == '' then
          return
        end
        vim.ui.input({ prompt = 'Name/description: ', default = trigger }, function(name)
          if not name or name == '' then
            return
          end

          -- Make sure friendly-snippets/luasnip are actually loaded before inspecting them.
          pcall(function()
            require('lazy').load { plugins = { 'nvim-cmp' } }
          end)

          local existing = {}
          local ok, luasnip = pcall(require, 'luasnip')
          if ok then
            for _, snip in ipairs(luasnip.get_snippets(ft) or {}) do
              if snip.trigger == trigger then
                table.insert(existing, snip)
              end
            end
          end

          local function proceed(override)
            if kind_choice == 'Static text' then
              open_body_editor(ft, nil, function(lines)
                save_snippet(ft, trigger, name, lines, override)
              end)
              return
            end

            local prompt_meta = kind_choice == 'Smart: treesitter' and prompt_treesitter_meta or prompt_regex_meta
            prompt_meta(function(meta)
              open_sections_editor(ft, DEFAULT_SECTIONS, function(sections)
                save_smart_snippet(ft, trigger, name, meta, sections, override)
              end)
            end)
          end

          if #existing > 0 then
            vim.ui.select({ 'Override existing', 'Add alongside (both will show)', 'Cancel' }, {
              prompt = ("Trigger '%s' already exists for %s:"):format(trigger, ft),
            }, function(choice)
              if choice == 'Override existing' then
                proceed(true)
              elseif choice and choice:match '^Add alongside' then
                proceed(false)
              end
            end)
          else
            proceed(false)
          end
        end)
      end)
    end)
  end)
end

vim.api.nvim_create_user_command('SnippetNew', snippet_new, { desc = 'Create a new snippet interactively' })

vim.api.nvim_create_user_command('SnippetEdit', function(cmd_opts)
  local ft = cmd_opts.args ~= '' and cmd_opts.args or vim.bo.filetype
  if ft == '' then
    vim.notify('No filetype to edit snippets for', vim.log.levels.WARN)
    return
  end
  ensure_manifest_entry(ft)
  local path = snippet_dir .. '/' .. ft .. '.json'
  if vim.fn.filereadable(path) == 0 then
    write_file(path, '{}\n')
  end
  vim.cmd.edit(path)
end, { nargs = '?', desc = 'Edit personal snippets (VSCode JSON) for a filetype' })

-- Hand-editing counterpart to :SnippetEdit, but for smart snippets — the picker's
-- <CR> only lets you touch header/line_template/footer/empty_message; changing
-- node_types/field/pattern/etc. means editing this file directly.
vim.api.nvim_create_user_command('SnippetEditSmart', function(cmd_opts)
  local ft = cmd_opts.args ~= '' and cmd_opts.args or vim.bo.filetype
  if ft == '' then
    vim.notify('No filetype to edit smart snippets for', vim.log.levels.WARN)
    return
  end
  local path = util.smart_dir .. '/' .. ft .. '.json'
  if vim.fn.filereadable(path) == 0 then
    write_file(path, '{}\n')
  end
  vim.cmd.edit(path)
end, { nargs = '?', desc = 'Edit personal smart snippets (JSON) for a filetype' })

-- :SnippetList — Snacks picker over every personal snippet (plain + smart) and
-- friendly-snippets' full bundled set. <CR> edits/clones depending on source, <C-x>
-- deletes it (and if it was an override, restores the friendly-snippets original in
-- the same step — there's no such thing as "restored but still overridden"). <C-n>
-- starts :SnippetNew without leaving the picker.

local function list_personal_fts()
  local fts = {}
  for _, path in ipairs(vim.fn.glob(snippet_dir .. '/*.json', true, true)) do
    local ft = vim.fn.fnamemodify(path, ':t:r')
    if ft ~= 'package' and ft ~= '_excluded' then
      table.insert(fts, ft)
    end
  end
  return fts
end

local function collect_personal_items()
  local excluded = read_json(excluded_file, {})
  local items = {}
  for _, ft in ipairs(list_personal_fts()) do
    local entries = read_json(snippet_dir .. '/' .. ft .. '.json', {})
    local is_excluded_ft = excluded[ft] or {}
    for name, e in pairs(entries) do
      local is_override = vim.tbl_contains(is_excluded_ft, e.prefix)
      table.insert(items, {
        text = ft .. ' ' .. e.prefix .. ' ' .. name,
        ft = ft,
        name = name,
        trigger = e.prefix,
        description = e.description,
        body = e.body,
        is_override = is_override,
        source = is_override and 'personal-override' or 'personal',
      })
    end
  end
  table.sort(items, function(a, b)
    if a.ft ~= b.ft then
      return a.ft < b.ft
    end
    return a.trigger < b.trigger
  end)
  return items
end

local function list_smart_fts()
  local fts = {}
  for _, path in ipairs(vim.fn.glob(util.smart_dir .. '/*.json', true, true)) do
    table.insert(fts, vim.fn.fnamemodify(path, ':t:r'))
  end
  return fts
end

local function collect_smart_items()
  local excluded = read_json(excluded_file, {})
  local items = {}
  for _, ft in ipairs(list_smart_fts()) do
    local entries = read_json(util.smart_dir .. '/' .. ft .. '.json', {})
    local is_excluded_ft = excluded[ft] or {}
    for name, cfg in pairs(entries) do
      local is_override = vim.tbl_contains(is_excluded_ft, cfg.trigger)
      table.insert(items, {
        text = ft .. ' ' .. cfg.trigger .. ' ' .. name,
        ft = ft,
        name = name,
        trigger = cfg.trigger,
        description = cfg.kind .. ' (' .. cfg.direction .. ')',
        cfg = cfg,
        is_override = is_override,
        source = is_override and 'smart-override' or 'smart',
      })
    end
  end
  return items
end

-- Cached after first read — friendly-snippets ships ~150 JSON files; reparsing them
-- on every :SnippetList open would be wasteful for data that never changes at runtime.
local friendly_items_cache = nil

local function to_list(v)
  if v == nil then
    return {}
  end
  return type(v) == 'table' and v or { v }
end

local function find_friendly_snippets_manifest()
  for _, f in ipairs(vim.api.nvim_get_runtime_file('package.json', true)) do
    if f:match 'friendly%-snippets' then
      return f
    end
  end
  return nil
end

local function collect_friendly_items()
  if friendly_items_cache then
    return friendly_items_cache
  end

  local manifest_path = find_friendly_snippets_manifest()
  if not manifest_path then
    friendly_items_cache = {}
    return friendly_items_cache
  end

  local manifest = read_json(manifest_path, {})
  local root = vim.fn.fnamemodify(manifest_path, ':h')
  local items = {}

  for _, file_entry in ipairs((manifest.contributes or {}).snippets or {}) do
    local langs = to_list(file_entry.language)
    local file_path = root .. '/' .. (file_entry.path:gsub('^%./', ''))
    local entries = read_json(file_path, {})
    for name, e in pairs(entries) do
      if type(e) == 'table' and e.prefix and e.body then
        local prefixes = to_list(e.prefix)
        local body = to_list(e.body)
        for _, ft in ipairs(langs) do
          -- "all"/"global" are friendly-snippets pseudo-filetypes, not real ones
          if ft ~= 'all' and ft ~= 'global' then
            for _, prefix in ipairs(prefixes) do
              table.insert(items, {
                text = ft .. ' ' .. prefix .. ' ' .. name,
                ft = ft,
                name = name,
                trigger = prefix,
                description = e.description,
                body = body,
                source = 'friendly',
              })
            end
          end
        end
      end
    end
  end

  friendly_items_cache = items
  return items
end

local function remove_json_entry(ft, name)
  local path = snippet_dir .. '/' .. ft .. '.json'
  local entries = read_json(path, {})
  entries[name] = nil
  write_file(path, serialize_snippet_file(entries))
end

local function remove_smart_json_entry(ft, name)
  local path = util.smart_dir .. '/' .. ft .. '.json'
  local entries = read_json(path, {})
  entries[name] = nil
  write_file(path, serialize_smart_file(entries))
end

local function edit_snippet_item(item)
  open_body_editor(item.ft, item.body, function(lines)
    save_snippet(item.ft, item.trigger, item.name, lines, item.is_override)
  end)
end

-- Enter on a friendly-snippets item: clone it straight into an editable override,
-- pre-filled with the original's body — skips the ft/trigger/name prompts since
-- they're already known.
local function clone_friendly_item(item)
  open_body_editor(item.ft, item.body, function(lines)
    save_snippet(item.ft, item.trigger, item.name, lines, true)
  end)
end

-- Editing a smart snippet from the list only opens the header/line_template/footer/
-- empty_message editor — extraction settings (node_types, field, pattern, ...) stay
-- as-is; hand-edit the JSON (:SnippetEdit-equivalent for smart ones is just :e the
-- file) if those need to change. Mirrors the same scoping choice as plain snippets,
-- where renaming trigger/name similarly isn't supported from the picker.
local function edit_smart_snippet_item(item)
  local sections = {
    header = item.cfg.header or {},
    line_template = item.cfg.line_template,
    footer = item.cfg.footer or {},
    empty_message = item.cfg.empty_message,
  }
  open_sections_editor(item.ft, sections, function(new_sections)
    save_smart_snippet(item.ft, item.trigger, item.name, item.cfg, new_sections, item.is_override)
  end)
end

-- Delete our entry for `item`. If it was an override, this also restores whatever
-- it was overriding — the two are inseparable, since they share a trigger.
local function delete_snippet_item(item)
  invalidate(item.ft, item.trigger, true)
  remove_json_entry(item.ft, item.name)
  if item.is_override then
    unexclude_trigger(item.ft, item.trigger)
    vim.notify(('Removed "%s" and restored the original %s for %s'):format(item.name, item.trigger, item.ft), vim.log.levels.INFO)
  else
    vim.notify(('Removed "%s" (%s) for %s'):format(item.name, item.trigger, item.ft), vim.log.levels.INFO)
  end
end

local function delete_smart_snippet_item(item)
  invalidate(item.ft, item.trigger, true)
  remove_smart_json_entry(item.ft, item.name)
  if item.is_override then
    unexclude_trigger(item.ft, item.trigger)
    vim.notify(('Removed "%s" and restored the original %s for %s'):format(item.name, item.trigger, item.ft), vim.log.levels.INFO)
  else
    vim.notify(('Removed "%s" (%s) for %s'):format(item.name, item.trigger, item.ft), vim.log.levels.INFO)
  end
end

local SOURCE_TAGS = {
  ['personal-override'] = { '  [override]', 'DiagnosticWarn' },
  ['smart-override'] = { '  [smart override]', 'DiagnosticWarn' },
  smart = { '  [smart]', 'DiagnosticHint' },
  friendly = { '  [friendly-snippets]', 'DiagnosticHint' },
}

local function snippet_picker_format(item)
  local ret = {
    { ('[%s] '):format(item.ft), 'SnacksPickerLabel' },
    { item.trigger, 'SnacksPickerSpecial' },
    { '  ' .. item.name, 'SnacksPickerComment' },
  }
  local tag = SOURCE_TAGS[item.source]
  if tag then
    table.insert(ret, tag)
  end
  return ret
end

-- Typing in the picker's prompt fuzzy-matches against `text` (ft + trigger + name
-- packed together in collect_*_items above), so filtering by filetype/trigger/name
-- is just: type any of those — e.g. "python" narrows to python snippets, "ifmain"
-- to that trigger across filetypes, a name fragment the same way. No separate
-- filter UI needed for that; combine terms (e.g. "python if") to narrow further.
local function snippet_list()
  -- Loading friendly-snippets' manifest needs nvim-cmp's dependency chain on the
  -- runtimepath first (see collect_friendly_items / find_friendly_snippets_manifest).
  pcall(function()
    require('lazy').load { plugins = { 'nvim-cmp' } }
  end)

  local items = collect_personal_items()
  vim.list_extend(items, collect_smart_items())
  vim.list_extend(items, collect_friendly_items())

  Snacks.picker.pick {
    source = 'personal_snippets',
    title = 'Snippets (<CR> edit/clone, <C-x> delete/restore, <C-n> new)',
    items = items,
    format = snippet_picker_format,
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      if item.source == 'friendly' then
        clone_friendly_item(item)
      elseif item.source == 'smart' or item.source == 'smart-override' then
        edit_smart_snippet_item(item)
      else
        edit_snippet_item(item)
      end
    end,
    win = {
      input = {
        keys = {
          ['<C-x>'] = { 'delete_snippet', mode = { 'n', 'i' } },
          ['<C-n>'] = { 'new_snippet', mode = { 'n', 'i' } },
        },
      },
    },
    actions = {
      delete_snippet = function(picker, item)
        if not item then
          return
        end
        if item.source == 'friendly' then
          vim.notify('Not a personal snippet — press <CR> to create an override first', vim.log.levels.WARN)
          return
        end
        picker:close()
        if item.source == 'smart' or item.source == 'smart-override' then
          delete_smart_snippet_item(item)
        else
          delete_snippet_item(item)
        end
      end,
      new_snippet = function(picker)
        picker:close()
        snippet_new()
      end,
    },
  }
end

vim.api.nvim_create_user_command('SnippetList', snippet_list, { desc = 'Browse/edit/delete personal + friendly-snippets' })

-- Helps fill in a treesitter smart-snippet's node_types/field/item_field (see
-- lua/snippet_engine.lua): put the cursor on real code and run this. Shows the
-- ancestor chain (pick a node_type from there) and that ancestor's s-expression,
-- which labels every field by name (e.g. "parameters:", "pattern:") — exactly the
-- strings `field`/`item_field` want. Pure treesitter, no LuaSnip dependency, so it
-- lives here (loaded at startup) rather than in the lazy-loaded snippet_engine.
vim.api.nvim_create_user_command('SnippetInspectNode', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = bufnr })
  if not ok or not node then
    vim.notify('No treesitter node under cursor', vim.log.levels.WARN)
    return
  end

  local lines = { 'Ancestors (nearest first — pick one as node_types):' }
  local cur = node
  local depth = 0
  local outer_depth = 0
  local outer = node
  while cur and depth < 6 do
    table.insert(lines, ('  %d: %s'):format(depth, cur:type()))
    outer, outer_depth = cur, depth
    cur = cur:parent()
    depth = depth + 1
  end

  table.insert(lines, '')
  table.insert(lines, ('S-expression from ancestor %d (%s) down — field names are labeled (e.g. "parameters:"):'):format(outer_depth, outer:type()))
  table.insert(lines, outer:sexpr())

  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'Treesitter node inspector' })
end, { desc = 'Show treesitter node types + fields under cursor (for smart-snippet setup)' })
