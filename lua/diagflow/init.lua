local M = {}

local config = {
    max_width = 60,
    severity_colors = {
        [vim.diagnostic.severity.ERROR] = "ErrorMsg",
        [vim.diagnostic.severity.WARN] = "WarningMsg",
        [vim.diagnostic.severity.INFO] = "InfoMsg",
        [vim.diagnostic.severity.HINT] = "HintMsg",
    }
}

function M.setup(user_config)
    config = vim.tbl_extend('force', config, user_config or {})
    require('diagflow.lazy').init(M.config)
end

return M
