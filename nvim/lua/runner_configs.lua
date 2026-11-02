Runner = require 'helpers.file_runner'

Runner.config_ft('python', 'uv run {file}')
Runner.config_ft('javascript', 'node {file}')
Runner.config_ft('typescript', 'npx tsx {file}')
Runner.config_ft('sh', 'bash {file}')
Runner.config_ft('go', 'go run {file}')
Runner.config_ft('lua', 'lua {file}')
