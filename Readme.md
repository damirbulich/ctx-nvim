Ctx_nvim
A Neovim plugin to select directories using fzf-lua, extract text from files, and copy the content to the clipboard.
Features

Select multiple directories using fzf-lua with a preview window.
Process text files, skipping common non-text extensions (e.g., .png, .pdf, .zip).
Copy file contents with relative paths as headers to the clipboard.
Fallback to displaying content in a new Neovim buffer if no clipboard tool is found.
Uses plenary.nvim for file operations and fzf-lua for directory selection.

Requirements

Neovim 0.7.0 or higher
fzf-lua
plenary.nvim
fzf installed on your system (for preview functionality)
A clipboard tool (xclip, wl-copy, or pbcopy)

Installation
Using lazy.nvim
Add the following to your lazy.nvim configuration:
{
  "your-username/fzf-dir-copy",
  dependencies = {
    "ibhagwan/fzf-lua",
    "nvim-lua/plenary.nvim",
  },
}

Replace your-username/fzf-dir-copy with the actual repository path (e.g., github.com/your-username/fzf-dir-copy).
Manual Installation

Clone the repository into ~/.config/nvim/pack/plugins/start/:git clone https://github.com/your-username/fzf-dir-copy.git ~/.config/nvim/pack/plugins/start/fzf-dir-copy


Ensure fzf-lua and plenary.nvim are installed.

Usage
Run the following command in Neovim:
:FzfDirCopy

This opens an fzf-lua interface to select directories. Use TAB to toggle selection, and Enter to confirm. The plugin will:

Process text files in the selected directories.
Copy their contents (with relative paths as headers) to the clipboard.
Display a notification with the number of lines copied or open a new buffer if no clipboard tool is available.

License
MIT License

