local M = {}

-- Check if fzf-lua is available
local has_fzf, fzf = pcall(require, 'fzf-lua')
local has_plenary, plenary = pcall(require, 'plenary')

-- List of file extensions to skip
local skip_extensions = {
    'png', 'jpg', 'jpeg', 'gif', 'bmp', 'pdf',
    'zip', 'tar', 'gz', 'bin', 'exe', 'o'
}

-- Function to check if file is text
local function is_text_file(filename)
    -- Check if file has a skippable extension
    for _, ext in ipairs(skip_extensions) do
        if filename:match('%.' .. ext .. '$') then
            return false
        end
    end
    -- Use plenary to check if file is readable text
    if has_plenary then
        local stat = plenary.path:new(filename):_stat()
        if stat and stat.type == 'file' then
            local cmd = string.format("file %q", filename)
            local output = vim.fn.system(cmd)
            return output:match('text') ~= nil
        end
    end
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
    end
end

-- Function to process files in a directory
local function process_directory(dir, output)
    local Path = require('plenary.path')
    local scandir = require('plenary.scandir')

    local files = scandir.scan_dir(dir, { hidden = false, add_dirs = false })

    for _, file in ipairs(files) do
        local relative_path = file:sub(#dir + 2) -- Remove dir prefix
        if is_text_file(file) then
            table.insert(output, string.format("=== Content from: %s ===", relative_path))
            local content = Path:new(file):read()
            table.insert(output, content)
            table.insert(output, "\n")
        end
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

-- Main function to select files and directories and process
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
        prompt = "Select files or folders to process (TAB to toggle, Enter to confirm)> ",
        cwd = vim.fn.getcwd(),
        file_ignore_patterns = { "%.git/" },
        fzf_opts = {
            ['--multi'] = '',
            ['--preview'] = '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || tree -C {} | head -n 20',
            ['--preview-window'] = 'up:40%'
        },
        actions = {
            ['default'] = function(selected)
                if not selected or #selected == 0 then
                    vim.notify("No files or folders selected. Exiting.", vim.log.levels.INFO)
                    return
                end

                local output = {}
                vim.notify("Selected items:\n" .. table.concat(selected, "\n"), vim.log.levels.INFO)

                for _, item in ipairs(selected) do
                    local stat = plenary.path:new(item):_stat()
                    if stat.type == 'directory' then
                        process_directory(item, output)
                    elseif stat.type == 'file' then
                        process_file(item, output)
                    end
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
    vim.api.nvim_create_user_command('Ctx', M.select_and_copy, { desc = "Select files/directories and copy text content to clipboard" })
    vim.notify("Ctx: Command registered", vim.log.levels.INFO)
end

return M
