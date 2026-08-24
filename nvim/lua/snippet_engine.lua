-- Engine for "smart" snippets: ones that look at the buffer (via treesitter or a
-- vim-regex search) and generate one templated line per thing found, instead of a
-- fixed body. Definitions live in lua/snippets/smart/<filetype>.json and are built
-- into real LuaSnip snippets (using a dynamic node) at startup.
--
-- Two extraction kinds:
--
-- "treesitter" — find the nearest node (of any of `node_types`) above/below the
-- cursor, read its `field` (e.g. "parameters"), and for each child read `item_field`
-- (e.g. "pattern") — or the child itself if item_field doesn't apply — as that
-- item's `name`. Use :SnippetInspectNode with your cursor on real code to find the
-- right node_types/field/item_field values for your language.
--
-- "regex" — search up to `max_lines` lines above/below the cursor with a vim-regex
-- `pattern` (supports \(...\) capture groups). `multi=true` collects every matching
-- line in range, one item per match; `multi=false` (default) stops at the first
-- (nearest) match. Each item exposes `match` (whole match) and `cap1`/`cap2`/...
-- (capture groups).
--
-- Definition shape (one entry per JSON file, keyed by name):
-- {
--   "trigger": "/**",
--   "kind": "treesitter" | "regex",
--   "direction": "below" | "above",
--   -- treesitter:
--   "node_types": ["function_declaration", "arrow_function"],
--   "field": "parameters",
--   "item_field": "pattern",
--   -- regex:
--   "pattern": "vim regex, \\( \\) groups",
--   "max_lines": 20,
--   "multi": true,
--   -- shared:
--   "header": ["/**"],                          -- static lines before the generated ones
--   "line_template": " * @param {${1:type}} {{name}}",  -- one ${1:default} tab stop + any
--                                                          -- number of {{field}} substitutions
--   "footer": [" */"],
--   "empty_message": "No function found below — type manually"
-- }
local util = require 'snippet_util'
local ls = require 'luasnip'
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node

local M = {}

local FUNCTION_LIKE_DEFAULT = {
  function_declaration = true,
  function_signature = true,
  method_definition = true,
  arrow_function = true,
  function_expression = true,
  generator_function_declaration = true,
}
M.FUNCTION_LIKE_DEFAULT = FUNCTION_LIKE_DEFAULT

--- treesitter extraction ----------------------------------------------------

local function find_target_node(bufnr, cursor_row, direction, node_types)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return nil
  end
  local type_set = {}
  for _, tname in ipairs(node_types) do
    type_set[tname] = true
  end

  local root = parser:parse()[1]:root()
  local best
  local function walk(node)
    if type_set[node:type()] then
      local srow = node:start()
      if direction == 'above' then
        if srow <= cursor_row and (not best or srow > best:start()) then
          best = node
        end
      else -- below
        if srow >= cursor_row and (not best or srow < best:start()) then
          best = node
        end
      end
    end
    for child in node:iter_children() do
      walk(child)
    end
  end
  walk(root)
  return best
end

local function extract_treesitter(bufnr, cursor_row, cfg)
  local target = find_target_node(bufnr, cursor_row, cfg.direction, cfg.node_types)
  if not target then
    return {}
  end
  local field_node = cfg.field and target:field(cfg.field)[1]
  if not field_node then
    return {}
  end

  local items = {}
  for child in field_node:iter_children() do
    if child:named() then
      local item_node = (cfg.item_field and cfg.item_field ~= '') and child:field(cfg.item_field)[1] or nil
      item_node = item_node or child
      table.insert(items, { name = vim.treesitter.get_node_text(item_node, bufnr) })
    end
  end
  return items
end

--- regex extraction ---------------------------------------------------------

local function extract_regex(bufnr, cursor_row, cfg)
  local max_lines = cfg.max_lines or 20
  local lines
  if cfg.direction == 'above' then
    local from = math.max(0, cursor_row - max_lines)
    lines = vim.api.nvim_buf_get_lines(bufnr, from, cursor_row, false)
    -- search nearest-first: reverse so line closest to cursor is checked first
    local reversed = {}
    for idx = #lines, 1, -1 do
      table.insert(reversed, lines[idx])
    end
    lines = reversed
  else
    lines = vim.api.nvim_buf_get_lines(bufnr, cursor_row, cursor_row + max_lines, false)
  end

  local items = {}
  for _, line in ipairs(lines) do
    local caps = vim.fn.matchlist(line, cfg.pattern)
    if #caps > 0 then
      local item = { match = caps[1], name = caps[2] or caps[1] }
      for gi = 2, 9 do
        item['cap' .. (gi - 1)] = caps[gi] ~= '' and caps[gi] or nil
      end
      table.insert(items, item)
      if not cfg.multi then
        break
      end
    end
  end
  return items
end

--- line template: any number of {{field}} substitutions, plus at most one
--- ${1:default} tab stop --------------------------------------------------

local function render_template(template, item)
  local text = template:gsub('{{(%w+)}}', function(key)
    return item[key] or ''
  end)

  local prefix, default, suffix = text:match '^(.-)%${1:([^}]*)}(.*)$'
  if prefix then
    return prefix, default, suffix
  end
  -- no tab stop in this template: it's all literal text, no insert node needed
  return text, nil, nil
end

--- building the dynamic node ------------------------------------------------

local function build_snippet_nodes(cfg)
  return function()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed
    local items
    if cfg.kind == 'treesitter' then
      items = extract_treesitter(bufnr, cursor_row, cfg)
    else
      items = extract_regex(bufnr, cursor_row, cfg)
    end

    local header = cfg.header or {}
    local nodes = {}
    for hidx, line in ipairs(header) do
      table.insert(nodes, hidx == 1 and t(line) or t { '', line })
    end

    if #items == 0 then
      local msg = cfg.empty_message or 'Nothing found'
      if #header == 0 then
        table.insert(nodes, i(1, msg))
      else
        table.insert(nodes, t { '', '' })
        table.insert(nodes, i(1, msg))
      end
    else
      local stop = 0
      for idx, item in ipairs(items) do
        local prefix, default, suffix = render_template(cfg.line_template, item)
        if idx == 1 and #header == 0 then
          table.insert(nodes, t(prefix))
        else
          table.insert(nodes, t { '', prefix })
        end
        if default ~= nil then
          stop = stop + 1
          table.insert(nodes, i(stop, default))
          if suffix and suffix ~= '' then
            table.insert(nodes, t(suffix))
          end
        end
      end
    end

    for _, line in ipairs(cfg.footer or {}) do
      table.insert(nodes, t { '', line })
    end

    return sn(nil, nodes)
  end
end

function M.build_snippet(cfg)
  local snip = ls.s(cfg.trigger, {
    d(1, build_snippet_nodes(cfg), {}),
  })
  snip.smart_snippet = true
  return snip
end

--- loading -------------------------------------------------------------------

local function list_smart_fts()
  local fts = {}
  for _, path in ipairs(vim.fn.glob(util.smart_dir .. '/*.json', true, true)) do
    table.insert(fts, vim.fn.fnamemodify(path, ':t:r'))
  end
  return fts
end
M.list_smart_fts = list_smart_fts

function M.load_ft(ft)
  local path = util.smart_dir .. '/' .. ft .. '.json'
  local entries = util.read_json(path, {})
  local snippets = {}
  for name, cfg in pairs(entries) do
    cfg = vim.tbl_extend('force', { name = name }, cfg)
    local ok, snip = pcall(M.build_snippet, cfg)
    if ok then
      table.insert(snippets, snip)
    else
      vim.notify(('Smart snippet "%s" (%s) failed to build: %s'):format(name, ft, snip), vim.log.levels.WARN)
    end
  end
  if #snippets > 0 then
    ls.add_snippets(ft, snippets)
  end
end

function M.load_all()
  util.ensure_exclusion_hook()
  for _, ft in ipairs(list_smart_fts()) do
    M.load_ft(ft)
  end
end

return M
