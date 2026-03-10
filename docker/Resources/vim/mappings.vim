nnoremap <C-p> :Files<CR>
nnoremap <C-b> :Buffers<CR>

if executable($SHELL)
	nnoremap <leader>t :vsplit | terminal fish<CR>
endif
