function! SafeMakeDir()
    if s:os == "Windows"
        let outdir = expand('%:p:h') . '\' . g:mdip_imgdir
    else
        let outdir = expand('%:p:h') . '/' . g:mdip_imgdir
    endif
    if !isdirectory(outdir)
        call mkdir(outdir)
    endif
    return fnameescape(outdir)
endfunction

function! SaveFileTMPLinux(imgdir, tmpname) abort
    let targets = filter(
                \ systemlist('xclip -selection clipboard -t TARGETS -o'),
                \ 'v:val =~# ''image/''')
    if empty(targets) | return 1 | endif

    let mimetype = targets[0]
    let extension = split(mimetype, '/')[-1]
    let tmpfile = a:imgdir . '/' . a:tmpname . '.' . extension
    call system(printf('xclip -selection clipboard -t %s -o > %s',
                \ mimetype, tmpfile))
    return tmpfile
endfunction

function! SaveFileTMPWin32(imgdir, tmpname) abort
    let tmpfile = a:imgdir . '/' . a:tmpname . '.png'

    let clip_command = "Add-Type -AssemblyName System.Windows.Forms;"
    let clip_command .= "if ($([System.Windows.Forms.Clipboard]::ContainsImage())) {"
    let clip_command .= "[System.Drawing.Bitmap][System.Windows.Forms.Clipboard]::GetDataObject().getimage().Save('"
    let clip_command .= tmpfile ."', [System.Drawing.Imaging.ImageFormat]::Png) }"
    let clip_command = "powershell -sta \"".clip_command. "\""

    silent call system(clip_command)
    if v:shell_error == 1
        return 1
    else
        return tmpfile
    endif
endfunction



function! SaveFileTMPMacOS(imgdir, tmpname) abort
    let tmpfile = a:imgdir . '/' . a:tmpname . '.png'
    let clip_command = 'osascript'
    let clip_command .= ' -e "set png_data to the clipboard as «class PNGf»"'
    let clip_command .= ' -e "set referenceNumber to open for access POSIX path of'
    let clip_command .= ' (POSIX file \"' . tmpfile . '\") with write permission"'
    let clip_command .= ' -e "write png_data to referenceNumber"'

    silent call system(clip_command)
    if v:shell_error == 1
        return 1
    else
        return tmpfile
    endif
endfunction

function! SaveFileSVGMacOS(imgdir, tmpname) abort
    let tmpfile = a:imgdir . '/' . a:tmpname . '.svg'
    let result = 1
" Using Python to save svg. If success, return 1.
python3 << EOF
import clipboard
from collections.abc import Iterable
import vim
text = clipboard.paste()
path = vim.eval("tmpfile")
if isinstance(text,Iterable):
    if "<svg" in text:
        myFile = open(path, 'w')
        myFile.write(text)
        myFile.close()
        vim.command("let result = 0")
EOF
    return result
endfunction

function! SaveFileTMP(imgdir, tmpname)
    if s:os == "Darwin"
        return SaveFileTMPMacOS(a:imgdir, a:tmpname)
    elseif s:os == "Linux"
        return SaveFileTMPLinux(a:imgdir, a:tmpname)
    elseif s:os == "Windows"
        return SaveFileTMPWin32(a:imgdir, a:tmpname)
    endif
endfunction

function! SaveNewFile(imgdir, tmpfile)
    let extension = split(a:tmpfile, '\.')[-1]
    let reldir = g:mdip_imgdir
    let cnt = 0
    let filename = a:imgdir . '/' . g:mdip_imgname . cnt . '.' . extension
    let relpath = reldir . '/' . g:mdip_imgname . cnt . '.' . extension
    while filereadable(filename)
        call system('diff ' . a:tmpfile . ' ' . filename)
        if !v:shell_error
            call delete(a:tmpfile)
            return relpath
        endif
        let cnt += 1
        let filename = a:imgdir . '/' . g:mdip_imgname . cnt . '.' . extension
        let relpath = reldir . '/' . g:mdip_imgname . cnt . '.' . extension
    endwhile
    if filereadable(a:tmpfile)
        call rename(a:tmpfile, filename)
    endif
    return relpath
endfunction

function! RandomName()
    " help feature-list
    if has('win16') || has('win32') || has('win64') || has('win95')
        let l:new_random = strftime("%Y-%m-%d-%H-%M-%S")
        " creates a file like this: `2019-11-12-10-27-10.png`
        " the filesystem on Windows does not allow : character.
    else
        let l:new_random = strftime("%Y-%m-%d-%H:%M")
    endif
    return l:new_random
endfunction

function! InputName()
    call inputsave()
    let name = input('Image name: ')
    call inputrestore()
    return name
endfunction

function! ChangeToSubfigure()
	let [start_l,start_c] = searchpairpos('\\begin{figure}','','\\end{figure}','bW')
	let [mid_l, mid_c] = searchpairpos('\\begin{\(sub\|\)figure}','\(\\incfig\|\\includegraphics\)','\\end{\(sub\|\)figure}','W')
    if mid_l>0
        if(match(getline('.'),'\(\\incfig\|\\includegraphics\)')!=-1)
            execute 's/\(\s*\)\(\\includegraphics\|\\incfig\)\(\[[0-9a-zA-Z=-\\.]*\]\)*{\([0-9a-zA-Z-\/.]*\)}/\1\\begin{subfigure}\[b\]{.48\\linewidth}\r\1\t\\centering\r\1\t\2\3{\4}\r\1\t\\caption{\4}\r\1\t\\label{fig:\4}\r\1\\end{subfigure}/'
            call searchpairpos('\\begin{subfigure}', '', '\\end{subfigure}','W')
            call cursor(line('.')-1,1)
            return 1
        endif
	endif
    return 0
endfunction

function! Find_Sub_Env()
    " check if in subfigure env. If so, insert after this env
    let [end_l, end_c] = searchpairpos('\\begin{subfigure}','','\\end{subfigure}','W')
    if end_l>0
        return 1
    endif

    " check if has subfigure before
	let [mid_l, mid_c] = searchpairpos('\\begin{figure}','\\end{subfigure}','\\end{figure}','bW')
    if mid_l >0
        if match(getline('.'), '\\end{subfigure}') > -1
            return 1
        endif
    endif
    
    " check if has subfigure after
	let [mid_l, mid_c] = searchpairpos('\\begin{figure}','\\end{subfigure}','\\end{figure}','nW')
    if mid_l >0
        if match(getline(mid_l), '\\end{subfigure}') > -1
            return 2       
        endif
    endif
    return 0
endfunction

function! latexip#LatexClipboardImage()
    " detect os: https://vi.stackexchange.com/questions/2572/detect-os-in-vimscript
    let s:os = "Windows"
    if !(has("win64") || has("win32") || has("win16"))
        let s:os = substitute(system('uname'), '\n', '', '')
    endif

    let workdir = SafeMakeDir()
    " change temp-file-name and image-name
    let g:mdip_tmpname = InputName()
    if empty(g:mdip_tmpname)
      let g:mdip_tmpname = RandomName()
    endif
    let save_name = substitute(g:mdip_tmpname, ' ', '_', 'g')


    let tmpfile = SaveFileSVGMacOS(workdir, save_name)
    if tmpfile == 0
        " svg image
        let texText = "\\incfig[0.8]{"
        let extension = "svg"
        let relpath = save_name
    else
        let tmpfile = SaveFileTMP(workdir, save_name)
        if tmpfile == 1
            return
        else
            let texText = "\\includegraphics[width=1\\textwidth]{"
            let extension = "png"
            let relpath = g:mdip_imgdir . '/' . save_name . '.' . extension
        endif
    endif
    
    let figure_title = "{figure}[ht]"
    let figure_title_end = "{figure}"

    " Remember cursor location
	let [bufnum, cur_l, cur_c, vr] = getpos('.')
    let res = ChangeToSubfigure()

    " Restore location
    " call append(cur_l-1,'abc')
    if res == 0
        call cursor(cur_l,cur_c)
    endif

    let has_sub_env = Find_Sub_Env()
    " call append(cur_l, has_sub_env)
    if has_sub_env==2
        call cursor(cur_l,cur_c)
    endif
    if has_sub_env>0
        let figure_title = "{subfigure}[b]{.48\\textwidth}"
        let figure_title_end = "{subfigure}"
    else
        call cursor(cur_l,cur_c)
    endif

    let match_res = matchlist(getline('.'), '\(\s*\)')
    let space_str = match_res[1]
"
"    let ret = "\\begin".figure_title
"    let ret = ret . space_str . '\t' . "\\centering\n"
"    let ret = ret . space_str . '\t' . texText . relpath . "}\n"
"    let ret = ret . space_str . '\t' . "\\caption{" . g:mdip_tmpname . "}\n"
"    let ret = ret . space_str . '\t' . "\\label{fig:" . save_name . "}\n"
"    let ret = ret . space_str . "\\end".figure_title_end
    call append(line('.'), space_str . "\\end".figure_title_end)
    call append(line('.'), space_str . "\t" . "\\label{fig:" . save_name . "}")
    call append(line('.'), space_str . "\t" . "\\caption{" . g:mdip_tmpname . "}")
    call append(line('.'), space_str . "\t" . texText . relpath . "}")
    call append(line('.'), space_str . "\t" . "\\centering")
    call append(line('.'), space_str . "\\begin".figure_title)
    "execute "normal! o" . ret
endfunction



if !exists('g:mdip_imgdir')
    let g:mdip_imgdir = 'figures'
endif
if !exists('g:mdip_tmpname')
    let g:mdip_tmpname = 'tmp'
endif
if !exists('g:mdip_imgname')
    let g:mdip_imgname = 'image'
endif