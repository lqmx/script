#!/bin/bash

# bash <(curl -s "https://raw.githubusercontent.com/lqmx/script/master/ql.sh") i

now=$(date)

if [[ -f "$HOME/.ql/config" ]]; then
    source "$HOME/.ql/config"
fi

cecho(){
    local exp=$1;
    local color=$2;
    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=1 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi
    tput setaf $color;
    echo -n $exp;
    tput sgr0;
}


Install() {
    echo "install"

    rm -rf "$HOME/.ql"

    if [[ ! -d $HOME/.ql ]]; then
        echo "mkdir $HOME/.ql"
        mkdir $HOME/.ql
    fi

    if [[ ! -f $HOME/.ql/config ]]; then
        username=$(git config --global user.name)
        cat <<EOT >> $HOME/.ql/config
qlUsername=$username # username
qlWpDir= # work dir
qlPbDir= # proto dir
EOT
    fi

    curl -s "https://raw.githubusercontent.com/lqmx/script/master/ql.sh" > $HOME/.ql/ql.sh
    chmod +x $HOME/.ql/ql.sh
    echo "alias i='$HOME/.ql/ql.sh'" >> $HOME/.bashrc
}

Config() {
    if [[ $# -eq 0 ]]; then
        if [[ -f $HOME/.ql/config ]]; then
            cat $HOME/.ql/config
        fi
    elif [[ $# -eq 1 ]]; then
        if [[ -f $HOME/.ql/config ]]; then
            grep -iE "$1" $HOME/.ql/config
        fi
    else
        if [[ $# -eq 2 ]]; then
            # todo set config value
            echo "set config $1=$2"
            sed -i '' "s/^$1.*/$1=$2/" $HOME/.ql/config
        fi
    fi
}


USAGE=$(cat <<-END
Hello, $(cecho $qlUsername green)

$now

Usage: $0 [command]

Commands:

  i: install

  c: config
       eg: ql c to see all config
       eg: ql c $(cecho [name] cyan) to see config
       eg: ql c $(cecho [name] cyan) $(cecho [value] cyan) to set config

END
)

if [[ "$1" == "i" ]]; then
    shift
    Install
elif [[ "$1" == "c" ]]; then
   shift
   Config $@
else
    echo "$USAGE"
    exit 1
fi
