local M = {}

local function wrap_text(text, max_width)
    local lines = {}
    local line = ""

    for word in text:gmatch("%S+") do
        if #line + #word + 1 > max_width then
            table.insert(lines, line)
            line = word
        else
            line = line ~= "" and line .. " " .. word or word
        end
    end

    table.insert(lines, line)

    return lines
end

function M.init(config)
    local maxwidth = config.maxwidth
    local severity_to_color = config.severity_colors

    vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
        vim.lsp.diagnostic.on_publish_diagnostics, {
            virtual_text = false,
            signs = true,
            underline = true,
            update_in_insert = true,
        }
    )

    local ns = vim.api.nvim_create_namespace("DiagnosticsHighlight")

    local function render_diagnostics()
        local bufnr = 0 -- current buffer

        -- Clear existing extmarks
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

        local win_info = vim.fn.getwininfo(vim.fn.win_getid())[1]

        local diags = vim.diagnostic.get(bufnr)

        -- Sort diagnostics by severity
        table.sort(diags, function(a, b) return a.severity < b.severity end)

        -- Get the current position
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        local line = cursor_pos[1] - 1 -- Subtract 1 to convert to 0-based indexing
        local col = cursor_pos[2]

        local current_pos_diags = {}
        for _, diag in ipairs(diags) do
            if diag.lnum == line and diag.col <= col and (diag.end_col or diag.col) >= col then
                table.insert(current_pos_diags, diag)
            end
        end

        -- Render current_pos_diags
        for _, diag in ipairs(current_pos_diags) do
            local hl_group = severity_to_color[diag.severity]
            local message_lines = wrap_text(diag.message, maxwidth)

            for i, message in ipairs(message_lines) do
                vim.api.nvim_buf_set_extmark(bufnr, ns, win_info.topline + i - 1, 0, {
                    virt_text = { { message, hl_group } },
                    virt_text_pos = "right_align",
                    virt_text_hide = true,
                    strict = false
                })
            end
        end
    end

    local group = vim.api.nvim_create_augroup('RenderDiagnostics', { clear = true })
    vim.api.nvim_create_autocmd('CursorMoved', {
        callback = render_diagnostics,
        pattern = "*",
        group = group
    })
end

return M
