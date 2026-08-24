-- Shared plumbing for lua/snippet_editor.lua (plain JSON snippets) and
-- lua/snippet_engine.lua (treesitter/regex-driven "smart" snippets): JSON-file I/O,
-- and the override/exclude mechanism that lets either kind of personal snippet
-- suppress a friendly-snippets original and be reversible later.
local M = {}

M.vscode_dir = vim.fn.stdpath 'config' .. '/lua/snippets/vscode'
M.smart_dir = vim.fn.stdpath 'config' .. '/lua/snippets/smart'
-- One shared exclusion record for both kinds — "is trigger X excluded for filetype Y"
-- doesn't care which kind of personal snippet is doing the excluding.
M.excluded_file = M.vscode_dir .. '/_excluded.json'

function M.read_json(path, default)
  if vim.fn.filereadable(path) == 0 then
    return default
  end
  local ok, content = pcall(vim.fn.readfile, path)
  if not ok or #content == 0 then
    return default
  end
  local decode_ok, decoded = pcall(vim.json.decode, table.concat(content, '\n'))
  if not decode_ok then
    return default
  end
  return decoded
end

function M.write_file(dir, path, text)
  vim.fn.mkdir(dir, 'p')
  vim.fn.writefile(vim.split(text, '\n'), path)
end

local function serialize_excluded(map)
  local fts = vim.tbl_keys(map)
  table.sort(fts)
  if #fts == 0 then
    return '{}\n'
  end
  local parts = {}
  for _, ft in ipairs(fts) do
    local triggers = vim.deepcopy(map[ft])
    table.sort(triggers)
    local encoded = {}
    for _, trig in ipairs(triggers) do
      table.insert(encoded, vim.json.encode(trig))
    end
    table.insert(parts, '  ' .. vim.json.encode(ft) .. ': [' .. table.concat(encoded, ', ') .. ']')
  end
  return '{\n' .. table.concat(parts, ',\n') .. '\n}\n'
end

function M.add_excluded(ft, trigger)
  local excluded = M.read_json(M.excluded_file, {})
  excluded[ft] = excluded[ft] or {}
  if not vim.tbl_contains(excluded[ft], trigger) then
    table.insert(excluded[ft], trigger)
  end
  M.write_file(M.vscode_dir, M.excluded_file, serialize_excluded(excluded))
end

function M.remove_excluded(ft, trigger)
  local excluded = M.read_json(M.excluded_file, {})
  if not excluded[ft] then
    return
  end
  excluded[ft] = vim.tbl_filter(function(t)
    return t ~= trigger
  end, excluded[ft])
  M.write_file(M.vscode_dir, M.excluded_file, serialize_excluded(excluded))
end

-- True for any snippet that came from one of *our* personal sources: tagged live
-- (personal_override / smart_snippet, set before registering — needed because
-- add_snippets() fires LuasnipSnippetsAdded synchronously, so a freshly-added one
-- would otherwise immediately "exclude" itself in the same call stack), or reloaded
-- from disk under our directories after a restart (loaders_store_source records the
-- file each snippet came from).
function M.is_ours(snip)
  if snip.personal_override or snip.smart_snippet then
    return true
  end
  local file = snip._source and snip._source.file
  if not file then
    return false
  end
  return vim.startswith(file, M.vscode_dir) or vim.startswith(file, M.smart_dir)
end

-- Note: luasnip.get_snippets(ft) returns a fresh COPY of the internal list on every
-- call — mutating that copy does nothing to the real collection. The actual removal
-- API is snip:invalidate(). We never call the companion clean_invalidated() — it
-- purges invalidated snippets from storage once enough accumulate, which would break
-- "restore" by discarding the object we'd need to reactivate. The list stays tiny.
--
-- `only_ours`: if true, invalidate only snippets from us; if false (default),
-- invalidate everything EXCEPT ours (used to override a friendly-snippets original).
function M.invalidate(ft, trigger, only_ours)
  local ok, luasnip = pcall(require, 'luasnip')
  if not ok then
    return
  end
  for _, snip in ipairs(luasnip.get_snippets(ft) or {}) do
    local ours = M.is_ours(snip)
    local target = only_ours and ours or (not only_ours and not ours)
    if snip.trigger == trigger and not snip.invalidated and target then
      snip._saved_matches = snip._saved_matches or snip.matches
      snip:invalidate()
    end
  end
end

-- Reactivate a previously-invalidated (non-personal) snippet for ft+trigger.
function M.reactivate_original(ft, trigger)
  local ok, luasnip = pcall(require, 'luasnip')
  if not ok then
    return
  end
  for _, snip in ipairs(luasnip.get_snippets(ft) or {}) do
    if snip.trigger == trigger and snip.invalidated and snip._saved_matches and not M.is_ours(snip) then
      snip.matches = snip._saved_matches
      snip.hidden = false
      snip.invalidated = false
    end
  end
end

function M.exclude_trigger(ft, trigger)
  M.invalidate(ft, trigger, false)
  M.add_excluded(ft, trigger)
end

function M.unexclude_trigger(ft, trigger)
  M.reactivate_original(ft, trigger)
  M.remove_excluded(ft, trigger)
end

-- Reapply recorded exclusions to whatever snippets are currently loaded for `ft`.
-- Hook this to LuaSnip's "snippets were (re)loaded for this ft" event so it runs at
-- the right time regardless of when/how that ft's snippets got loaded.
function M.apply_exclusions(ft)
  if not ft or ft == '' then
    return
  end
  local excluded = M.read_json(M.excluded_file, {})
  local triggers = excluded[ft]
  if not triggers or #triggers == 0 then
    return
  end
  for _, trigger in ipairs(triggers) do
    M.invalidate(ft, trigger, false)
  end
end

local hooked = false
function M.ensure_exclusion_hook()
  if hooked then
    return
  end
  hooked = true
  vim.api.nvim_create_autocmd('User', {
    pattern = 'LuasnipSnippetsAdded',
    callback = function()
      local ok, luasnip = pcall(require, 'luasnip')
      if ok then
        M.apply_exclusions(luasnip.session.latest_load_ft)
      end
    end,
  })
end

return M
