#!/bin/bash

# bash <(curl -s "https://raw.githubusercontent.com/lqmx/script/master/ql.sh") i

now=$(date)
dateMd=$(date "+%m%d")

qlConfDir="$HOME/.ql"
qlCofigFile="$qlConfDir/config"
qlRcFile="$qlConfDir/rc"
qlIpFile="$qlConfDir/ip"
qlAliasFile="$qlConfDir/alias"
qlGroupFile="$qlConfDir/group"
qlMainScript="$qlConfDir/ql.sh"

if [[ -f $qlCofigFile ]]; then
    source $qlCofigFile
fi

if [[ -f $qlRcFile ]]; then
    source $qlRcFile
fi

if [[ -f $qlAliasFile ]]; then
    source $qlAliasFile
fi

# todo
# if [[ -f "$qlSourceDir/ql.sh" ]]; then
#     cp -f "$qlSourceDir"/ql.sh "$qlMainScript"
#     echo "ql.sh is copied to $qlMainScript"
# fi

divider() {
    printf "%60s" " " | tr ' ' '-' 
    echo
}

cEcho(){
    local exp=$1;
    local color=$2;
    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red|error) color=1 ;;
        green|success|path) color=2 ;;
        yellow|warning|required) color=3 ;;
        blue|info) color=4 ;;
        magenta) color=5 ;;
        cyan|option) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi
    tput setaf $color;
    echo -n $exp;
    tput sgr0;
}

qlCofigFileContent=$(cat <<-END
qlUsername=$username # 用户名
qlTemplatePath= # 模板路径
qlSourceDir= # 源代码路径
qlWpDir= # 工作目录
qlPbDir= # proto文件目录
qlHostDev= # 本地开发服务器地址
qlGitLab= # gitlab地址
qlDevIp= # 开发服务器ip
qlTestIp= # 测试服务器ip
qlTDevIp= # 开发服务器ip
qlTTestIp= # 测试服务器ip
qlSyncToolUser= # 同步用户
qlSyncToolDir= # 同步目录
qlDevUser= # 开发服务器用户
qlTestUser= # 测试服务器用户
qlTDevUser= # 开发服务器用户
qlTTestUser= # 测试服务器用户
qlDevPort= # 开发服务器端口
qlTestPort= # 测试服务器端口
qlTDevPort= # 开发服务器端口
qlTTestPort= # 测试服务器端口
qlJUser= # 跳板机用户
qlJPort= # 跳板机端口
qlJIp= # 跳板机ip
END
)

qlRcFileContent=$(cat <<-END
export HOST_DEV=$qlHostDev
export TEMPLATE_PATH=$qlTemplatePath
END
)

qlGroupFileContent=$(cat <<-END
# 多个服务用,分割
# 分组名称=服务1,服务2,服务3
END
)

qlAliasFileContent=$(cat <<-END
# https://git-scm.com/book/fr/v2/Les-bases-de-Git-Les-alias-Git
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.pl pull
git config --global alias.ph push
git config --global alias.unstage 'reset HEAD --'
END
)

usageInstallSimple="$(cEcho install info): i 安装"
usageInstall=$(cat <<-END
$(cEcho install info): i 安装
    $(cEcho "-f, --force" option): 强制安装
    eg: install -f
END
)
Install() {
    # options
    while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -h | --help ) echo "$usageInstall"  && exit 0 ;;
    -f | --force ) force=true ;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi

    if [[ $force == true ]]; then
        rm -rf "$qlConfDir"
    fi

    if [[ ! -d $qlConfDir ]]; then
        echo "mkdir $qlConfDir"
        mkdir $qlConfDir
    else
        echo "$HOME/.ql already exists. skip"
    fi

    if [[ ! -f $qlCofigFile ]]; then
        echo "init config"
        username=$(git config --global user.name)
        echo "$qlCofigFileContent" > $qlCofigFile
    else
        echo $(cEcho "$qlCofigFile already exists. skip" info)
    fi

    if [[ ! -f $qlRcFile ]]; then
        echo $(cEcho "init rc" info)
        echo $qlRcFileContent > $qlRcFile
    else
        echo $(cEcho "$qlRcFile already exists. skip" info)
    fi

    if [[ ! -f $qlGroupFile ]]; then
        echo $(cEcho "init group" info)
        echo $qlGroupFileContent > $qlGroupFile
    else
        echo $(cEcho "$qlGroupFile already exists. skip" info)
    fi

        

    if [[ ! -f $qlAliasFile ]]; then
        echo $(cEcho "init alias" info)
        echo $qlAliasFileContent > $qlAliasFile
    else
        echo $(cEcho "$qlAliasFile already exists. skip" info)
    fi

    #curl "https://raw.githubusercontent.com/lqmx/script/master/ql.sh" > $HOME/.ql/ql.sh
    if [[ ! -f $qlMainScript ]]; then
        echo $(cEcho "curl ql.sh" info)
        curl "https://raw.githubusercontent.com/lqmx/script/master/ql.sh" > $qlMainScript
        chmod +x $qlMainScript
    else
        echo $(cEcho  "$qlMainScript already exists, skip" info)
    fi

    if grep --quiet "alias i='qlMainScript'" $HOME/.bashrc; then
        echo $(cEcho "alias i already exists, skip" info)
    else
        echo "alias i='qlMainScript'" >> $HOME/.bashrc
        source $HOME/.bashrc
    fi
}

usageConfSimple="$(cEcho config info): c 配置"
usageConf=$(cat <<-END
$(cEcho config info): c 配置
    $(cEcho [配置名] option): 获取配置
    $(cEcho [配置名] option) $(cEcho [配置值] option): 设置配置
    eg: config username
        config username yourname
END
)
Config() {
     # options
    while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -h | --help ) echo "$usageConf"  && exit 0 ;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi

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
            echo $(cEcho "set config $1=$2" info)
            sed -i '' "s/^$1.*/$1=$2/" $HOME/.ql/config
        fi
    fi
}

usageGitPullSimple="$(cEcho gitpull info): gpl 拉取服务"
usageGitPull=$(cat <<-END
$(cEcho gitpull info): gpl 拉取服务
    $(cEcho "[服务名 多个用,隔开]" option): 拉取服务
    $(cEcho "[服务分组名 g开头,需要配置]" option)($(cEcho ${qlGroupFile} path)): 拉取服务组
    eg: gitpull
        gitpull service1,service2,service3
        gitpull group1
END
)
GitPull() {
    # options
    while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -h | --help ) echo "$usageGitPull"  && exit 0 ;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi


    if [[ $# -eq 0 ]]; then
        git pull
        exit 1
    fi

    local services=()
    if [[ $# -ge 1 ]]; then
        local str=$1
        if [[ $str == g* ]]; then
            if [[ -f $qlGroupFile ]]; then
                local group=$(grep ${str:1:${#str}}= $qlGroupFile)
                if [[ $group != "" ]]; then
                    echo ${group:3:${#group}}
                    services=($(echo ${group:3:${#group}} | cut -d= -f2 | tr ',' ' '))
                fi
                # IFS=', ' read -r -a services <<< ${group:3:${#group}}
            else
                echo $(cEcho "File: $qlGroupFile not found" error)
                exit
            fi
        else
            services=($(echo $str | cut -d= -f2 | tr ',' ' '))
        fi

        if [[ ${#services[@]} -eq 0 ]]; then
            echo $(cEcho "empty group" error)
            exit
        fi
    fi

    for service in "${services[@]}"; do
        echo $(cEcho "$service" info)

        divider
        if [[ -d "$qlWpDir/$service" ]]; then
            echo $(cEcho "client: $service => $qlWpDir/$service" info)
            echo
            cd "$qlWpDir/$service"
            git pull
        fi
        divider

        if [[ -d "$qlWpDir/$service"server ]]; then
            echo $(cEcho "server: $service => $qlWpDir/${service}server" info)
            echo
            cd "$qlWpDir/$service"server
            git pull
        fi
        echo
    done
}

usageGitCloneSimple="$(cEcho gitclone info): gcl 克隆服务"
usageGitClone=$(cat <<-END
$(cEcho gitclone info): gcl 克隆服务
    $(cEcho "(服务名 多个用,隔开)" required): 克隆服务
    eg: gitclone service1,service2,service3
END
)
GitClone() {
    # options
    while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -h | --help ) echo "$usageGitClone"  && exit 0 ;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi

    if [[ $# -eq 0 ]]; then
        echo $(cEcho "服务名不能为空 多个用,隔开" warning)
        exit 1
    fi

    local services=()
    if [[ $# -ge 1 ]]; then
        services=($(echo $1 | cut -d= -f2 | tr ',' ' '))
    fi

    if [[ ${#services[@]} -eq 0 ]]; then
        echo $(cEcho "服务名不能为空 多个用,隔开" error)
        exit;
    fi

    echo $(cEcho "services: ${services[*]}" info)

    for service in "${services[@]}"; do
        echo
        echo $(cEcho "$service" info)

        divider
        echo $(cEcho "client: $service => $qlWpDir/$service" info)
        if [[ ! -d "$qlWpDir/$service" ]]; then
            git clone $qlGitLab/$service.git $qlWpDir/$service
        else
            echo $(cEcho "$qlWpDir/$service already exists" warning)
        fi
        divider

        echo $(cEcho "server: $service => $qlWpDir/${service}server" info)
        if [[ ! -d "$qlWpDir/${service}server" ]]; then
            git clone $qlGitLab/${service}server.git $qlWpDir/${service}server
        else
            echo $(cEcho "$qlWpDir/${service}server already exists" warning)
        fi
        divider
    done
}

usageGitBranchSimple="$(cEcho gitbranch info): gbr 切换服务分支"
usageGitBranch=$(cat <<-END
$(cEcho gitbranch info): gbr 服务分支
    -n  使用输入的分支名称,否则会在分支名下加上日期
    $(cEcho "[分支名]" option) $(cEcho "[服务名 多个用,隔开]" option) 创建服务分支
    eg: gitbranch branchname
        gitbranch branchname service1,service2,service3 
END
)
GitBranch() {
    while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -h | --help ) echo "$usageGitBranch" && exit 0;;
    -n | --name )
        local isName=1
        ;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi


    if [[ $# -eq 0 ]]; then
        echo $(cEcho "分支名不能为空" warning)
        exit 1
    fi
    
    local branchName=$1
    if [[ $# -eq 1 ]]; then
        if [[ $isName != 1 ]]; then
            branchName="${dateMd}_${branchName}"
        fi
        # local gitName=$(git config --get remote.origin.url | sed 's/.*\///g')
        git checkout master || exit 1
        git pull origin master  || exit 1
        git checkout -b $branchName || exit 1
        git push --set-upstream origin $branchName || exit 1
        exit 0
    fi

    
    local services=($(echo $2 | cut -d= -f2 | tr ',' ' '))

    if [[ ${#services[@]} -eq 0 ]]; then
        echo $(cEcho "服务名不能为空 多个用,隔开" error)
        exit 1
    fi

    echo $(cEcho "分支名: $branchName" info)
    echo $(cEcho "服务名: ${services[*]}" info)

    for service in "${services[@]}"; do
        echo
        echo $(cEcho "$service" info)

        divider
        echo $(cEcho "server: $service => $qlWpDir/${service}server" info)
        if [[ ! -d "$qlWpDir/${service}server" ]]; then
            git clone $qlGitLab/${service}server.git $qlWpDir/${service}server
        else
            cd "$qlWpDir/${service}server"
            git checkout master
            git pull origin master
            git checkout -b $branchName
            git push --set-upstream origin $branchName
        fi
        divider
    done
}

#todo
GitPush() {
    echo $(cEcho "gitpush" info)
}

#todo
GitMerge() {
    echo $(cEcho "gitmerge" info)
}

#todo
Publish() {
    echo $(cEcho "publish" info)
}

#todo
Generate() {
    echo $(cEcho "generate" info)
}

usageRunSimple="$(cEcho run info): r 运行服务"
usageRun=$(cat <<-END
$(cEcho run info): r 运行服务
    $(cEcho "[服务名,没有则运行当前文件的服务]" option) 运行服务
    eg: run
        run service1
END
)
Run() {
    while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -h | --help ) echo "$usageRun" && exit 0;;
    -n | --name )
        local isName=1
        ;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi

    if [[ $1 != "" ]]; then
        local serviceName=$1
        cd "$qlWpDir/$serviceName"server
        console.sh run
    else
        console.sh run
    fi
}

usageBuildToolSimple="$(cEcho buildtool info): bt 生成工具"
usageBuildTool=$(cat <<-END
$(cEcho buildtool info): bt 生成工具
    $(cEcho "[服务名,没有则生成当前文件的服务]" option) $(cEcho "[os,默认系统,linux,windows,]" option)  $(cEcho "[同步的服务器,默认dev,dev,test,tdev,ttest]" option) 生成工具
    eg: buildtool
        buildtool service1
        buildtool service1 linux
        buildtool service1 linux test
END
)
BuildTool() {
    while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -h | --help ) echo "$usageBuildTool" && exit 0;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi

    local dirname=$(pwd | sed 's/.*\///')
    local serviceName=$(echo $dirname | sed 's/server//g')
    if [[ $1 != "" ]]; then
        serviceName=$1
    fi

    cd "$qlWpDir/$serviceName"server || echo $(cEcho "服务不存在" error) && exit 1

    if [[ $2 != "" ]]; then
        GOOS=$2 tools_builder -f "${serviceName}_tool.go"
    else
        tools_builder -f "${serviceName}_tool.go"
    fi

    if [[ $3 != "" ]]; then
        local ip=""
        if [[ $3 == "dev" ]]; then
            ip=$qlDevIp
        elif [[ $3 == "test" ]]; then
            ip=$qlTestIp
        elif [[ $3 == "tdev" ]]; then
            ip=$qlTDevIp
        elif [[ $3 == "ttest" ]]; then
            ip=$qlTTestIp
        else
            ip=$3
        fi
        echo scp "${serviceName}_tool" $qlSyncToolUser@"$ip":$qlSyncToolDir
        scp "${serviceName}_tool" $qlSyncToolUser@"$ip":$qlSyncToolDir
        rm "${serviceName}_tool" || exit 1
    fi
}

#todo
Pkg() {
    echo $(cEcho "pkg" info)
}

usageSyncSimple="$(cEcho sync info): s 同步服务,仅dev环境"
usageSync=$(cat <<-END
$(cEcho sync info): 同步服务,仅dev环境
    $(cEcho "[服务名]" option) $(cEcho "[分支名,为空是同步当前目录所在分支,如果分支有代码没提交会自动提交]" option)
    eg: sync service1
        sync service1 branchname
END
)
Sync() {
    while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -h | --help ) echo "$usageSync" && exit 0;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi

    local dirname=$(pwd | sed 's/.*\///')
    local serviceName=$(echo $dirname | sed 's/server//g')
    if [[ $1 != "" ]]; then
        serviceName=$1
    fi

    local currentBranch=$(git rev-parse --abbrev-ref HEAD)
    local branchName=$currentBranch
    if [[ $2 != "" ]]; then
        branchName=$2
    fi


    if [[ $branchName == $currentBranch ]]; then
       if [[ $(git status -s) != "" ]]; then
        sed -i "" "s/\(.*\)\/\/\(todo for dev.*\)/\/\/\1\/\/\2/g" go.mod 
        echo $(cEcho "有未提交的修改" warning)
        git commit -am "ok"
        git push
       fi
    fi

    echo $(cEcho "服务名: $serviceName" info)
    echo $(cEcho "分支名: $branchName" info)

    local filePath=$qlWpDir/${serviceName}server
    if [[ ! -d $filePath ]]; then
        echo $(cEcho "$filePath not exists" error)
        exit 1
    fi

    cd $filePath

    git checkout dev 
    git pull origin dev

    if [[ $branchName != "dev" ]] && [[ $branchName != "" ]]; then
        git merge "origin/$branchName" 

        local mergeConflictFiles=$(git diff --name-only --diff-filter=U)
        if [[ $mergeConflictFiles != "" ]]; then
            echo $(cEcho "合并冲突: $mergeConflictFiles" warning)
        fi
        for file in $mergeConflictFiles; do
            if [[ $file != "go.mod" ]] && [[ $file != "go.sum" ]]; then
                echo $(cEcho "合并冲突: $file" error)
                exit 1
            fi
            echo $(cEcho "解决冲突: $file" info)
            git checkout HEAD $file
        done
    fi

    rpc_gen -f UpdateAllMod || echo $(cEcho "UpdateMod失败" error) && exit 1
    console.sh sync || echo $(cEcho "同步失败" error) && exit 1

    if [[ $(git status | grep -c "nothing to commit") -eq 0 ]]; then
        git commit -am "ok"
        git push origin dev
    fi

    if [[ $branchName != "dev" ]] && [[ $branchName != "" ]]; then
        git checkout "$branchName" || echo $(cEcho "切换$branchName失败" error) && exit 1
        sed -i "" "s/\/\/\(.*\)\/\/\(todo for dev.*\)/\1\/\/\2/g" go.mod
    fi

    echo $(cEcho "同步成功" success)
}

#todo
UpdateMod() {
    echo $(cEcho "updatemodules" info)
}

#todo
Init() {
    echo $(cEcho "init" info)
}

usageSshSimple="$(cEcho ssh info): go 登录服务器"
usageSsh=$(cat <<-END
$(cEcho ssh info): go 登录服务器
    $(cEcho "[服务器,dev,test,tdev,ttest,j]" option)
    eg: ssh service1
END
)
Ssh() {
    while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -h | --help ) echo "$usageSshSimple" && exit 0;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi

    local ip=""
    if [[ $1 != "" ]]; then
        if [[ $1 == "dev" ]]; then
            ip=$qlDevIp
        elif [[ $1 == "test" ]]; then
            ip=$qlTestIp
        elif [[ $1 == "tdev" ]]; then
            ip=$qlTDevIp
        elif [[ $1 == "ttest" ]]; then
            ip=$qlTTestIp
        else
            ip=$1
        fi
    fi

    if [[ $ip == 'j' ]]; then
        ip=$qlJIp
        ssh $qlJUser@$qlJumpIp -p $qlJumpPort
    fi

    local user=""
    if [[ $2 != "" ]]; then
        if [[ $2 == "dev" ]]; then
            user=$qlDevUser
        elif [[ $2 == "test" ]]; then
            user=$qlTestUser
        elif [[ $2 == "tdev" ]]; then
            user=$qlTDevUser
        elif [[ $2 == "ttest" ]]; then
            user=$qlTTestUser
        else
            user=$2
        fi
    fi

    local port=""
    if [[ $3 != "" ]]; then
        if [[ $3 == "dev" ]]; then
            port=$qlDevPort
        elif [[ $3 == "test" ]]; then
            port=$qlTestPort
        elif [[ $3 == "tdev" ]]; then
            port=$qlTDevPort
        elif [[ $3 == "ttest" ]]; then
            port=$qlTTestPort
        else
            port=$3
        fi
    fi

    ssh $user@$ip -p $port

}

#todo
Log() {
    echo $(cEcho "log" info)
}

#todo
AddRpc() {
    echo $(cEcho "addrpc" info)
}

#todo
AddModelRpc() {
    echo $(cEcho "addmodelrpc" info)
}

usageSimple="$(cEcho help info): h 帮助"
usage=$(cat <<-END
Usage: $0 [command]

Commands:
    $usageSyncSimple

    $usageRunSimple

    $usageBuildToolSimple

    $usageSshSimple

    $usageInstallSimple

    $usageConfSimple

    $usageGitPullSimple

    $usageGitCloneSimple

    $usageGitBranchSimple

    $usageSimple
END
)
Help() {
    if [[ $# -eq 0 ]]; then
        echo "$usage"
        exit 0
    fi

    case "$1" in
        i | install)
            echo "$usageInstall"
            ;;
        c | config)
            echo "$usageConf"
            ;;
        gpl | gitpull)
            echo "$usageGitPull"
            ;;
        gcl | gitclone)
            echo "$usageGitClone"
            ;;
        gbr | gitbranch)
            echo "$usageGitBranch"
            ;;
        *)
            echo "$usage"
            exit 0
            ;;
    esac
}

case "$1" in
    i | install)
        shift
        Install $@
        ;;

    c | config)
        shift
        Config $@
        ;;

    h | help | -h | --help)
        shift
        Help $@
        exit
        ;;

    gitpull | gpl)
        shift
        GitPull $@
        ;;

    gitclone | gcl)
        shift
        GitClone $@
        ;;

    gitbranch | gbr)
        shift
        GitBranch $@
        ;;
    
    gitpush | gph)
        shift
        GitPush $@
        ;;
    
    publish | pub)
        shift
        Publish $@
        ;;

    generate | gen)
        shift
        Generate $@
        ;;

    run | r)
        shift
        Run $@
        ;;

    buildtool | bt)
        shift
        BuildTool $@
        ;;

    pkg)
        shift
        Pkg $@
        ;;

    sync | s)
        shift
        Sync $@
        ;;

    updatemod | um)
        shift
        UpdateMod $@
        ;;

    init)
        shift
        Init $@
        ;;

    ssh | go)
        shift
        Ssh $@
        ;;

    log)
        shift
        Log $@
        ;;

    addrpc | ar)
        shift
        AddRpc $@
        ;;

    addmodelrpc | amr)
        shift
        AddModelRpc $@
        ;;

    *)
        echo Hello, $(cEcho $qlUsername green) 
        echo $now
        ;;
esac

exit 0