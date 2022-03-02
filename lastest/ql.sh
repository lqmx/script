#!/bin/bash
#
########### Ql #################
#
# Script for ql
# License: GPL-3
#
####################################################
# Base Variables
version='v1.0.0'
scriptName="ql"
scriptPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"

Usage() {
    cat <<EOF
Usage:
    Usage: $scriptName arg [arg,...]
Options:
    
Params:
    git:
        gitpull, pull, gpl, pl          $(cecho optional '[service,...|group]')
        gitclone, clone, gcl, cl        $(cecho required '(service,...)')
        gitbranch, branch, gbr, br      $(cecho optional '[branch] [service,...]')
        gitpush, push, gph, ph          $(cecho optional '[service,...]')
    generate:
        init, i                         $(cecho optional '[service,...]')
        addrpc, arp                     $(cecho required '[service]') $(cecho required '[rpcname]') $(cecho required '[gento]') $(cecho optional '[user:sys,staff]')
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
        deploy, d                       $(cecho required '(service,...) (remark)') $(cecho optional '[branch:test,master]')
        ssh, go                         $(cecho required '(service:dev,test,tdev,ttest,j)')
        log, l                          $(cecho required '(reqid)') $(cecho optional '[servergroup:dev,test]')
EOF
}

# Variables
username=$USER
workDir=
pbDir=
gitLabUrl=
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


# baseDir="$HOME"
baseDir=$scriptPath
confDir="$baseDir/.ql"
confFile="$confDir/config.sh"
tmpDir="$confDir/tmp"
#logFile="$tmpDir/$(date +%Y%m%d).$RANDOM.$$.log"

# Init config and tmp dir
if [[ ! -d $confDir ]]; then
    mkdir -p "$confDir"
fi

if [[ ! -d $tmpDir ]]; then
    mkdir -p "$tmpDir"
fi

if [[ -f "$confFile" ]]; then
    # shellcheck disable=SC1090
    . "${confFile}"
else
    cat << EOF > "$confFile"
#!/bin/bash
# 
username="$USER"
username=
workDir=
pbDir=
gitLabUrl=
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
    # shellcheck disable=SC1090
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
#    content="$(echo "$2" | awk '{print toupper($2)}')"
    case $1 in
        "black")
            echo -e "${Black}$2${NC}"
            ;;
        "red" | "err")
            echo -e "${Red}$2${NC}"
            ;;
        "green" | "ok" | "greet")
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
        "cyan" | "debug")
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
        "lightgreen" | "required")
            echo -e "${LightGreen}$2${NC}"
            ;;
        "yellow")
            echo -e "${Yellow}$2${NC}"
            ;;
        "lightblue" | "optional")
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
getService() {
    local services=();
    if [[ $# -eq 0 ]]; then
      while IFS='' read -r line; do services+=("$line"); done < <(basename "$(pwd)" | sed 's/server//g')
    else
        if [[ $1 == gg* ]]; then
          IFS=" " read -r -a services <<< "$(grep "${1:1:${#1}}=" "$confFile" | awk -F= '{print $2}' | tr ',' ' ')"
        else
          IFS=" " read -r -a services <<< "$(echo "$1" | cut -d= -f2 | tr ',' ' ')"
        fi
    fi
    declare -p services
}
commitCode() {
    cecho debug "Commit code..."
    if [[ $(git status -s) != "" ]]; then
        git status
	    git add .
        git commit -m 'ok'
	  fi
	  git push
}
sedX() {
    if [[ $(uname) == "Darwin" ]]; then
        sed -i '' "$1" "$2"
    else
        sed -i "$1" "$2"
    fi
}

# Function
Test() {
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
      echo "$service"
    done

    cecho debug "Services: $(joinBy , "${services[@]}")"

}
## Pull code
#
# Alias: gitpull, pull, gpl pl
# Params:
# * $1 - optional, service or service group
#        service spilt by ,
#        service group will be set in config.sh
# Example:
#   gitpull
#   gitpull service1,service2
#   gitpull servicegroup
# Returns:
# * 0 - successfully
# * 1 - failed
GitPull() {
    cecho debug "Git Pull..."

    if [[ $# == 0 ]]; then
      git pull
      safeExit
    fi
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho debug "$service"
        if [[ -d "$workDir/$service" ]]; then
            cecho debug "Pulling Client $service"
            cd "$workDir/$service"
            git pull
        fi
        divider
        if [[ -d "$workDir/$service"server ]]; then
            cecho debug "Pulling Server $service"
            cd "$workDir/$service"server
            git pull
        fi
    done

}
GitClone() {
    cecho debug "Git Clone..."
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho debug "$service"
        if [[ ! -d "$workDir/$service" ]]; then
            cecho debug "Git clone $gitLabUrl/$service"
            git clone "$gitLabUrl/$service" "$workDir/$service"
        else
            cecho debug "Git pull $workDir/$service"
            cd "$workDir/$service"
            git pull
        fi
        divider
        if [[ ! -d "$workDir/$service"server ]]; then
            cecho debug "Git clone $gitLabUrl/$service"server
            git clone "$gitLabUrl/$service"server "$workDir/$service"server
        else
            cecho debug "Git pull $workDir/$service"server
            cd "$workDir/$service"server
            git pull
        fi
        divider
    done
}
GitBranch() {
    cecho debug "Git Branch..."
    local branchName=""
    if [[ $# -eq 0 ]]; then
        die "No branch specified"
    fi
    branchName=$(date +%m%d)_$1
    shift

    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    cecho debug "BranchName: $branchName"

    for service in "${services[@]}"; do
        cecho debug "$service"
        divider
        if [[ ! -d "$workDir/$service"server ]]; then
            cecho debug "Git clone $gitLabUrl/$service"server
            git clone "$gitLabUrl/$service"server "$workDir/$service"server
        fi

        cd "$workDir/$service"server
        cecho debug "Checkout master"
        git checkout master
        cecho debug "Pull"
        git pull
        git checkout -b "$branchName"
        cecho debug "Push Orgin"
        git push --set-upstream origin "$branchName"
        divider
    done
}
GitPush() {
    cecho debug "Git Push..."
    if [[ $# == 0 ]]; then
      # todo remove
      sedX 's/^#.*//' "$confFile"
      commitCode
      safeExit
    fi

    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho debug "$service"
        if [[ ! -d "$workDir/$service" ]]; then
            cecho warn "No git repo found for $service"
        else
            cecho debug "Git pull $workDir/$service"
            cd "$workDir/$service"
            git pull
            # todo remove
            sedX "s/\!\*\.\*//g" .gitignore
	        commitCode
        fi
    done
}
GitMerge() {
  cecho debug "Git Merge..."
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    if [[ $2 == "" ]]; then
        die "No branch specified"
    fi
    branchName=$2

    for service in "${services[@]}"; do
        cecho debug "Merge $branchName"
        git merge "origin/$branchName"
        local mergeConflictFiles
        mergeConflictFiles=$(git diff --name-only --diff-filter=U)
        if [[ $mergeConflictFiles != "" ]]; then
            cecho warn "Merge conflict found for $service: $mergeConflictFiles"
        fi
        for file in $mergeConflictFiles; do
            if [[ $file != "go.mod" ]] && [[ $file != "go.sum" ]]; then
                die "Merge conflict found for $service: $file"
            fi
            cecho warn "Solve conflict for $service: $file"
            git checkout HEAD "$file"
        done
    done
}
Init() {
    cecho debug "Init..."
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    local registerTxt="$pbDir/server_register.txt"
    for i in "${!services[@]}"; do
        local service=${services[$i]}
        divider
        cecho debug "$service"
        if ! grep "^$service " "$registerTxt"; then
            local port
            local errcode
            port=$(tail -n 1 "$registerTxt" | awk -F" " '{print $2}')
            errcode=$(tail -n 1 "$registerTxt" | awk -F" " '{print $NF}')
            cecho debug "Write to file: $service $(("$port"+"$i"+1)) $errcode - $(("$errcode"+1000*("$i"+1)))"
            echo "$service $(("$port"+1)) $errcode - $(("$errcode"+1000))" >> "$registerTxt"
        fi

        if [[ ! -f "$pbDir/$service" ]]; then
            rpc_gen -f Init -n "$service"
        fi

        GitClone "$service"
    done
}
AddRpc() {
  cecho debug "AddRpc..."
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    if [[ $# -lt 2 ]] || [[ $2 == "" ]]; then
        die "No rpc name specified"
    fi

    if [[ $# -lt 3 ]] || [[ $3 == "" ]]; then
        die "No gento specified"
    fi

    local rpcName=$2
    local genTo=$3
    local user=
    if [[ $# -gt 3 ]]; then
      user=$4
    fi

    for service in "${services[@]}"; do
        divider
        cecho debug "$service"
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
    cecho debug "Generate..."
    cecho debug "Generate Client"
    GenerateClient "$@"
    cecho debug "Generate Server"
    GenerateServer "$@"
}
GenerateClient() {
   cecho debug "Generate Client..."
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho debug "$service"
        rpc_gen -f GenClient -p "$pbDir/${service}.proto"
        ig field -o "$service"
    done
}
GenerateServer() {
    cecho debug "Generate Server..."
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho debug "$service"
        rpc_gen -f GenServer -p "$pbDir/${service}.proto"
    done
}
UpdateMod() {
    cecho debug "UpdateMod..."
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho debug "$service"
        local clientPath=$workDir/${service}
        if [[ ! -d $clientPath ]]; then
            die "No client repo found for $service"
        fi
        cd "$clientPath"
        rpc_gen -f UpdateAllMod
         
        divider
        local serverPath=$workDir/${service}server
        if [[ ! -d $serverPath ]]; then
            die "No server repo found for $service"
        fi
        cd "$serverPath"
        rpc_gen -f UpdateAllMod
    done
}
Run() {
    cecho debug "Run..."
    if [[ $# -gt 1 ]] && [[ $1 != "" ]]; then
        cd "$workDir/$1"server || die "No such service"
    fi
    console.sh run
}
BuildTool() {
    cecho debug "BuildTool..."
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    for service in "${services[@]}"; do
        divider
        cecho debug "$service"
        cd "$workDir/$service"server/tool
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
            cecho debug "Scp ${service}_tool $syncToolUser@$ip:$syncToolDir"
            scp "${service}_tool" "$syncToolUser"@"$ip":"$syncToolDir"
            cecho debug "Remove ${service}_tool"
            rm "${service}_tool"
        fi
    done
    
}
Package() {
    cecho debug "Package..."
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi
    
    for service in "${services[@]}"; do
        divider
        cecho debug "$service"
        cd "$workDir/$service"server || die "No such service"
        console.sh pkg
    done
}
Sync() {
    cecho debug "Sync..."
    local services=()
    if [[ $# -eq 0 ]]; then
        local dirname
        dirname=$(pwd | sed 's/.*\///')
        services=("${dirname//server/}")
    else
        eval "$(getService "$@")"
    fi
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    local branchName=dev
    if [[ ${#services[@]} == 1 ]]; then
        local currentBranch
        currentBranch=$(git rev-parse --abbrev-ref HEAD)
        if [[ $currentBranch != "dev" ]]; then
            if [[ $(git status -s) != "" ]]; then
                cecho debug "Remove todo in go.mod"
                sedX -i "s/\(.*\)\/\/\(todo for dev.*\)/\/\/\1\/\/\2/g" go.mod
                cecho warn "Commit changes before sync"
                commitCode
            fi
        fi
        branchName=$currentBranch
    fi

    if [[ $# -gt 1 ]]; then
      branchName=$2
    fi

    cecho debug "BranchName: $branchName"
    for service in "${services[@]}"; do
        divider
        cecho debug "$service"
        cd "$workDir/$service"server || die "No such service"
        cecho debug "Switch dev..."
        git checkout dev
        cecho debug "Pull code..."
        git pull
        if [[ $branchName != "dev" ]] && [[ $branchName != "" ]]; then
            if ! GitMerge "$service" "$branchName"; then
                die "Merge failed"
            fi
        fi

        cecho debug "UpdateAllMod..."
        rpc_gen -f UpdateAllMod
        cecho debug "Sync code..."
        console.sh sync

        if [[ $(git status | grep -c "nothing to commit") -eq 0 ]]; then
            commitCode
        fi

        if [[ $branchName != "dev" ]] && [[ $branchName != "" ]]; then
            git checkout "$branchName"
            cecho debug "reset todo in go.mod"
            sedX -i "s/\/\/\(.*\)\/\/\(todo for dev.*\)/\1\/\/\2/g" go.mod
        fi
    done
}
Deploy() {
    cecho debug "Deploy..."
    local services=()
    eval "$(getService "$@")"
    if [[ ${#services[@]} -eq 0 ]]; then
        die "No service specified"
    fi

    if [[ $# -lt 2 ]] || [[ $2 == "" ]]; then
        die "No remark specified"
    fi
    local remark=$2

    local branchName=test
    if [[ $# -lt 3 ]] || [[ $3 != "" ]]; then
        branchName=$3
    fi

    local allPkgs=()
    for service in "${services[@]}"; do
        divider
        cecho debug "$service"
        cd "$workDir/$service"server || die "No such service: $service"
        git checkout "$branchName"
        git pull origin "$branchName"
        local commitHash
        commitHash=$(git rev-parse HEAD)
        console.sh pkg || die "Package failed: $service"
        local pkgName="$service-$branchName-${commitHash:0:8}.tar.gz"
        console.sh store "$pkgName" "$remark" || die "Store failed: $service"
        commitCode
        allPkgs+=("$pkgName")
    done

    divider
    cecho ok "joinBy $'\n' "${allPkgs[@]}""
    echo 
}
Ssh() {
    cecho debug "Ssh..."
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
        ssh "$jUser"@"$jIp" -p "$jPort"
    fi

    local user="root"
    if [[ $# -gt 1 ]] && [[ $2 != "" ]]; then
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

    local port="22"
    if [[ $# -gt 2 ]] && [[ $3 != "" ]]; then
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

    ssh "$user"@"$ip" -p "$port"
}
Log() {
    cecho warn "TODO"
}

# main
main() {
    if [[ $# -lt 1 ]]; then
        echo -n "Hello, "
        cecho greet "$username"
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
    test) Test "${@:2}" ;;
    *) Usage ;;
    esac
}


# main

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

main "$@"