if executable('clangd')
	au User lsp_setup call lsp#register_server({
	        \ 'name': 'clangd'
	        \ 'cmd': {server_info->['clangd']},
		\ 'whitelist': ['c', 'cpp'],
		\ })
endif

nnoremap gd :LspDefinition<CR>
nnoremap gr :LspReferences<CR>
nnoremap gi :LspImplementation<CR>
nnoremap K  :LspHover<CR>
