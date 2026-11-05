-- nvim-dap: Debug Adapter Protocol client — breakpoints, step/continue,
-- variable inspection UI. Go (delve) and Python (debugpy) are configured.
-- https://github.com/mfussenegger/nvim-dap
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
    'leoluz/nvim-dap-go',
    { 'theHamsta/nvim-dap-virtual-text', opts = {} },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {
        'delve',
        'debugpy',
      },
    }

    -- Keymaps (F1-F3 step controls, F5 continue, F6 breakpoint, F7 UI, F8 conditional breakpoint)
    vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<F4>', require('dap.ui.widgets').hover, { desc = 'Debug: Hover Value' })
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F6>', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })
    vim.keymap.set('n', '<F8>', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Debug: Set Conditional Breakpoint' })

    -- DAP UI
    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = { enabled = false },
      layouts = {
        {
          elements = {
            { id = 'scopes', size = 0.75 },
            { id = 'watches', size = 0.25 },
          },
          size = 60,
          position = 'left',
        },
        {
          elements = { 'repl' },
          size = 10,
          position = 'bottom',
        },
      },
    }

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Go
    require('dap-go').setup {
      delve = {
        detached = vim.fn.has 'win32' == 0,
      },
    }

    -- debugpy itself is NOT configured here (no require('dap-python').setup()):
    -- mason-nvim-dap's default handler (triggered automatically above, since
    -- 'debugpy' is mason-installed) already points dap.adapters.python at
    -- mason's own standalone debugpy-adapter binary -- an editor-level
    -- install, independent of any project. dap-python's setup() would
    -- overwrite that with a version that runs debugpy via the *project's*
    -- interpreter instead, requiring debugpy to be pip/uv-installed into
    -- every project's venv -- exactly what we don't want.
    --
    -- Below, pythonPath is a different, legitimate kind of project-dependency:
    -- it's just "which interpreter should run my code", not "where does the
    -- debugger engine live". Resolves the project's venv, falling back to
    -- whatever python3 is on PATH.
    local function get_python_path()
      local venv = os.getenv 'VIRTUAL_ENV'
      if venv then return venv .. '/bin/python' end
      local local_venv = vim.fn.getcwd() .. '/.venv/bin/python'
      if vim.fn.executable(local_venv) == 1 then return local_venv end
      local python3 = vim.fn.exepath 'python3'
      return python3 ~= '' and python3 or '/usr/bin/python3'
    end

    dap.configurations.python = {
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        justMyCode = false,
        pythonPath = get_python_path,
      },
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file with arguments',
        program = '${file}',
        args = function()
          local args = vim.fn.input 'Arguments: '
          return vim.split(args, ' ', { trimempty = true })
        end,
        pythonPath = get_python_path,
      },
      {
        type = 'python',
        request = 'launch',
        name = 'Launch module',
        module = function() return vim.fn.input 'Module name: ' end,
        pythonPath = get_python_path,
      },
    }
  end,
}
