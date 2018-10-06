#!/bin/sh
# admin@kamenka.su
# Скрипт добавляющий БСДшную хистори и приглашение

# CSH FREEBSD-LIKE HISTORY (i prefer this becouse of FBSD youth)
PROMPT_COMMAND='history -a'
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# VERY USEFULL COLORING FOR THOSE WHO HAVE TONS OF CONSOLES IN USE
PS1='\[\e]0;[\w]\a\r\e[1;38;5;118;48;5;16m\] \u \[\e[38;5;16;48;5;118m\] \h \[\e[0m\] \$'

#
# OF COURSE IT IS BETTER TO PLACE THIS IN ~/.bashrc or similar config!
# do it yourself
