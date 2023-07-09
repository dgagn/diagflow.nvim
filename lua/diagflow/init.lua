local M = {}

local diagflowlazy = require('diagflow.lazy')

M.config = {
    max_width = 60,
    severity_colors = {
        error = "DiagnosticFloatingError",
        warn = "DiagnosticFloatingWarning",
        info = "DiagnosticFloatingInfo",
        hint = "DiagnosticFloatingHint",
    },
    gap_size = 1,
    scope = 'cursor', -- 'cursor', 'line'
    top_padding = 0,
    enable = true,
}

function M.setup(user_config)
    M.config = vim.tbl_deep_extend('force', M.config, user_config or {})
    diagflowlazy.init(M.config)
end

function M.toggle()
    M.config.enable = not M.config.enable
    if M.config.enable then
        diagflowlazy.init(M.config)
    else
        diagflowlazy.clear()
    end
end

return M

