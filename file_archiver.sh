#!/usr/bin/env bash

# =========================================== COPYRIGHT ===========================================
readonly SCRIPT_NAME="file_archiver.sh"                           # 脚本名称
readonly SCRIPT_DESC="文件归档工具"                         # 脚本名称
readonly SCRIPT_VERSION="1.0.0"                                   # 脚本版本
readonly SCRIPT_UPDATETIME="2022/03/14"                           # 最近的更新时间
readonly AUTHER_NAME="MengXinxin"                                 # 作者
readonly AUTHER_EMAIL="andy_m129@163.com"                         # 作者邮箱
readonly REAMDME_URL="https://github.com/AndyM129/ShellScriptTpl" # 说明文档
readonly SCRIPT_UPDATE_LOG='''
'''

# =========================================== GLOBAL CONST ===========================================
readonly MACOS_VER="$(/usr/bin/sw_vers -productVersion)"      # 当前 MacOS 版本，eg. 11.0.1
readonly TIMESTAMP=$(date +%s)                                # 当前时间戳，eg. 1617351251
readonly DATE=$(date -r "$TIMESTAMP" "+%Y-%m-%d %H:%M:%S")    # 当前时间，eg. 2021-04-02 16:14:11
readonly DATE_STAMP=$(date -r "$TIMESTAMP" "+%Y%m%d%H%M%S")   # 当前时间戳，eg. 20210402161411
readonly CURRENT_PATH=$(pwd)                                  # 当前所在路径
readonly SCRIPT_DIRPATH=$(dirname "$0")                       # 当前脚本的文件路径
readonly SCRIPT_BASENAME=$(basename "$0")                     # 当前脚本的文件名
readonly SCRIPT_BASENAME_WITHOUT_SUFFIX=${SCRIPT_BASENAME%.*} # 文件名（不含后缀）
readonly SCRIPT_BASENAME_SUFFIX=${SCRIPT_BASENAME##*.}        # 文件后缀

# =========================================== GLOBAL VARIABLES ===========================================
verbose="0"
debug="0"

# =========================================== GLOBAL FUNCTIONS ===========================================
echoDebug() { if [[ $verbose == "1" || $debug == "1" ]]; then echo "\033[1;2m$@\033[0m"; fi; } # debug 级别最低，可以随意的使用于任何觉得有利于在调试时更详细的了解系统运行状态的东东；
echoInfo() { echo "\033[1;36m$@\033[0m"; }                                                     # info  重要，输出信息：用来反馈系统的当前状态给最终用户的；
echoSuccess() { echo "\033[1;32m$@\033[0m"; }                                                  # success 成功，输出信息：用来反馈系统的当前状态给最终用户的；
echoWarn() { echo "\033[1;33m$@\033[0m"; }                                                     # warn, 可修复，系统可继续运行下去；
echoError() { echo "\033[1;31m$@\033[0m"; }                                                    # error, 可修复性，但无法确定系统会正常的工作下去;
echoFatal() { echo "\033[5;31m$@\033[0m"; }                                                    # fatal, 相当严重，可以肯定这种错误已经无法修复，并且如果系统继续运行下去的话后果严重。

# =========================================== HELP ===========================================
help() {
    echoInfo "脚本名称: $SCRIPT_NAME"
    echoInfo "功能简介: $SCRIPT_DESC"
    echoInfo "当前版本: $SCRIPT_VERSION"
    echoInfo "最近更新: $SCRIPT_UPDATETIME"
    echoInfo "作    者: $AUTHER_NAME <$AUTHER_EMAIL>"
    echoInfo "说明文档: $REAMDME_URL"
    echoInfo
    echoInfo "============================================================="
    echoInfo
    echoInfo "Usage:"
    echoInfo
    echoInfo "\t\$ sh $SCRIPT_NAME [-dvh] [command] [params...] [--Option [value] [-sub_option [value]]...]..."
    echoInfo
    echoInfo "Commands:"
    echoInfo "\tcommand1:\t命令1"
    echoInfo "\tcommand2:\t命令2"
    echoInfo
    echoInfo "Options:"
    echoInfo "\t--opt1:\t\t选项1"
    echoInfo "\t--opt2:\t\t选项2"
    echoInfo "\t--updatelog:\t脚本的更新日志"
    echoInfo "\t--version:\t当前脚本版本"
    echoInfo "\t--help:\t\t查看使用说明"
    echoInfo
    echoInfo "SubOptions:"
    echoInfo "\t-sub_opt1:\t子选项1"
    echoInfo "\t-sub_opt2:\t子选项2"
}

# =========================================== PROCESS ===========================================

process() {
    echoInfo "> 注释："
    echoDebug "> 📃 表示「普通文件」"
    echoInfo "> 📂 表示「普通文件夹」"
    echoSuccess "> 🗃  表示「待归档文件夹」"
    echoWarn "> 🗄  表示「已归档文件」"
    echoInfo
    echoInfo "开始处理..."
    echoInfo
    file_archiver_in_path $@
    echoSuccess
    echoSuccess "智能归档完成 !"
    echoSuccess
    exit 0
}

# 对传入的目录 进行智能归档
function file_archiver_in_path() {
    # 若传入的不是目录 则直接返回
    if [ -f "$1" ]; then
        echoWarn "📃 单纯的文件不需要归档：$1 "

    # 若符合「智能归档」条件，则对当前目录进行归档：IDE配置、Git工程、xcode工程、Flutter工程
    elif [ $(echo $(find $1 \
        -name ".idea" \
        -o -name ".gitignore" \
        -o -name "LICENSE" \
        -o -name "README.md" -o -name "readme.md" -o -name "README" \
        -o -name "*.git" -o -name "*.gitee" \
        -o -name "*.xcodeproj" -o -name "*.xcplugin" \
        -o -name "pubspec.yaml" \
        -maxdepth 1 | wc -l) | sed 's/ //g') -gt 0 ]; then
        echoSuccess "🗃  $1"

    # 若「没有目录」则不再遍历其中的文件
    elif [ $(echo $(find $1 -type d -maxdepth 1 | wc -l) | sed 's/ //g') -le 1 ]; then
        echoInfo "📂 $1"

    # 否则遍历其下的文件，并对目录文件 进行递归处理
    else
        echoInfo "📂 $1"
        for file in $(ls $1); do
            if [ -f "$1/$file" ]; then
                if [[ "$1/$file" == *".zip" ]] || [[ "$1/$file" == *".tar"* ]]; then
                    echoWarn "🗄  $1/$file"
                else
                    echoDebug "📃 $1/$file"
                fi
                continue
            fi
            file_archiver_in_path "$1/$file"
        done
    fi
}

# =========================================== MAIN ===========================================

main() {
    if [[ $1 && ${1:0:2} != "--" ]]; then
        while getopts "dvh" OPT; do
            case $OPT in
            d) debug="1" ;;
            v) verbose="1" ;;
            h) help="1" ;;
            ?)
                help
                exit 1
                ;;
            esac
        done
        shift $((OPTIND - 1))
    fi

    echoDebug
    echoDebug "======================== DATE ======================"
    echoDebug "$DATE"
    echoDebug
    echoDebug "======================== GLOBAL CONST ======================"
    echoDebug "\$MACOS_VER=$MACOS_VER"
    echoDebug "\$TIMESTAMP=$TIMESTAMP"
    echoDebug "\$DATE=$DATE"
    echoDebug "\$DATE_STAMP=$DATE_STAMP"
    echoDebug "\$CURRENT_PATH=$CURRENT_PATH"
    echoDebug "\$SCRIPT_DIRPATH=$SCRIPT_DIRPATH"
    echoDebug "\$SCRIPT_BASENAME=$SCRIPT_BASENAME"
    echoDebug "\$SCRIPT_BASENAME_WITHOUT_SUFFIX=$SCRIPT_BASENAME_WITHOUT_SUFFIX"
    echoDebug "\$SCRIPT_BASENAME_SUFFIX=$SCRIPT_BASENAME_SUFFIX"
    echoDebug
    echoDebug "======================== Command ======================"
    echoDebug "sh $0 $*"
    echoDebug
    echoDebug "======================== Parsing options ======================"
    commandParams=()
    currentOptionKey=""
    currentSubOptionKey=""
    currentCommandParamIndex=-1

    while [ -n "$1" ]; do
        case "$1" in
        --*)
            currentSubOptionKey=""
            currentOptionKey="${1:2}"
            currentOptionValue="$([[ -z $2 || ${2:0:1} == "-" ]] && echo '1' || echo $2)"
            eval ${currentOptionKey}='$currentOptionValue'
            echoDebug "\$$currentOptionKey=$currentOptionValue"
            shift $([[ -z $2 || ${2:0:1} == "-" ]] && echo 0 || echo 1)
            ;;
        -*)
            currentOptionKeyPrefix=$([ $currentOptionKey ] && echo "${currentOptionKey}_" || echo "")
            currentSubOptionKey="${currentOptionKeyPrefix}${1:1}"
            currentSubOptionValue=""
            while [[ -n "$2" && ${2:0:1} != "-" ]]; do
                shift
                currentSubOptionValue=$([[ -z $currentSubOptionValue ]] && echo "$1" || echo "$currentSubOptionValue $1")
            done
            if [[ -z $currentSubOptionValue ]]; then currentSubOptionValue="1"; fi
            echoDebug "\$$currentSubOptionKey=$currentSubOptionValue"
            eval ${currentSubOptionKey}='$currentSubOptionValue'
            shift $([[ -z $2 || ${2:0:1} == "-" ]] && echo 0 || echo 1)
            ;;
        *)
            let currentCommandParamIndex=$currentCommandParamIndex+1
            commandParams[$currentCommandParamIndex]=$1
            echoDebug "\$$currentCommandParamIndex=$1"
            # if $debug; then echoDebug "\$$currentCommandParamIndex=$1"; fi
            # echoSuccess "commandParams count=${#commandParams[@]}，items=${commandParams[@]}"
            ;;
        esac
        shift
    done
    unset -v currentOptionKey
    unset -v currentSubOptionKey
    unset -v currentCommandParamIndex

    echoDebug
    echoDebug "======================== Params ======================"
    currentParamIndex=1
    echoDebug "\$0=$0"
    for param in ${commandParams[@]}; do
        echoDebug "\$$currentParamIndex=$param"
        currentParamIndex=$(($currentParamIndex + 1))
    done
    unset -v currentParamIndex

    echoDebug "======================== GLOBAL VARIABLES ======================"
    echoDebug "debug=$debug"
    echoDebug "verbose=$verbose"
    echoDebug
    echoDebug "=============================================="
    echoDebug

    # 预制处理
    if [ $help ]; then
        help
        exit 0
    fi
    if [ $version ]; then
        echoInfo "$SCRIPT_VERSION"
        exit 0
    fi
    if [ $updatelog ]; then
        echoInfo "$SCRIPT_UPDATE_LOG"
        exit 0
    fi

    # 开始处理
    process ${commandParams[@]}
}

OLDIFS=$IFS
IFS=$'\n'
main $@
IFS=$OLDIFS
