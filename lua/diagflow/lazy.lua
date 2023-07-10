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

local group = nil
local ns = nil

local function shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

M.cached = {}

local function update_cached_diagnostic()
    M.cached = vim.diagnostic.get(0)
    table.sort(M.cached, function(a, b) return a.severity < b.severity end)
end

function M.init(config)
    vim.diagnostic.config({ virtual_text = false })

    ns = vim.api.nvim_create_namespace("DiagnosticsHighlight")

    local function render_diagnostics()
        if not config.enable then
            return
        end

        local bufnr = 0 -- current buffer

        -- Clear existing extmarks
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

        local win_info = vim.fn.getwininfo(vim.fn.win_getid())[1]

        local diags = M.cached

        -- Get the current position
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        local line = cursor_pos[1] - 1 -- Subtract 1 to convert to 0-based indexing
        local col = cursor_pos[2]

        local current_pos_diags = {}
        for _, diag in ipairs(diags) do
            if config.scope == 'line' and diag.lnum == line or
                config.scope == 'cursor' and diag.lnum == line and diag.col <= col and (diag.end_col or diag.col) >= col then
                table.insert(current_pos_diags, diag)
            end
        end

        local severity = {
            [vim.diagnostic.severity.ERROR] = config.severity_colors.error,
            [vim.diagnostic.severity.WARN] = config.severity_colors.warn,
            [vim.diagnostic.severity.INFO] = config.severity_colors.info,
            [vim.diagnostic.severity.HINT] = config.severity_colors.hint,
        }

        local line_offset = 0
        -- Render current_pos_diags
        for _, diag in ipairs(current_pos_diags) do
            local hl_group = severity[diag.severity]
            local message_lines = wrap_text(diag.message, config.max_width)

            for _, message in ipairs(message_lines) do
                vim.api.nvim_buf_set_extmark(bufnr, ns, win_info.topline + line_offset + config.padding_top, 0, {
                    virt_text = { { message, hl_group } },
                    virt_text_pos = "right_align",
                    virt_text_hide = true,
                    strict = false
                })
                line_offset = line_offset + 1
            end

            -- Add a gap only after each diagnostic, not after each line
            if config.gap_size > 0 then
                line_offset = line_offset + config.gap_size - 1
            end
        end
    end

    group = vim.api.nvim_create_augroup('RenderDiagnostics', { clear = true })
    vim.api.nvim_create_autocmd('CursorMoved', {
        callback = render_diagnostics,
        pattern = "*",
        group = group
    })
    vim.api.nvim_create_autocmd('DiagnosticChanged', {
        callback = update_cached_diagnostic,
        pattern = "*",
        group = group
    })

    update_cached_diagnostic()
end

function M.clear()
    pcall(function() vim.api.nvim_del_augroup_by_name('RenderDiagnostics') end)
    pcall(function() vim.api.nvim_buf_clear_namespace(0, ns, 0, -1) end)
end

return M
