local M = {}

local function len(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

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

local error = function(message)
    vim.notify(message, vim.log.levels.ERROR)
end

M.cached = {}

local function update_cached_diagnostic()
    local ok, diagnostics = pcall(vim.diagnostic.get, 0)

    if not ok then
        error('Failed to get diagnostic: ' .. diagnostics)
        return
    end

    if type(diagnostics) ~= "table" then
        error('Diagnostic is not a table ' .. diagnostics)
        return
    end

    ok, diagnostics = pcall(function()
        table.sort(diagnostics, function(a, b) return a.severity < b.severity end)
        return diagnostics
    end)

    if not ok then
        error('Failed to sort diagnostics ' .. diagnostics)
        return
    end


    M.cached = diagnostics
end



function M.init(config)
    vim.diagnostic.config({ virtual_text = false })
    M.config = config

    ns = vim.api.nvim_create_namespace("DiagnosticsHighlight")

    local signs = (function()
      local signs = {}
      local type_diagnostic = vim.diagnostic.severity
      for _, severity in ipairs(type_diagnostic) do
        local status, sign = pcall(function()
          return vim.trim(
            vim.fn.sign_getdefined(
              "DiagnosticSign" .. severity:lower():gsub("^%l", string.upper)
            )[1].text
          )
        end)
        if not status then
          sign = severity:sub(1, 1)
        end
        signs[severity] = sign
      end
      return signs
    end)()

    local function render_diagnostics()
        if type(M.config.enable) == "function" then
            print("function")
            if not M.config.enable() then
                return
            end
        elseif not M.config.enable then
            return
        end

        if vim.diagnostic.is_disabled ~= nil and vim.diagnostic.is_disabled(0) then
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
        local win_width = vim.api.nvim_win_get_width(0) - vim.fn.getwininfo()[1].textoff - config.padding_right
        -- Render current_pos_diags
        for _, diag in ipairs(current_pos_diags) do
            local diag_message = config.format(diag)

            local hl_group = severity[diag.severity]
            local sign = config.show_sign and signs[vim.diagnostic.severity[diag.severity]] .. " " or ""
            local message_lines = wrap_text(sign .. diag_message, config.max_width)

            local max_width = 0
            if config.text_align == 'left' then
                for _, message in ipairs(message_lines) do
                    max_width = math.max(max_width, #message)
                end
            end

            local is_right = config.text_align == 'right'
            local is_top = config.placement == 'top'

            local lines_added = 0
            for _, message in ipairs(message_lines) do
                if lines_added >= config.max_height then
                    break
                end
                lines_added = lines_added + 1
                if config.placement == 'inline' then
                    local spacing = string.rep(" ", config.inline_padding_left)
                    vim.api.nvim_buf_set_extmark(bufnr, ns, diag.lnum, diag.col, {
                        virt_text_pos = 'eol',
                        virt_text = { { spacing .. message, hl_group } },
                        virt_text_hide = true,
                        strict = false
                    })
                elseif is_top and is_right and config.padding_right == 0 then
                    -- fixes the issue of neotree and nvim-tree weird not on screen when opened
                    vim.api.nvim_buf_set_extmark(bufnr, ns, win_info.topline + line_offset + config.padding_top, 0, {
                        virt_text_pos = 'right_align',
                        virt_text = { { message, hl_group } },
                        virt_text_hide = true,
                        strict = false,
                    })
                else
                    local align = config.text_align == 'left' and max_width or #message
                    vim.api.nvim_buf_set_extmark(bufnr, ns, win_info.topline + line_offset + config.padding_top, 0, {
                        virt_text_win_col = win_width - align,
                        virt_text = { { message, hl_group } },
                        virt_text_hide = true,
                        strict = false
                    })
                end

                line_offset = line_offset + 1
            end

            -- Add a gap only after each diagnostic, not after each line
            if config.gap_size > 0 then
                line_offset = line_offset + config.gap_size - 1
            end
        end
    end
    local function toggle()
        M.config.enabled = not M.config.enabled
        vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    end

    group = vim.api.nvim_create_augroup('RenderDiagnostics', { clear = true })
    vim.api.nvim_create_autocmd(config.render_event, {
        callback = render_diagnostics,
        pattern = "*",
        group = group
    })

    if len(config.toggle_event) > 0 then
        vim.api.nvim_create_autocmd(config.toggle_event, {
            callback = toggle,
            pattern = "*",
            group = group
        })
    end
    vim.api.nvim_create_autocmd(config.update_event, {
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
