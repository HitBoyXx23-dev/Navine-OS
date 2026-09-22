export PS1='\[\033[1;36m\]navine\[\033[0m\]:\w\$ '
export EDITOR=mousepad
export BROWSER=firefox-esr
alias ll='ls -la --color=auto'
alias la='ls -A'
alias navine-help='/usr/local/bin/navine-help'
alias navine-about='/usr/local/bin/navine-about'
[ -f /etc/navine-banner ] && [ -z "$NAVINE_BANNER_SHOWN" ] && {
    export NAVINE_BANNER_SHOWN=1
    cat /etc/navine-banner 2>/dev/null
}
