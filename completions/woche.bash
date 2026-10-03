# bash completion for woche

_woche() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local command="${COMP_WORDS[1]}"
    local days="mon tue wed thu fri sat sun mont die mit don fre sam son"
    local words=""

    case "$COMP_CWORD" in
        1)
            words="create show all today search done edit delete open config init help --version $days"
            ;;
        2)
            case "$command" in
                show)
                    words="last $("${COMP_WORDS[0]}" all 2> /dev/null | sed -n 's/^\(\.\/\)\{0,1\}\([0-9]\{6\}\)\.md$/\2/p')"
                    ;;
                done | edit | delete) words="$days" ;;
                config) words="language dir" ;;
            esac
            ;;
        3)
            case "$command ${COMP_WORDS[2]}" in
                "config language") words="en de" ;;
                "config dir")
                    compopt -o filenames 2> /dev/null
                    mapfile -t COMPREPLY < <(compgen -d -- "$cur")
                    return
                    ;;
            esac
            ;;
    esac

    mapfile -t COMPREPLY < <(compgen -W "$words" -- "$cur")
}

complete -F _woche woche woche.sh
