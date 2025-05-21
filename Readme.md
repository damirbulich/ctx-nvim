# Ctx_nvim

A Neovim plugin to select files using `fzf-lua`, extract text from them, and copy the content to the clipboard.

## Features

- **Directory Selection**: Select multiple directories using `fzf-lua` with a preview window for easy navigation.
- **Text File Processing**: Process text files while skipping common non-text extensions (e.g., `.png`, `.pdf`, `.zip`).
- **Clipboard Integration**: Copy file contents with relative paths as headers to the system clipboard.
- **Fallback Display**: If no clipboard tool is found, display content in a new Neovim buffer.
- **Dependencies**: Utilizes `plenary.nvim` for file operations and `fzf-lua` for directory selection.

## Requirements

- Neovim 0.7.0 or higher
- `fzf-lua`
- `plenary.nvim`
- `fzf` installed on your system (required for preview functionality)
- A clipboard tool (`xclip`, `wl-copy`, or `pbcopy`)

## Installation

### Using lazy.nvim

Add the following to your `lazy.nvim` configuration:

```lua
{
    "damirbulich/ctx-nvim",
    dependencies = {
        "ibhagwan/fzf-lua",
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("ctx_nvim").setup()
        vim.keymap.set("n", "<C-g>", ":Ctx<Return>", {})
    end,
}
```

Replace `your-username/fzf-dir-copy` with the actual repository path (e.g., `github.com/your-username/fzf-dir-copy`).

### Manual Installation

1. Clone the repository into `~/.config/nvim/pack/plugins/start/`:

   ```bash
   git clone https://github.com/your-username/fzf-dir-copy.git ~/.config/nvim/pack/plugins/start/fzf-dir-copy
   ```

2. Ensure `fzf-lua` and `plenary.nvim` are installed.

## Usage

Run the following command in Neovim:

```
:Ctx
```

This opens an `fzf-lua` interface to select directories. Usage steps:

1. Use `TAB` to toggle directory selection.
2. Press `Enter` to confirm your selection.
3. The plugin will:
   - Process text files in the selected directories.
   - Copy their contents (with relative paths as headers) to the clipboard.
   - Display a notification with the number of lines copied or open a new buffer if no clipboard tool is available.

## License

MIT License
