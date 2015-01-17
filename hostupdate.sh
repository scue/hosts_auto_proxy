#!/bin/bash - 
#===============================================================================
#
#          FILE: hostupdate
# 
#         USAGE: ./hostupdate 
# 
#   DESCRIPTION: 实时更新自己电脑上的hosts，加速网络的访问。
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: linkscue(scue), 
#  ORGANIZATION: 
#       CREATED: 2013年08月10日 22时58分48秒 HKT
#      REVISION:  ---
#===============================================================================


ref_host_file=$1
new_host_file=$2
append_to_etc=${3:-"false"}

# fun: usage
usage(){
    echo -en "\e[0;31m" # color: red
    echo "==> Usage: $(basename $0) [ref_host_file]."
    echo -en "\e[0m"
    echo -en "\e[0;36m" # color: cyan
    echo "==> Example: $(basename $0) /etc/hosts"
    echo "  --> Result: 参照/etc/hosts中的信息，更新ip，临时保存: $new_host_file。"
    echo "==> Example: $(basename $0) /etc/hosts -y"
    echo "  --> Result: 参照/etc/hosts中的信息，更新ip，最后替换/etc/hosts。"
    echo -en "\e[0m"
    exit
}

# detect: help
if [[ $# -lt 2 ]]; then
    usage
else
    case ${1} in
        "-h" | "--help" | "-help" )
            usage
            ;;
    esac
fi

# 输出信息
info(){
    echo -e "\e[0;32m==> ${@}\e[0m"
}

# 输出次级信息
infosub(){
    echo -e "\e[0;36m  --> ${@}\e[0m"
}

# 输出提示
tip(){
    echo -e "\e[0;35m==> ${@}\e[0m"
}

# function
get_addr(){
    curl -sL http://www.ip138.com/ips1388.asp\?ip\=$1\&action\=1 |\
        grep -i $1 |grep -o '[0-9.]\+<'|awk -F'<' '{print $1}'
#   echo $(nslookup "$1" | sed '/^$/d' | sed -n '$p' | sed -n 's/Address: //gp')
}

# get root
rootopt=""
if [[ "$append_to_etc" != "false" ]]; then
    rootopt=sudo
    info "请输入root密码："
    $rootopt echo -n
fi

> $new_host_file

# 2. 更新hosts
tip "开始更新hosts文件"
cat $ref_host_file | while read line; do
    if [[ ${line:0:1} == '#' ]] || [[ ${#line} == 0 ]] \
        || [[ $(echo $line | grep '0.0.0.0') != "" ]] \
        || [[ $(echo $line | grep localhost) != "" ]] \
        || [[ $(echo $line | grep $HOSTNAME) != "" ]]; then
        echo $line | $rootopt tee -a $new_host_file
    else
        addr=$(echo $line|awk '{print $2}')
        link=""
        while [[ -z $link ]]; do
            link=$(get_addr $addr)
        done
        printf "%-19s%s\n" $link $addr | $rootopt tee -a $new_host_file
    fi
done

# 3. 追加至 /etc/hosts
if [[ "$append_to_etc" != "false" ]]; then
    cat $new_host_file | $rootopt tee -a /etc/hosts
else
    tip "更新hosts文件完毕，请把 $new_host_file 内容追加到 /etc/hosts"
fi
tip "全部操作完成，Enjoy!"
