local M = {}

-- Check if fzf-lua is available
local has_fzf, fzf = pcall(require, 'fzf-lua')
local has_plenary, plenary = pcall(require, 'plenary')

-- List of file extensions to skip
local skip_extensions = {
    'png', 'jpg', 'jpeg', 'gif', 'bmp', 'pdf',
    'zip', 'tar', 'gz', 'bin', 'exe', 'o'
}

-- Common text file extensions as fallback
local text_extensions = {
    'txt', 'md', 'lua', 'py', 'js', 'ts', 'json',
    'yaml', 'yml', 'sh', 'c', 'cpp', 'h', 'java', 'go'
}

-- Function to check if file is text
local function is_text_file(filename)
    -- Check if file has a skippable extension
    for _, ext in ipairs(skip_extensions) do
        if filename:match('%.' .. ext .. '$') then
            vim.notify("Skipping non-text file: " .. filename, vim.log.levels.DEBUG)
            return false
        end
    end
    -- Check if file has a known text extension
    for _, ext in ipairs(text_extensions) do
        if filename:match('%.' .. ext .. '$') then
            return true
        end
    end
    -- Use plenary to check if file is readable text
    if has_plenary then
        local stat = plenary.path:new(filename):_stat()
        if stat and stat.type == 'file' then
            local cmd = string.format("file %q", filename)
            local output = vim.fn.system(cmd)
            local is_text = output:match('text') ~= nil
            if not is_text then
                vim.notify("File not identified as text by `file` command: " .. filename .. " (" .. output .. ")", vim.log.levels.DEBUG)
            end
            return is_text
        end
    end
    vim.notify("Unable to check file type (plenary failed or file not found): " .. filename, vim.log.levels.DEBUG)
    return false
end

-- Function to process a single file
local function process_file(file, output)
    local Path = require('plenary.path')
    local relative_path = file:sub(#vim.fn.getcwd() + 2) -- Remove cwd prefix
    if is_text_file(file) then
        table.insert(output, string.format("=== Content from: %s ===", relative_path))
        local content = Path:new(file):read()
        table.insert(output, content)
        table.insert(output, "\n")
        vim.notify("Processed file: " .. relative_path, vim.log.levels.DEBUG)
    end
end

-- Function to copy to clipboard
local function copy_to_clipboard(content)
    local clipboard_cmd = nil
    if vim.fn.executable('xclip') == 1 then
        clipboard_cmd = 'xclip -selection clipboard'
    elseif vim.fn.executable('wl-copy') == 1 then
        clipboard_cmd = 'wl-copy'
    elseif vim.fn.executable('pbcopy') == 1 then
        clipboard_cmd = 'pbcopy'
    end

    if clipboard_cmd then
        vim.fn.system(clipboard_cmd, table.concat(content, "\n"))
        vim.notify(string.format("Done! Text copied to clipboard. Total lines: %d", #content))
    else
        vim.notify("Error: No clipboard tool found (install xclip, wl-copy, or pbcopy)", vim.log.levels.ERROR)
        -- Display in new buffer as fallback
        vim.api.nvim_command('new')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
    end
end

-- Main function to select files and process
function M.select_and_copy()
    if not has_fzf then
        vim.notify("Error: fzf-lua is not installed. Please install it first.", vim.log.levels.ERROR)
        return
    end
    if not has_plenary then
        vim.notify("Error: plenary.nvim is not installed. Please install it first.", vim.log.levels.ERROR)
        return
    end

    fzf.files({
        prompt = "Select files to process (TAB to toggle, Enter to confirm)> ",
        cwd = vim.fn.getcwd(),
        file_ignore_patterns = { "%.git/" },
        fzf_opts = {
            ['--multi'] = '',
            ['--preview'] = 'bat --style=numbers --color=always {} || cat {}',
            ['--preview-window'] = 'up:40%'
        },
        actions = {
            ['default'] = function(selected)
                if not selected or #selected == 0 then
                    vim.notify("No files selected. Exiting.", vim.log.levels.INFO)
                    return
                end

                local output = {}
                vim.notify("Selected files:\n" .. table.concat(selected, "\n"), vim.log.levels.INFO)

                for _, file in ipairs(selected) do
                    process_file(file, output)
                end

                if #output > 0 then
                    copy_to_clipboard(output)
                else
                    vim.notify("No text content found to copy.", vim.log.levels.WARN)
                end
            end
        }
    })
end

-- Setup function to initialize the plugin
function M.setup()
    vim.api.nvim_create_user_command('Ctx', M.select_and_copy, { desc = "Select files and copy text content to clipboard" })
    vim.notify("Ctx: Command registered", vim.log.levels.INFO)
end

return M
