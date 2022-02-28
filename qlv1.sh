#!/bin/bash
#
########### Ql #################
#
# Script for ql
# License: GPL-3
#
####################################################
Usage() {
    cat <<EOF
Usage:
    Usage: $(basename "${BASH_SOURCE[0]}") arg1 [arg2...]

Options:
    
Params:
    git:
        gitpull, pull, gpl, pl          $(cecho optional '[service,...|group]')
        gitclone, clone, gcl, cl        $(cecho required '(service,...)')
        gitbranch, branch, gbr, br      $(cecho optional '[branch] [service,...]')
        gitpush, push, gph, ph          $(cecho optional '[service,...]')

    generate:
        init, i                         $(cecho optional '[service,...]')
        addrpc, arp                     $(cecho required '(service)') $(cecho required '(rpcname)') $(cecho required '(gento)') $(cecho optional '[user:sys,staff]')
        generate, gen, g                $(cecho optional '[service,...|group]')
        generateclient, genc, gc        $(cecho optional '[service,...]')
        generateserver, gens, gs        $(cecho optional '[service,...]')

    dev:
        updatemod, upm, um              $(cecho optional '[service,...]')
        run, r                          $(cecho optional "[service] [os] [server:dev,test,tdev,ttest]")
        buildtool, bt                   $(cecho optional '[service]')
        package, pkg                    $(cecho optional '[service]')
        sync, s                         $(cecho optional '[service] [branch]')

    ops:
        deploy, d                       $(cecho required '(service,...) (remark)') $(cecho optional '[barnch:test,master]')
        ssh, go                         $(cecho required '(server:dev,test,tdev,ttest,j)')
        log, l                          $(cecho required '(reqid)') $(cecho optional '[servergroup:dev,test]') 

EOF
}
# Variables
version="1.0.0"
scriptName="ql"
scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
utilsLocalPath="$scriptPath/utils.sh"

# baseDir="$HOME"
baseDir="./"
confDir="$baseDir/.ql"
confFile="$confDir/config.sh"
tmpDir="$confDir/tmp"
logFile="$tmpDir/$(date +%Y%m%d).$RANDOM.$$.log"

# Init config and tmp dir
if [[ ! -d $confDir ]]; then
    mkdir -p $confDir
fi

if [[ ! -d $tmpDir ]]; then
    mkdir -p $tmpDir
fi

if [[ -f "$confFile" ]]; then
    source "$confFile"
else
    cat << EOF > "$confFile"
#!/bin/bash
# 
username="$USER"
templatePath=
sourceDir=
workDir=
pbDir=
devIp=
devUser=
devPort=
testIp=
testUser=
testPort=
tDevIp=
tDevUser=
tDevPort=
tTestIp=
tTestUser=
tTestPort=
syncToolUser=
syncToolDir=
jIp=
jUser=
jPort=

export HOST_DEV=
export TEMPLATE_PATH=

# group
# eg: group1=service1,service2,service3

EOF
    source "$confFile"
fi

# Utils
divider() {
    printf "%60s" " " | tr ' ' '-' 
    echo
}

joinBy() {
    local IFS="$1"
    shift
    echo "$*"
}

cecho() {
    Black='\033[0;30m'
    Red='\033[0;31m'
    Green='\033[0;32m'
    Orange='\033[0;33m'
    Blue='\033[0;34m'
    Purple='\033[0;35m'
    Cyan='\033[0;36m'
    LightGray='\033[0;37m'
    DarkGray='\033[1;30m'
    LightRed='\033[1;31m'
    LightGreen='\033[1;32m'
    Yellow='\033[1;33m'
    LightBlue='\033[1;34m'
    LightPurple='\033[1;35m'
    LightCyan='\033[1;36m'
    White='\033[1;37m'

    NC='\033[0m' # No Color
    case $1 in
        "black")
            echo -e "${Black}$2${NC}"
            ;;
        "red" | "err")
            echo -e "${Red}$2${NC}"
            ;;
        "green" | "ok" | "greet" | "required")
            echo -e "${Green}$2${NC}"
            ;;
        "orange" | "warn")
            echo -e "${Orange}$2${NC}"
            ;;
        "blue" | "info")
            echo -e "${Blue}$2${NC}"
            ;;  
        "purple")
            echo -e "${Purple}$2${NC}"
            ;;
        "cyan" | "debug" | "optional")
            echo -e "${Cyan}$2${NC}"
            ;;
        "lightgray")
            echo -e "${LightGray}$2${NC}"
            ;;
        "darkgray")
            echo -e "${DarkGray}$2${NC}"
            ;;
        "lightred")
            echo -e "${LightRed}$2${NC}"
            ;;
        "lightgreen")
            echo -e "${LightGreen}$2${NC}"
            ;;
        "yellow")
            echo -e "${Yellow}$2${NC}"
            ;;
        "lightblue")
            echo -e "${LightBlue}$2${NC}"
            ;;
        "lightpurple")
            echo -e "${LightPurple}$2${NC}"
            ;;
        "lightcyan")
            echo -e "${LightCyan}$2${NC}"
            ;;
        "white")
            echo -e "${White}$2${NC}"
            ;;
        *)
            echo -e "$2"
            ;;
    esac
}

die() {
    cecho red "$1"
    exit 1
}

safeExit() {
    exit 0
}
cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}
getservice() {
    local services=();
    if [[ $# -eq 0 ]]; then
        local dirname=$(pwd | sed 's/.*\///')
        local serviceName=$(echo $dirname | sed 's/server//g')
        services=($serviceName)
    else
        if [[ $1 == gg* ]]; then
            local str=$1
            local group=$(grep ${str:1:${#str}}= $confFile)
            if [[ $group != "" ]]; then
                services=($(echo ${group:3:${#group}} | cut -d= -f2 | tr ',' ' '))
            fi
        else
            services=($(echo $1 | cut -d= -f2 | tr ',' ' '))
        fi
    fi

    declare -p services
}

# Function

## Pull code
#
# Alias: gitpull, pull, gpl pl
# Params:
# * $1 - optional, service or service group
#        service spilted by ,
#        service group will be set in config.sh
# Example:
#   gitpull
#   gitpull service1,service2
#   gitpull servicegroup
# Returns:
# * 0 - successfully
# * 1 - failed
GitPull() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        if [[ -d "$workDir/$service" ]]; then
            cecho info "Pulling Client $service"
            cd "$workDir/$service"
            git pull
        fi
        divider
        if [[ -d "$workDir/$service"server ]]; then
            cecho info "Pulling Server $service"
            cd "$workDir/$service"server
            git pull
        fi
    done

}
GitClone() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho info "$service"
        if [[ ! -d "$workDir/$service" ]]; then
            cecho info "git clone $gitLabUrl/$service"
            git clone $gitLabUrl/$service $workDir/$service
        else
            cecho info "git pull $workDir/$service"
            cd $workDir/$service
            git pull
        fi
        divider
        if [[ ! -d "$workDir/$service"server ]]; then
            cecho info "git clone $gitLabUrl/$service"server
            git clone "$gitLabUrl/$service"server "$workDir/$service"server
        else
            cecho info "git pull $workDir/$service"server
            cd "$workDir/$service"server
            git pull
        fi
        divider
    done
}
GitBranch() {
    local branchName=""
    if [[ $# -eq 0 ]]; then
        die "No branch specified"
    fi
    branchName=$(date +%m%d)_$1
    shift

    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        cecho info "$service"
        divider
        if [[ ! -d "$workDir/$service"server ]]; then
            cecho info "git clone $gitLabUrl/$service"server
            git clone "$gitLabUrl/$service"server "$workDir/$service"server
        fi

        cd "$workDir/$service"server
        git checkout master
        git pull
        git checkout -b $branchName
        git push --set-upstream origin $branchName

        divider
    done
    
    echo
}
GitPush() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho info "$service"
        if [[ ! -d "$workDir/$service" ]]; then
            cecho warn "No git repo found for $service"
        else
            cecho info "git pull $workDir/$service"
            cd $workDir/$service
            git pull
            # todo remove
            sed -i "s/\!\*\.\*//g"  .gitignore
	        git status
            git commit -am 'ok'
            git push
        fi
    done
}
GitMerge() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    if [[ $2 == "" ]]; then
        die "No branch specified"
    fi
    $branchName=$2

    for service in "${services[@]}"; do
        git merge "origin/$branchName"
        local mergeConflictFiles=$(git diff --name-only --diff-filter=U)
        if [[ $mergeConflictFiles != "" ]]; then
            cecho warn "Merge conflict found for $service: $mergeConflictFiles"
        fi
        for file in $mergeConflictFiles; do
            if [[ $file != "go.mod" ]] && [[ $file != "go.sum" ]]; then
                die "Merge conflict found for $service: $file"
            fi
            cecho warn "Solve conflict for $service: $file"
            git checkout HEAD $file
        done
    done
}
Init() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    local registerTxt="$pbDir/server_register.txt"
    for i in "${!services[@]}"; do
        local service=${services[$i]}
        divider
        cecho info "$service"
        if ! grep "^$service " "$registerTxt"; then
            port=$(tail -n 1 "$registerTxt" | awk -F" " '{print $2}')
            errcode=$(tail -n 1 "$registerTxt" | awk -F" " '{print $NF}')
            cecho info "$service $(($port+$i+1)) $errcode - $(($errcode+1000*($i+1)))"
            echo "$service $(($port+1)) $errcode - $(($errcode+1000))" >> "$registerTxt"
        fi

        if [[ ! -f "$pbDir/$service" ]]; then
            rpc_gen -f Init -n "$service"
        fi

        GitClone $service
    done
}
AddRpc() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    if [[ $2 == "" ]]; then
        die "No rpc name specified"
    fi

    if [[ $3 == "" ]]; then
        die "No gento specified"
    fi

    local rpcName=$2
    local genTo=$3
    local user=$4

    for service in "${services[@]}"; do
        divider
        cecho info "$service"
        cd "$pbDir"
        if [[ $user != "" ]]; then
            rpc_gen -f AddRpc -p "$service".proto -r "$rpcName" -g "$genTo" -u "$user"
        else
            case "$rpcName" in
            *Sys )  rpc_gen -f AddRpc -p "$service".proto -r "$rpcName" -g "$genTo" -u sys;;
            * ) rpc_gen -f AddRpc -p "$service".proto -r "$rpcName" -g "$genTo";;
            esac
        fi
    done
}
Generate() {
    cecho info "Generate Client"
    GenerateClient "$@"
    cecho info "Generate Server"
    GenerateServer "$@"
}
GenerateClient() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho info "$service"
        rpc_gen -f GenClient -p $pbDir/${service}.proto 
    done
}
GenerateServer() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho info "$service"
        rpc_gen -f GenServer -p $pbDir/${service}.proto 
    done
}
UpdateMod() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in ${services[@]}; do
        divider
        cecho info "$service"
        local clientPath=$workDir/${service}
        if [[ ! -d $clientPath ]]; then
            die "No client repo found for $service"
        fi
        cd $clientPath
        rpc_gen -f UpdateAllMod
         
        divider
        local serverPath=$workDir/${service}server
        if [[ ! -d $serverPath ]]; then
            die "No server repo found for $service"
        fi
        cd $serverPath
        rpc_gen -f UpdateAllMod
    done
}
Run() {
    if [[ $1 != "" ]]; then
        cd "$workDir/$1"server || die "No such service"
    fi
    console.sh run
}
BuildTool() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho info "$service"
        cd "$workDir/$service"server
        # build
        if [[ $2 != "" ]]; then
            GOOS=$2 tools_builder -f "${service}_tool.go"
        else
            tools_builder -f "${service}_tool.go"
        fi
        # sync
        if [[ $3 != "" ]]; then
            local ip=""
            if [[ $3 == "dev" ]]; then
                ip=$devIp
            elif [[ $3 == "test" ]]; then
                ip=$testIp
            elif [[ $3 == "tdev" ]]; then
                ip=$tDevIp
            elif [[ $3 == "ttest" ]]; then
                ip=$tTestIp
            else
                ip=$3
            fi
            cecho info "scp ${service}_tool $syncToolUser@$ip:$syncToolDir"
            scp "${service}_tool" $syncToolUser@"$ip":$syncToolDir
            rm "${service}_tool"
        fi
    done
    
}
Package() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi
    
    for service in "${services[@]}"; do
        divider
        cecho info "$service"
        cd "$workDir/$service"server || die "No such service"
        console.sh pkg
    done
}
Sync() {
    local services=()
    if [[ $# -eq 0 ]]; then
        local dirname=$(pwd | sed 's/.*\///')
        local serviceName=$(echo $dirname | sed 's/server//g')
        services=($serviceName)
    else
        eval $(getservice "$@")
    fi
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    local branchName=dev
    if [[ ${#services[@]} == 1 ]]; then
        local currentBranch=$(git rev-parse --abbrev-ref HEAD)
        if [[ $currentBranch != "dev" ]]; then
            if [[ $(git status -s) != "" ]]; then
                sed -i "" "s/\(.*\)\/\/\(todo for dev.*\)/\/\/\1\/\/\2/g" go.mod 
                cecho warn "Commit changes before sync"
                git commit -am "ok"
                git push
            fi
        fi
    fi

    if [[ $2 != "" ]]; then
        branchName=$2
    fi
    
    for service in "${services[@]}"; do
        divider
        cecho info "$service"
        cd "$workDir/$service"server || die "No such service"
        git checkout dev
        git pull
        if [[ $branchName != "dev" ]] && [[ $branchName != "" ]]; then
            if ! GitMerge $service $branchName; then
                die "Merge failed"
            fi

            rpc_gen -f UpdateAllMod
            console.sh sync

            if [[ $(git status | grep -c "nothing to commit") -eq 0 ]]; then
                git commit -am "ok"
                git push origin dev
            fi

            if [[ $branchName != "dev" ]] && [[ $branchName != "" ]]; then
                git checkout "$branchName"
                sed -i "" "s/\/\/\(.*\)\/\/\(todo for dev.*\)/\1\/\/\2/g" go.mod
            fi
        fi
    done
}
Deploy() {
    local services=()
    eval $(getservice "$@")
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    if [[ $2 == "" ]]; then
        die "No remark specified"
    fi
    local remark=$2

    local branchName=test
    if [[ $3 != "" ]]; then
        branchName=$3
    fi

    local allPkgs=()
    for service in "${services[@]}"; do
        divider
        cecho info "$service"
        cd "$workDir/$service"server || die "No such service: $service"
        git checkout $branchName
        git pull origin $branchName
        local commitHash=$(git rev-parse HEAD)
        console.sh pkg || die "Package failed: $service"
        local pkgName="$service-$branchName-${commitHash:0:8}.tar.gz"
        console.sh store "$pkgName" "$remark" || die "Store failed: $service"
        allPkgs+=($pkgName)
    done

    joinBy $'\n' "${allPkgs[@]}"
    echo 
}
Ssh() {
    local ip=""
    if [[ $1 != "" ]]; then
        if [[ $1 == "dev" ]]; then
            ip=$devIp
        elif [[ $1 == "test" ]]; then
            ip=$testIp
        elif [[ $1 == "tdev" ]]; then
            ip=$tDevIp
        elif [[ $1 == "ttest" ]]; then
            ip=$tTestIp
        else
            ip=$1
        fi
    fi

    if [[ $ip == 'j' ]]; then
        ip=$jIp
        ssh $jUser@$jIp -p $jPort
    fi

    local user=""
    if [[ $2 != "" ]]; then
        if [[ $2 == "dev" ]]; then
            user=$devUser
        elif [[ $2 == "test" ]]; then
            user=$testUser
        elif [[ $2 == "tdev" ]]; then
            user=$tDevUser
        elif [[ $2 == "ttest" ]]; then
            user=$tTestUser
        else
            user=$2
        fi
    fi

    local port=""
    if [[ $3 != "" ]]; then
        if [[ $3 == "dev" ]]; then
            port=$devPort
        elif [[ $3 == "test" ]]; then
            port=$testPort
        elif [[ $3 == "tdev" ]]; then
            port=$tDevPort
        elif [[ $3 == "ttest" ]]; then
            port=$tTestPort
        else
            port=$3
        fi
    fi

    ssh $user@$ip -p $port
}
Log() {
    cecho warn "TODO"
}

# main
main() {
    if [[ $# -lt 1 ]]; then
        echo Hello, $(cecho greet "$username") 
        echo "Version: $version"
        safeExit
    fi

    case "$1" in
    h | help) Usage ;;
    gitpull | pull | gpl | pl) GitPull "${@:2}" ;;
    gitclone | clone | gcl | cl) GitClone "${@:2}" ;;
    gitbranch | branch | gbr | br) GitBranch "${@:2}" ;;
    gitpush | push | gph | ph) GitPush "${@:2}" ;;
    init | i) Init "${@:2}" ;;
    addrpc | arp) AddRpc "${@:2}" ;;
    generate | gen | g) Generate "${@:2}" ;;
    generateclient | genc | gc) GenerateClient "${@:2}" ;;
    generateserver | gens | gs) GenerateServer "${@:2}" ;;
    updatemod | upm | um) UpdateMod "${@:2}" ;;
    run | r) Run "${@:2}" ;;
    buildtool | bt) BuildTool "${@:2}" ;;
    package | pkg) Package "${@:2}" ;;
    sync | s) Sync "${@:2}" ;;
    deploy | d) Deploy "${@:2}" ;;
    ssh | go) Ssh "${@:2}" ;;
    log | l) Log "${@:2}" ;;
    *) Usage ;;
    esac
}


# main

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

main "$@"