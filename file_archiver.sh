#!/usr/bin/env bash

# =========================================== COPYRIGHT ===========================================
readonly SCRIPT_NAME="file_archiver.sh"                         # 脚本名称
readonly SCRIPT_DESC="文件归档工具"                       # 脚本名称
readonly SCRIPT_VERSION="1.0.1"                                 # 脚本版本
readonly SCRIPT_UPDATETIME="2022/03/14"                         # 最近的更新时间
readonly AUTHER_NAME="MengXinxin"                               # 作者
readonly AUTHER_EMAIL="andy_m129@163.com"                       # 作者邮箱
readonly REAMDME_URL="https://github.com/AndyM129/FileArchiver" # 说明文档
readonly SCRIPT_UPDATE_LOG='''
### 2022/03/20: v1.0.1
* 修复「压缩文件解压后 带有路径」的问题

### 2022/03/15: v1.0.0
* 实现核心功能开发，包括：目录的递归遍历、工程文件的识别&归档、彩色日志的输出
* 支持参数控制 以删除被归档的源文件
* 补充使用说明 及文档

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
# 更多用法见：https://github.com/AndyM129/AMKShell/wiki/TipsForUse#%E9%A2%9C%E8%89%B2
echoDebug() { if [[ $verbose == "1" || $debug == "1" ]]; then echo "\033[1;2m$@\033[0m"; fi; } # debug 级别最低，可以随意的使用于任何觉得有利于在调试时更详细的了解系统运行状态的东东；
echoInfo() { echo "\033[1;36m$@\033[0m"; }                                                     # info  重要，输出信息：用来反馈系统的当前状态给最终用户的；
echoSuccess() { echo "\033[1;32m$@\033[0m"; }                                                  # success 成功，输出信息：用来反馈系统的当前状态给最终用户的；
echoWarn() { echo "\033[1;33m$@\033[0m"; }                                                     # warn, 可修复，系统可继续运行下去；
echoError() { echo "\033[1;31m$@\033[0m"; }                                                    # error, 可修复性，但无法确定系统会正常的工作下去;
echoFatal() { echo "\033[1;31m$@\033[0m"; }                                                    # fatal, 相当严重，可以肯定这种错误已经无法修复，并且如果系统继续运行下去的话后果严重。
echoInfoWithBg() { echo "\033[1;46;30m$@\033[0m"; }                                            # info  重要，输出信息：用来反馈系统的当前状态给最终用户的；

# =========================================== HELP ===========================================
help() {
    echoInfo
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
    echoInfo "\t\$ sh $SCRIPT_NAME [-dvh] <path> [--Option [value] [-sub_option [value]]...]..."
    echoInfo
    echoInfo "Options:"
    echoInfo "\t--list:\t\t仅筛查、显示可能的归档处理\n\t\t\t若未指定 --kof 或 --rof 选项时，默认添加该选项"
    echoInfo "\t--kof:\t\t即\"KeepOriginalFile\"，保留被归档的源文件"
    echoInfo "\t--rof:\t\t即\"RemoveOriginalFile\"，删除被归档的源文件"
    echoInfo "\t--updatelog:\t脚本的更新日志"
    echoInfo "\t--version:\t当前脚本版本"
    echoInfo "\t--help:\t\t查看使用说明"
    echoInfo
    #    echoInfo "SubOptions:"
    #    echoInfo "\t-sub_opt1:\t子选项1"
    #    echoInfo "\t-sub_opt2:\t子选项2"
    echoInfo
}

# =========================================== PROCESS ===========================================

process() {
    # 大标题
    echoInfo
    echoInfo "# 🗄  文件归档工具"
    echoInfo

    # 二级标题：当前模式
    if [ $kof ]; then
        echoInfo "## 📂 开始归档，并将保留原文件"
    elif [ $rof ]; then
        echoInfo "## 🗑  开始归档，并将删除原文件"
    else
        echoInfo "## 🔍 开始筛查，并将显示可能的归档处理"
    fi
    echoInfo

    # 输出说明
    echoInfo "> 注释："
    echoDebug "> 📃 表示「普通文件」"
    echoInfo "> 📂 表示「普通文件夹」"
    echoSuccess "> 🗃  表示「待归档文件夹」"
    echoWarn "> 🗄  表示「已归档文件」"
    echoInfo

    # 异常处理：若传入的不是目录 则直接返回
    if [ -f "$*" ]; then
        echoFatal "📃 单纯的文件不需要归档：$* "
        echoFatal
        exit 0
    fi

    # cd 到对应的路径，执行处理
    cd $1 || ! echoFatal "前往目录失败($?)：$1" || exit 1
    echoInfo "\`\`\`shell"
    file_archiver_in_path "$(dirname $(pwd))" "$(basename $(pwd))"
    echoInfo "\`\`\`"
    echoInfo

    # 执行结束
    if [ $sof ]; then
        echoInfo "✅ 智能归档已完成，并保留了相关源文件！"
    elif [ $rof ]; then
        echoInfo "✅ 智能归档已完成，并删除了相关源文件！"
    else
        echoInfo "✅ 智能归档已完成筛查，并显示可能的归档处理！"
    fi
    echoSuccess
    exit 0
}

# 对传入的目录 进行智能归档：dirname=$1，basename=$2
# echoWarn "file_archiver_in_path: dirname=$1, basename=$2"
function file_archiver_in_path() {
    # 若传入的不是目录 则直接返回
    if [ -f "$1/$2" ]; then
        echoWarn "📃 单纯的文件不需要归档：$1/$2 "

    # 若符合「智能归档」条件，则对当前目录进行归档：IDE配置、Git工程、xcode工程、Flutter工程
    elif [ $(echo $(find "$1/$2" \
        -name ".idea" \
        -o -name ".gitignore" \
        -o -name "LICENSE" \
        -o -name "README.md" -o -name "readme.md" -o -name "README" \
        -o -name "*.git" -o -name "*.gitee" \
        -o -name "*.xcodeproj" -o -name "*.xcplugin" -o -name "*.podspec" \
        -o -name "pubspec.yaml" \
        -maxdepth 1 | wc -l) | sed 's/ //g') -gt 0 ]; then
        file_archiving $@

    # 若符合「忽略归档」的条件，则对当前目录直接跳过：照片图库
    elif [[ "$2" == *".photoslibrary" ]]; then
        echoInfoWithBg "🏞  $1/$2"

    # 若「没有目录」则不再遍历其中的文件
    elif [ $(echo $(find "$1/$2" -type d -maxdepth 1 | wc -l) | sed 's/ //g') -le 1 ]; then
        echoInfo "📂 $1/$2    —— 其中有文件夹$(echo $(find "$1/$2" -type d -maxdepth 1 | wc -l) | sed 's/ //g')个 + 文件$(echo $(find "$1/$2" -type f -maxdepth 1 | wc -l) | sed 's/ //g')个"
        exit

    # 否则遍历其下的文件，并对目录文件 进行递归处理
    else
        echoInfo "📂 $1/$2    —— 其中有文件夹$(echo $(find "$1/$2" -type d -maxdepth 1 | wc -l) | sed 's/ //g')个 + 文件$(echo $(find "$1/$2" -type f -maxdepth 1 | wc -l) | sed 's/ //g')个"
        for file in $(ls "$1/$2"); do
            if [ -f "$1/$2/$file" ]; then
                if [[ "$file" == *".zip" ]] || [[ "$file" == *".tar"* ]]; then
                    echoWarn "🗄  $1/$2/$file"
                else
                    echoDebug "📃 $1/$2/$file"
                fi
                continue
            fi
            file_archiver_in_path "$1/$2" "$file"
        done
    fi
}

# 执行归档
# echoWarn "file_archiving: dirname=$1, basename=$2"
function file_archiving() {
    echoSuccess "🗃  $1/$2 ➡️  ${2}_fa${DATE_STAMP}.zip"

    # 若目标文件已存在，则直接返回
    if [[ -e "${1}/${2}_fa${DATE_STAMP}.zip" ]]; then
        return
    fi

    # 归档文件
    if [ $((${kof:-0} + ${rof:-0})) -gt 0 ]; then
        # 前往对应的目录
        cd "$1"
        if [ $? -gt 0 ]; then
            echo "前往目录失败($?)：$1"

        # 进行归档
        else
            zip -qr "${2}_fa${DATE_STAMP}" "$2"

            if [ $? -gt 0 ]; then
                echoError "文件压缩失败($?)"

            # 按需删除源文件
            elif [ $rof ]; then
                rm -rf "$2"
            fi
        fi
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

    # 必要参数校验：path
    if [ -z ${commandParams[0]} ]; then
        help
        exit 0
    fi

    # 必要参数校验：--kof、--rof、--list
    if [ $((${kof:-0} + ${rof:-0} + ${list:-0})) -gt 1 ]; then
        echoFatal "选项 --kof、--rof、--list 只能三选一，请勿同时指定多个"
        help
        exit 0
    elif [ $((${kof:-0} + ${rof:-0})) -eq 0 ]; then
        list=1
    fi

    # 开始处理
    process ${commandParams[@]}
}

OLDIFS=$IFS
IFS=$'\n'
main $@
IFS=$OLDIFS
