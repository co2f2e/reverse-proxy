#!/bin/bash

clear

# 使用 which 命令检查 nginx 是否未安装
if ! which nginx > /dev/null 2>&1
then
    echo "还未安装nginx！"
    # 退出脚本
    exit 1
fi

# 检查nginx进程是否存在，不存在则启动nginx
if ! pgrep nginx > /dev/null 2>&1
then
    echo "nginx没有启动，正在启动..."
    sudo nginx
fi

read -p "请输入你的二级域名: " DOMAIN
read -p "请输入Github私有仓库令牌：" TOKEN
read -p "请输入反向代理配置的数量: " CONFIG_COUNT
read -p "请输入Github用户名：" USERNAME
read -p "请输入Github私有仓库名：" PROJECTNAME

# 创建一个临时文件来保存反向代理配置
TEMP_FILE=$(mktemp)

# 动态添加反向代理配置
for ((i=1; i<=CONFIG_COUNT; i++))
do
    read -p "请输入第 $i 个配置的路径（例如/test）： " LOCATION
    read -p "请输入第 $i 个配置的GitHub文件路径（例如/test.txt）： " FILE_PASS
    read -p "是否允许浏览器访问该文件？(y/n): " ALLOW_BROWSER_ACCESS

    # 检查用户输入是否允许浏览器访问
    if [[ "$ALLOW_BROWSER_ACCESS" == "y" || "$ALLOW_BROWSER_ACCESS" == "Y" ]]; then
        # 允许浏览器访问，不添加限制
        cat <<EOF >> "$TEMP_FILE"
    location $LOCATION/ {
        proxy_pass https://api.github.com/repos/$USERNAME/$PROJECTNAME/contents$FILE_PASS;
    }
EOF
    else
        # 禁止浏览器访问，添加限制
        cat <<EOF >> "$TEMP_FILE"
    location $LOCATION/ {
        if (\$http_user_agent ~* "Mozilla|Chrome|Safari|Opera|Edge|MSIE|Trident|Baiduspider|Yandex|Sogou|360SE|Qihoo|UCBrowser|WebKit|Bing|Googlebot|Yahoo|Bot|Crawler") {
            return 403;
        }
        proxy_pass https://api.github.com/repos/$USERNAME/$PROJECTNAME/contents$FILE_PASS;
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
    
    # SSL 证书和私钥文件的路径
    ssl_certificate /root/$DOMAIN.crt;
    ssl_certificate_key /root/$DOMAIN.key;

    # SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 启用 HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 设置 CA 证书
    proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt; 
    proxy_ssl_verify on;   
    proxy_ssl_verify_depth 2;

    # 添加 Token 到请求头
    proxy_set_header Authorization "token $TOKEN";
    proxy_set_header Host api.github.com;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_ssl_server_name on;
    proxy_ssl_name api.github.com;
    proxy_http_version 1.1;
    proxy_set_header Connection "keep-alive"; 
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
    proxy_cache_bypass \$http_upgrade;
    proxy_set_header Accept "application/vnd.github.v3.raw";  # 直接获取文件的原始内容

$(
    # 将临时文件内容导入到 nginx_config
    cat "$TEMP_FILE"
)
}

# 拒绝通过 IP 访问
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
