local M = {}

-- Plugin version for debugging
local PLUGIN_VERSION = "0.2.0"

-- Check if fzf-lua is available
local has_fzf, fzf = pcall(require, 'fzf-lua')
local has_plenary, plenary = pcall(require, 'plenary')

-- Function to clean file path (remove special characters like  and ./)
local function clean_path(path)
    -- Remove non-ASCII characters, special characters, and trim whitespace
    local cleaned = path:gsub("[^%w%/%-%.%_]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    -- Remove './' prefix if present
    if cleaned:sub(1, 2) == "./" then
        cleaned = cleaned:sub(3)
    end
    return cleaned
end

-- Function to process a single file
local function process_file(file, output)
    local Path = require('plenary.path')
    -- Clean the file path
    local cleaned_path = clean_path(file)
    
    -- Convert to absolute path
    local absolute_path = vim.fn.fnamemodify(cleaned_path, ':p')
    
    -- Compute relative path for output
    local relative_path = absolute_path:sub(#vim.fn.getcwd() + 2)

    local path = Path:new(absolute_path)
    local exists = path:exists()
    
    if not exists then
        vim.notify("File does not exist or is not accessible: " .. absolute_path, vim.log.levels.DEBUG)
        return
    end
    
    local content = path:read()
    if content then
        table.insert(output, string.format("=== Content from: %s ===", relative_path))
        table.insert(output, content)
        table.insert(output, "\n")
    else
        vim.notify("Failed to read content of file: " .. absolute_path, vim.log.levels.DEBUG)
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
end

return M
