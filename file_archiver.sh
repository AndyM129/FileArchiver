#!/usr/bin/env bash

# =========================================== COPYRIGHT ===========================================
readonly SCRIPT_NAME="file_archiver.sh"                         # 脚本名称
readonly SCRIPT_DESC="文件归档工具"                       # 脚本名称
readonly SCRIPT_VERSION="1.3.1"                                 # 脚本版本
readonly SCRIPT_UPDATETIME="2022/03/14"                         # 最近的更新时间
readonly AUTHER_NAME="MengXinxin"                               # 作者
readonly AUTHER_EMAIL="andy_m129@163.com"                       # 作者邮箱
readonly REAMDME_URL="https://github.com/AndyM129/FileArchiver" # 说明文档
readonly SCRIPT_UPDATE_LOG='''
### 2022/03/27: v1.3.1
* 智能归档优化：对于需要归档的文件夹，若其更新时间小于 其最近一次归档的时间，则不再重复归档

### 2022/03/27: v1.3.0
* 控制台日志 添加时间显示

### 2022/03/27: v1.2.0
* 支持添加 .faignore 以忽略对应目录

### 2022/03/20: v1.1.0
* 支持智能归档后 备份至指定路径

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
echoDebug() { if [[ $verbose == "1" || $debug == "1" ]]; then echo "\033[1;2m[$(date "+%Y/%m/%d %T")] $@\033[0m"; fi; } # debug 级别最低，可以随意的使用于任何觉得有利于在调试时更详细的了解系统运行状态的东东；
echoInfo() { echo "\033[1;36m[$(date "+%Y/%m/%d %T")] $@\033[0m"; }                                                     # info  重要，输出信息：用来反馈系统的当前状态给最终用户的；
echoSuccess() { echo "\033[1;32m[$(date "+%Y/%m/%d %T")] $@\033[0m"; }                                                  # success 成功，输出信息：用来反馈系统的当前状态给最终用户的；
echoWarn() { echo "\033[1;33m[$(date "+%Y/%m/%d %T")] $@\033[0m"; }                                                     # warn, 可修复，系统可继续运行下去；
echoError() { echo "\033[1;31m[$(date "+%Y/%m/%d %T")] $@\033[0m"; }                                                    # error, 可修复性，但无法确定系统会正常的工作下去;
echoFatal() { echo "\033[1;31m[$(date "+%Y/%m/%d %T")] $@\033[0m"; }                                                    # fatal, 相当严重，可以肯定这种错误已经无法修复，并且如果系统继续运行下去的话后果严重。

echoFile() { echo "[$(date "+%Y/%m/%d %T")] $@ "; }                     # 普通文件
echoDir() { echo "\033[1;36m[$(date "+%Y/%m/%d %T")] $@ \033[0m"; }     # 普通文件夹
#echoIgnore() { echo "\033[1;46;100m[$(date "+%Y/%m/%d %T")] $@ \033[0m"; }     # 被忽略文件
echoIgnore() { echo "\033[1;90m[$(date "+%Y/%m/%d %T")] $@ \033[0m"; }  # 普通文件夹
#echoIgnore() { echo "\033[7;36m[$(date "+%Y/%m/%d %T")] $@ \033[0m"; }    # 普通文件夹

echoZipping() { echo "\033[1;33m[$(date "+%Y/%m/%d %T")] $@ \033[0m"; } # 待压缩文件夹
#echoZipped() { echo "\033[1;43;30m[$(date "+%Y/%m/%d %T")] $@ \033[0m"; } # 已压缩文件夹
echoZipped() { echo "\033[4;33m[$(date "+%Y/%m/%d %T")] $@ \033[0m"; } # 待压缩文件夹

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

# =========================================== PROCESS ===¬========================================

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
    echoFile "> 📃 表示「普通文件」"
    echoDir "> 📂 表示「普通文件夹」"
    echoIgnore "> 📂 表示「忽略文件夹」，如 特殊文件夹、已归档且无更新"
    echoZipping "> 🗃  表示「待归档文件夹」"
    echoZipped "> 🗄  表示「已归档文件」"
    echoInfo

    # 获取原路径 的完整路径
    cd $1 || ! echoFatal "前往目录失败($?)：$1" || exit 1
    fromPath=$(pwd)
    echoInfo "归档文件夹：$fromPath"

    # 获取目标路径 的完整路径
    cd ${toPath:=$1} || ! echoFatal "前往目录失败($?)：$toPath" || exit 1
    toPath=$(pwd)
    echoInfo "  到文件夹：$toPath"
    echoInfo

    # cd 到对应的路径，执行处理
    echoInfo "\`\`\`shell"
    file_archiver_in_path "$(dirname $fromPath)" "$(basename $fromPath)" "$fromPath"
    echoInfo "\`\`\`"
    echoInfo

    # 执行结束
    if [ $kof ]; then
        echoSuccess "✅ 智能归档已完成，并保留了相关源文件！"
    elif [ $rof ]; then
        echoSuccess "✅ 智能归档已完成，并删除了相关源文件！"
    else
        echoSuccess "✅ 智能归档已完成筛查，并显示可能的归档处理！"
    fi
    echoSuccess
    exit 0
}

# 对传入的目录 进行智能归档 并按需移动：$1 源文件所在文件夹的完整路径（dirname），$2 源文件名称（basename），$3 源文件的完整路径
function file_archiver_in_path() {
    # 若需要忽略，则仅输出提示：相册
    if [[ "$3" == *".photoslibrary" ]]; then
        echoIgnore "🏞  $3"

    # 若需要忽略，则仅输出提示：其他
    elif [ $(echo $(find "$1/$2" -name "*.faignore" -maxdepth 1 | wc -l) | sed 's/ //g') -gt 0 ]; then
        echoIgnore "⏭  $3"

    # 若是文件，则先按需创建目标目录 并复制到该目录，再按需删除原文件
    elif [ -f "$3" ]; then
        # 无需创建目录
        if [ $fromPath == $toPath ]; then
            if [[ "$2" == *".zip" ]] || [[ "$2" == *".tar"* ]]; then
                echoZipped "🗄  $3"
            else
                echoFile "📃 $3"
            fi

        # 需要创建目标目录
        else
            if [[ "$2" == *".zip" ]] || [[ "$2" == *".tar"* ]]; then
                echoZipped "🗄  $3 ➡️  ${3/$fromPath/$toPath}"
            else
                echoFile "📃 $3 ➡️  ${3/$fromPath/$toPath}"
            fi

            # 按需移动
            if [ $((${kof:-0} + ${rof:-0})) -gt 0 ]; then
                if [ ! -e "$(dirname "${3/$fromPath/$toPath}")" ]; then
                    mkdir -p "$(dirname "${3/$fromPath/$toPath}")" || ! echoFatal "目录创建失败($?)：$(dirname "${3/$fromPath/$toPath}")" || exit 1
                fi
                cp "$3" "${3/$fromPath/$toPath}" || ! echoFatal "文件移动失败($?)：$3 => ${3/$fromPath/$toPath}" || exit 1

                # 按需删除源文件（若文件夹为空 则删除文件夹）
                if [ $rof ]; then
                    rm -rf "$3"
                    remove_empty_dir "$1"
                fi
            fi
        fi

    # 若是文件夹，且符合「智能归档」条件，则对当前目录先就地归档，并按需删除原文件；再按需创建目标目录 并复制到该目录，再按需删除原压缩文件
    elif [ $(echo $(find "$1/$2" \
        -name ".idea" \
        -o -name ".gitignore" \
        -o -name "LICENSE" \
        -o -name "README.md" -o -name "readme.md" -o -name "README" \
        -o -name "*.git" -o -name "*.gitee" \
        -o -name "*.xcodeproj" -o -name "*.xcplugin" -o -name "*.podspec" \
        -o -name "pubspec.yaml" \
        -o -name "index.html" \
        -maxdepth 1 | wc -l) | sed 's/ //g') -gt 0 ]; then

        # 已归档 且无更新，则无需再次归档
        if [ $(last_fa_timestamp $@) -gt $(last_update_timestamp $@) ]; then
            echoIgnore "🗃  $3 ➡️  $(last_fa_file $@)"

        # 正常归档文件夹
        else
            echoZipping "🗃  $3 ➡️  ${3/$fromPath/$toPath}_fa${DATE_STAMP}.zip"

            # 归档文件夹
            if [ $((${kof:-0} + ${rof:-0})) -gt 0 ]; then
                # 前往对应的目录
                cd "$1" || ! echo "前往目录失败($?)：$1" || exit 1

                # 就地进行归档
                zip -qr "${2}_fa${DATE_STAMP}.zip" "$2" || ! echo "文件压缩失败($?)：$2" || exit 1

                # 按需删除源文件
                if [ $rof ]; then
                    rm -rf "$2"
                fi

                # 按需移动
                if [ ! -e "$(dirname "${3/$fromPath/$toPath}")" ]; then
                    mkdir -p "$(dirname "${3/$fromPath/$toPath}")" || ! echoFatal "目录创建失败($?)：$(dirname "${3/$fromPath/$toPath}")" || exit 1
                fi
                cp "${2}_fa${DATE_STAMP}.zip" "$(dirname "${3/$fromPath/$toPath}")" || ! echoFatal "文件移动失败($?)：${2}_fa${DATE_STAMP}.zip => $(dirname "${3/$fromPath/$toPath}")" || exit 1
                rm -rf "${2}_fa${DATE_STAMP}.zip"
                remove_empty_dir "$1"
            fi
        fi

    # 空文件夹：按需备份，按需删除
    elif [ $(echo $(ls -l "$3" | wc -l) | sed 's/ //g') -le 1 ]; then
        # 无需创建目录
        if [ $fromPath == $toPath ]; then
            echoDir "📂 $3"

        # 需要创建目标目录
        else
            echoDir "📂 $3 ➡️  ${3/$fromPath/$toPath}"

            # 按需移动
            if [ $((${kof:-0} + ${rof:-0})) -gt 0 ]; then
                if [ ! -e "$(dirname "${3/$fromPath/$toPath}")" ]; then
                    mkdir -p "$(dirname "${3/$fromPath/$toPath}")" || ! echoFatal "目录创建失败($?)：$(dirname "${3/$fromPath/$toPath}")" || exit 1
                fi
                cp -r "$3" "${3/$fromPath/$toPath}" || ! echoFatal "文件夹移动失败($?)：$3 => ${3/$fromPath/$toPath}" || exit 1

                # 按需删除源文件（若文件夹为空 则删除文件夹）
                if [ $rof ]; then
                    rm -rf "$3"
                    remove_empty_dir "$1"
                fi
            fi
        fi

    # 否则 递归处理当前目录下的子文件
    else
        echoDir "📂 $3"
        for file in $(ls "$3"); do
            file_archiver_in_path "$1/$2" "$file" "$1/$2/$file"
        done
    fi
}

# 删除空文件夹：$1 目录的完整路径
function remove_empty_dir() {
    dir="$1/$2"
    while true; do
        if [ ! -e "$dir" ]; then
            break
        fi

        # 若是空目录，则删除
        if [ $(echo $(ls -l "$dir" | wc -l) | sed 's/ //g') -le 1 ]; then
            echoDebug "🗑  $dir"
            rm -r "$dir"
            dir=$(dirname "$dir")
            continue
        fi

        # 结束处理
        break
    done
}

# 上次更新的时间戳：$1 源文件所在文件夹的完整路径（dirname），$2 源文件名称（basename），$3 源文件的完整路径
# "—— 修改时间：$(stat -f%c "$3") => $(date -r $(stat -f%c "$3") "+%Y-%m-%d %H:%M:%S")"
function last_update_timestamp() {
    echo $(stat -f%c "$3")
}

# 上次更新的日期戳：$1 源文件所在文件夹的完整路径（dirname），$2 源文件名称（basename），$3 源文件的完整路径
# "—— 修改时间：$(stat -f%c "$3") => $(date -r $(stat -f%c "$3") "+%Y-%m-%d %H:%M:%S")"
function last_update_date_stamp() {
    echo $(date -r $(stat -f%c "$3") "+%Y-%m-%d %H:%M:%S")
}

# 上次归档的文件：$1 源文件所在文件夹的完整路径（dirname），$2 源文件名称（basename），$3 源文件的完整路径
function last_fa_file() {
    # 若目标文件夹 不存在，则直接返回
    if [[ ! -e "${1/$fromPath/$toPath}" ]]; then
        return
    fi

    # 返回搜搜结果
    echo "$(find "${1/$fromPath/$toPath}" -name "${2}_fa2*.zip" -maxdepth 1 | sort | tail -n 1)"
    return
}

# 上次归档的文件的时间戳：$1 源文件所在文件夹的完整路径（dirname），$2 源文件名称（basename），$3 源文件的完整路径
function last_fa_timestamp() {
    ############################################################################################################
    #    #    完整思路如下：
    #    #    Andys-MacBook-Pro-2018:B_1 mengxinxin$ find . -name "C_1_idea_fa2*.zip" -maxdepth 1
    #    #    ./C_1_idea_fa20220329210602.zip
    #    #    ./C_1_idea_fa20220329210639.zip
    #    #    Andys-MacBook-Pro-2018:B_1 mengxinxin$ find . -name "C_1_idea_fa2*.zip" -maxdepth 1 | tail -n 1
    #    #    ./C_1_idea_fa20220329210639.zip
    #
    #    lastUpdateTimestamp=$(stat -f%c "$3")                                 # 上次更新时间的 时间戳
    #    lastUpdateDateStamp=$(date -r "$lastUpdateTimestamp" "+%Y%m%d%H%M%S") # 上次更新时间的 日期戳
    #    lastFaFile=$(find "${1/$fromPath/$toPath}" -name "${2}_fa2*.zip" -maxdepth 1 | tail -n 1) # 上次归档的文件
    #    lastFaFileName=$(basename "$lastFaFile")                                                  # 上次归档的 文件名
    #    lastFaDateStamp=$(echo "$lastFaFileName" | grep -Eo "fa[0-9]{14}")                        # 上次归档的日期戳
    #    lastFaDateStamp=${lastFaDateStamp#fa}
    #    if [ -n "$lastFaDateStamp" ]; then
    #        lastFaDateString="${lastFaDateStamp:0:4}-${lastFaDateStamp:4:2}-${lastFaDateStamp:6:2} ${lastFaDateStamp:8:2}:${lastFaDateStamp:10:2}:${lastFaDateStamp:12:2}"
    #        lastFaTimestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "$lastFaDateString" +%s)
    #        echoZipping "原文件最近修改时间：$lastUpdateDateStamp => $lastUpdateTimestamp"
    #        echoZipping "最近备份时间：$lastFaFileName => $lastFaDateStamp => $lastFaDateString => $lastFaTimestamp"
    #    fi
    #    exit
    ############################################################################################################

    # 若没有 则直接返回
    lastFaFile=$(last_fa_file $@) # 上次归档的文件
    if [ -z "$lastFaFile" ]; then
        return
    fi

    # 提取日期戳：若没有 则返回
    lastFaFileName=$(basename "$lastFaFile")                           # 上次归档的文件 的名称
    lastFaDateStamp=$(echo "$lastFaFileName" | grep -Eo "fa[0-9]{14}") # 上次归档的文件 的日期戳
    lastFaDateStamp=${lastFaDateStamp#fa}
    if [ -z "$lastFaDateStamp" ]; then
        return
    fi

    # 将日期戳转成时间戳
    lastFaDateString="${lastFaDateStamp:0:4}-${lastFaDateStamp:4:2}-${lastFaDateStamp:6:2} ${lastFaDateStamp:8:2}:${lastFaDateStamp:10:2}:${lastFaDateStamp:12:2}"
    lastFaTimestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "$lastFaDateString" +%s)
    echo "$lastFaTimestamp"
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
