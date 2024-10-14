#!/bin/bash

clear

# 使用 which 命令检查 nginx 是否未安装
if ! which nginx > /dev/null 2>&1; then
    echo "还未安装nginx！"
    exit 1
fi

# 检查nginx进程是否存在，不存在则启动nginx
if ! pgrep nginx > /dev/null 2>&1; then
    echo "nginx没有启动，正在启动..."
    sudo nginx
fi

while true; do
    echo "请选择私有仓库类型:"
    echo "1) Gitlab私有仓库"
    echo "2) Github私有仓库"
    read -p "请输入你的选择: " choice

    echo

    if [ "$choice" == "2" ]; then
        read -p "请输入你的二级域名: " DOMAIN
        read -p "请输入Github私有仓库令牌：" TOKEN
        read -p "请输入反向代理配置的数量: " CONFIG_COUNT
        read -p "请输入Github用户名：" USERNAME
        read -p "请输入Github私有仓库名：" PROJECTNAME
        break
    elif [ "$choice" == "1" ]; then
        read -p "请输入你的二级域名: " DOMAIN
        read -p "请输入Gitlab私有仓库令牌：" TOKEN
        read -p "请输入反向代理配置的数量: " CONFIG_COUNT
        read -p "请输入Gitlab用户名：" USERNAME
        read -p "请输入Gitlab私有仓库名：" PROJECTNAME
        break
    else
        clear
        echo "无效的选择，请输入1或2。"
        echo
    fi
done

# 根据不同选择赋值
if [ "$choice" == "1" ]; then
    PROXY_SET_HEADER_HOST="gitlab.com"
    PROXY_SSL_NAME="gitlab.com"
else
    PROXY_SET_HEADER_HOST="api.github.com"
    PROXY_SSL_NAME="api.github.com"
fi

# 创建一个临时文件来保存反向代理配置
TEMP_FILE=$(mktemp)

# 动态添加反向代理配置
for ((i=1; i<=CONFIG_COUNT; i++)); do
    read -p "请输入第 $i 个配置的路径（例如/test）： " LOCATION
    read -p "请输入第 $i 个配置的GitHub文件路径（例如/test.txt）： " FILE_PASS
    read -p "是否允许浏览器访问该文件？(y/n): " ALLOW_BROWSER_ACCESS

    # 根据选择生成不同的 proxy_pass URL
    if [ "$choice" == "1" ]; then
        # 保留第一个斜杠，之后的斜杠替换为 %2F
        FILE_PASS_CONVERTED=$(echo "$FILE_PASS" | sed 's@/@%2F@g' | sed 's@^%2F@/@')
        # Gitlab 私有仓库的 URL
        PROXY_URL="https://gitlab.com/api/v4/projects/$USERNAME%2F$PROJECTNAME/repository/files/$FILE_PASS_CONVERTED/raw?ref=main"
    elif [ "$choice" == "2" ]; then
        # Github 私有仓库的 URL
        PROXY_URL="https://api.github.com/repos/$USERNAME/$PROJECTNAME/contents$FILE_PASS"
    fi

    # 检查用户输入是否允许浏览器访问
    if [[ "$ALLOW_BROWSER_ACCESS" == "y" || "$ALLOW_BROWSER_ACCESS" == "Y" ]]; then
        cat <<EOF >> "$TEMP_FILE"
    location $LOCATION/ {
        proxy_pass $PROXY_URL;
    }
EOF
    else
        cat <<EOF >> "$TEMP_FILE"
    location $LOCATION/ {
        if (\$http_user_agent ~* "Mozilla|Chrome|Safari|Opera|Edge|MSIE|Trident|Baiduspider|Yandex|Sogou|360SE|Qihoo|UCBrowser|WebKit|Bing|Googlebot|Yahoo|Bot|Crawler") {
            return 403;
        }
        proxy_pass $PROXY_URL;
    }
EOF
    fi
done

# 开始构建 Nginx 配置
nginx_config=$(cat <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    # 公共配置
    ssl_certificate /root/$DOMAIN.crt;
    ssl_certificate_key /root/$DOMAIN.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt; 
    proxy_ssl_verify on;   
    proxy_ssl_verify_depth 2;

    proxy_set_header Authorization "token $TOKEN";
    proxy_set_header Host $PROXY_SET_HEADER_HOST;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_ssl_server_name on;
    proxy_ssl_name $PROXY_SSL_NAME;
    proxy_http_version 1.1;
    proxy_set_header Connection "keep-alive"; 
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
    proxy_cache_bypass \$http_upgrade;
EOF
)

# 如果选择的是 Github，添加 proxy_set_header Accept
if [ "$choice" == "2" ]; then
    nginx_config+=$'\n    proxy_set_header Accept "application/vnd.github.v3.raw";\n'
fi

nginx_config+=$'\n'
nginx_config+=$(cat "$TEMP_FILE")

nginx_config+=$'\n}\n'

# 拒绝通过 IP 访问
nginx_config+=$(cat <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _; 
    return 444;
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;
    ssl_certificate /root/$DOMAIN.crt;
    ssl_certificate_key /root/$DOMAIN.key;
    return 444;
}
EOF
)

# 删除临时文件
rm -f "$TEMP_FILE"

# 备份原有的默认配置文件
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# 将新配置写入 default 文件
echo "$nginx_config" | sudo tee /etc/nginx/sites-available/default > /dev/null

echo

# 测试 Nginx 配置是否正确
sudo nginx -t

# 如果配置无误，重新加载 Nginx
if [ $? -eq 0 ]; then
    sudo nginx -s reload 
    echo
    echo "配置正确,nginx已重新加载并应用新的配置!"
    echo
else
    # 恢复备份的配置文件
    sudo cp /etc/nginx/sites-available/default.bak /etc/nginx/sites-available/default
    sudo nginx -s reload
    echo
    echo "Nginx 配置有错误，请检查后重试，已恢复原有配置并应用!"
    echo
fi
