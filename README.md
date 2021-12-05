# Latex-img-paste.vim
Yet simple tool to paste images into latex files

## Use Case
You are editing a markdown file and have an image on the clipboard and want to paste it into the document as the text `![](img/image1.png)`. Instead of first copying it to that directory, you want to do it with a single `<leader>p` key press in Vim. So it hooks `<leader>p`, checks if you are editing a Markdown file, saves the image from the clipboard to the location  `img/image1.png`, and inserts `![](img/image1.png)` into the file.

By default, the location of the saved file (`img/image1.png`) and the in-text reference (`![](img/image1.png`) are identical. You can change this behavior by specyfing an absolute path to save the file (`let g:mdip_imgdir_absolute = /absolute/path/to/imgdir` on linux) and a different path for in-text references (`let g:mdip_imdir_intext = /relative/path/to/imgdir` on linux). 

## Installation

Using Vundle

```
Plugin 'wgmzbl/md-img-paste.vim'
```

## Usage
Add to .vimrc
```
autocmd FileType latex,tex nmap <buffer><silent> <leader>p :call mdip#LatexClipboardImage()<CR>
" there are some defaults for image directory and image name, you can change them
" let g:mdip_imgdir = 'img'
" let g:mdip_imgname = 'image'
```

### For linux user
This plugin gets clipboard content by running the `xclip` command.

install `xclip` first.

## Acknowledgements
I'm not yet perfect at writing vim plugins but I managed to do it. Thanks to [Karl Yngve Lervåg](https://vi.stackexchange.com/users/21/karl-yngve-lerv%C3%A5g) and [Rich](https://vi.stackexchange.com/users/343/rich) for help on [vi.stackexchange.com](https://vi.stackexchange.com/questions/14114/paste-link-to-image-in-clipboard-when-editing-markdown) where they proposed a solution for my use case.

