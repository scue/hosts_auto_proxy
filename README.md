About
=====

你想做一些Android相关的开发？

你想下载Android SDK/NDK或者整套Android Source？

没门了吧？

你想使用pptp连接VPN，却又不想所有的网络连接都通过VPN？

或者，如果你使用ssh来连接Proxy的话，那么这些源代码对你已不存在任何意义了。

Who
===

谁合适使用这里的工具？

在Linux下使用pptp来连接国外的VPN，并把这个pptp作为一个Gateway。

能明白了吗？

简单点说，你期望**把你的Linux作为一个自动穿越城墙的路由器**。

HowTo
=====

心动了吗？

一个良好的网络环境，对于开发者来说，可以让你事半功倍，这些一点也不假；

跟随我的步伐，开启畅快淋漓的网络旅途。

*   **购买一个按年付费的VPN**: 我不喜欢推荐，不过这个的确有必要，什么样的VPN好用自己搜索就好

*   **Linux上使用命令行连接VPN**: 多数情况下，Ubuntu Server可是没有图形界面的哦

        sudo apt-get install pptp-linux pptpd
        sudo pptpsetup --create proxy_name --server proxy_addr --username your_account --password your_passwd --encrypt --start

    简单吧，没有你想像中的那么复杂，比很多博客上介绍的操作可是简单多了，不过内核要支持ppp_mppe加密哦
    查看方法也很简单`lsmod | grep ppp_mppe`，一般情况下都是支持的拉！

*   **配置路由规则**: 嘿嘿，这个是重点

    细心的你，发现如果只要再执行一行命令:

        sudo route add default dev ppp0

    就可以让所有的网络都通过VPN来上网了，如果你是短暂的上上外网倒是无所谓啦；

    可是，你真的只有这么点需求吗？
    你应该让它变得更加智能一点，我们还是把这一条默认的路由去掉吧

        sudo route del default dev ppp0

    细心的你可能会发现，如果你单纯只想上Google.com，你从ip138.com得知它的IP是173.194.127.240，通过这一行命令：

        sudo route add -host 173.194.127.240 dev ppp0

    你可以畅通无阻的连接Google.com了。

    可是，有一点，你发现Google.com会解析到了 173.194.127.241 ？

    哇靠，这么难搞？
    所谓天无绝人之路，幸好我们的`/etc/hosts`这个文件，只要我们在这个文件加上一行

        173.194.127.240 www.google.com
    
    以后只要访问www.google.com就会解析到了 173.194.127.240 啦，是不是听起来很棒？！

    细心的你可能通过微信的极客范推荐文章上看到了这么一篇超牛的Hosts: [Hosts](http://chinageek-wordpress.stor.sinaapp.com/uploads/2014/07/hosts.txt#rd)
    这是我见过最详细的Hosts文件了，只要把这个Hosts追加到你的`/etc/hosts`文件，配置以httpseverywhere，很多网站都可以访问了！

    不过话说回来，我还是期望使用VPN来访问这些网站，觉得是速度和安全上的一些考虑吧

    现在**我们要把这个超牛的Hosts文件所有的IP都取出来，然后它们都经过 ppp0 这个Interface去访问**

    取出这些IP地址的方法：

        sed '/^#/d;/^$/d;/^0.0.0.0/d;/^127.0.0/d;' $host | awk '{print $1}' | sort | uniq

    添加至路由的方法：

        sudo route add -host $ip dev $dev

    **如果你期望自动配置这一切，使用这个项目的脚本即可**：

        cp hosts hosts_new
        sudo ./pptp_route.sh on  # on表示开启路由规则，默认从hosts_new中取得IP地址

    **如果你不想要这些规则了，或者VPN已经断开了，这么操作**：

        sudo ./pptp_route.sh off # off表示关闭这些路由规则，也是从hosts_new中取得IP地址

    如果你还想更加智能一点，在连接上vpn时开启这些路由规则

        sudo vi /etc/ppp/ip-up.d/route-traffic # 输入以下内容
        #!/bin/bash
        (cd /path/to/this_project_src && sudo sudo ./pptp_route.sh on)

    在关闭VPN时关闭这些规则

        sudo vi /etc/ppp/ip-down.d/route-traffic # 输入以下内容
        #!/bin/bash
        (cd /path/to/this_project_src && sudo sudo ./pptp_route.sh off)

    注意，不要忘记给 `/etc/ppp/ip-up.d/route-traffic` 和 `/etc/ppp/ip-down.d/route-traffic`可执行权限


*   **让Linux作为网关时，子网机器都能使用上VPN**: 嘿嘿，这个也是重点

    如果你的Linux已配置成了网关，有NAT转发，这个时候，你期望你的这些VPN连接的路由规则同样在子网中生效的话

    可以这么做，把从ppp0出去的包都做一个nat转发，这里只需要一行命令即可：

        sudo iptables -C -t nat -A POSTROUTING -o ppp0 -j MASQUERADE || \
            sudo iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE

    当然，我在脚本pptp_route.sh已经把这件事情帮你给做到了，Enjoy！

Summary
=======

写了那么多，来一个总结吧

    # 1. 克隆此项目
    cd ~
    git clone https://github.com/scue/hosts_auto_proxy.git ~/hosts_auto_proxy
    cp ~/hosts_auto_proxy/hosts ~/hosts_auto_proxy/hosts_new
    cat ~/hosts_auto_proxy/hosts_new | sudo tee -a /etc/hosts # 你可能需要手工删除重复内容

    # 2. 配置VPN
    sudo vi /etc/ppp/ip-up.d/route-traffic # 输入以下内容
    #!/bin/bash
    (cd /home/YOURNAME/hosts_auto_proxy && sudo sudo ./pptp_route.sh on)
    sudo vi /etc/ppp/ip-down.d/route-traffic # 输入以下内容
    #!/bin/bash
    (cd /path/to/this_project_src && sudo sudo ./pptp_route.sh off)

    sudo chmod +x /etc/ppp/ip-up.d/route-traffic
    sudo chmod +x /etc/ppp/ip-down.d/route-traffic 

    # 3. 连接VPN
    sudo apt-get install pptp-linux pptpd
    sudo pptpsetup --create proxy_name --server proxy_addr --username your_account --password your_passwd --encrypt --start

按步骤执行完这些命令，做你爱做的事情吧，哈哈！
