local M = {}

M.config = {
    max_width = 60,
    severity_colors = {
        error = "DiagnosticDefaultErrorMsg",
        warn = "DiagnosticDefaultWarningMsg",
        info = "DiagnosticDefaultInfoMsg",
        hint = "DiagnosticDefaultHintMsg",
    }
}

function M.setup(user_config)
    M.config = vim.tbl_deep_extend('force', M.config, user_config or {})
    require('diagflow.lazy').init(M.config)
end

return M
