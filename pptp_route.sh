#!/bin/bash - 
#===============================================================================
#
#          FILE: pptp_route.sh
# 
#         USAGE: ./pptp_route.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: lwq (28120), scue@vip.qq.com
#  ORGANIZATION: 
#       CREATED: Saturday, January 17, 2015 06:51:23 CST CST
#      REVISION:  ---
#===============================================================================

opt=$1                                          # on|off
host=./hosts_new
dev=$(ifconfig -s | grep -o 'ppp[0-9]\+')

case $opt in
    on|ON|On )
        act="add"                               # 添加路由
        ;;
    off|OFF|Off )
        act="del"                               # 删除路由
        ;;
    * )
        echo "未指定路由操作，退出"
        exit 1
        ;;
esac

# 配置路由，把指定的IP通过路由
if [[ "$dev" == "" ]] && [[ "$act" == "on" ]]; then
    echo "未连接VPN，不添加路由规则，退出"
    exit 1
else
    sed '/^#/d;/^$/d;/^0.0.0.0/d;/^127.0.0/d;' $host |\
        awk '{print $1}' | sort | uniq |\
            while read ip; do
                case $act in
                    add )
                        route add -host $ip dev $dev
                        ;;
                    del )
                        route del -host $ip
                        ;;
                esac
            done
    route -n
fi

# 配置网关，NAT转发pppX
case $act in
    add )
        iptables -C -t nat -A POSTROUTING -o $dev -j MASQUERADE || \
            iptables -t nat -A POSTROUTING -o $dev -j MASQUERADE
        ;;
    del )
        # TODO: 暂时还不知道如何去掉已存在的 iptables NAT转发规则，受限于 pppX 不确定
        echo "请阅读TODO"
        ;;
esac
