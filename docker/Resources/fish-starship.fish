if status --is-interactive
	starship init fish | source
end

set -gx STARSHIP_LOG error
set -gx EDITOR nvim

set -gx LANG C.UTF-8
set -gx LC_ALL C.UTF-8
