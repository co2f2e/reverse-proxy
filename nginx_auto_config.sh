#!/bin/bash

# 提示用户输入信息
read -p "请输入您二级域名: " DOMAIN
read -p "请输入令牌：" TOKEN

# 生成 Nginx 配置内容
nginx_config="
# 监听80端口，重定向到HTTPS
server {
    listen 80;
    server_name $DOMAIN;

    # 处理所有 HTTP 请求，重定向到 HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    # 公共配置
    
    # SSL 证书和私钥文件的路径
    ssl_certificate /root/$DOMAIN.crt;
    ssl_certificate_key /root/$DOMAIN.key;

    # SSL 配置（可根据需要进行调整）
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 启用 HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 设置 CA 证书
    proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt; 
    # 如果使用自签名证书或内部 CA，可以禁用 SSL 验证（生产环境不建议）
    proxy_ssl_verify on;   
    # 设置验证深度为 2
    proxy_ssl_verify_depth 2;

    # 添加 Token 到请求头
    proxy_set_header Authorization "token $TOKEN";

    # 保留原始 Host 请求头
    proxy_set_header Host api.github.com;

    # 其他代理设置
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # 启用 SNI（服务器名称指示）以使用正确的证书
    proxy_ssl_server_name on;
        
    # 指定 GitLab 的服务器名称
    proxy_ssl_name api.github.com;

    # 使用 HTTP/1.1 保持连接
    proxy_http_version 1.1;
    proxy_set_header Connection "keep-alive"; 

    # 设置更长的连接超时时间
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    # 防止缓存敏感数据
    proxy_cache_bypass $http_upgrade;

    proxy_set_header Accept "application/vnd.github.v3.raw";  # 直接获取文件的原始内容

    #第一个配置文件
    location /v2ray/ {
        # 禁止所有其他常见浏览器
        if ($http_user_agent ~* "Mozilla|Chrome|Safari|Opera|Edge|MSIE|Trident|Baiduspider|Yandex|Sogou|360SE|Qihoo|UCBrowser|WebKit|Bing|Googlebot|Yahoo|Bot|Crawler") {
            return 403;
        }
        # 反向代理到 GitLab API
        proxy_pass https://api.github.com/repos/co2f2e/subscription/contents/config/v2ray.txt;
    }

    #第二个配置文件
    location /clash/ {
        # 禁止所有其他常见浏览器
        if ($http_user_agent ~* "Mozilla|Chrome|Safari|Opera|Edge|MSIE|Trident|Baiduspider|Yandex|Sogou|360SE|Qihoo|UCBrowser|WebKit|Bing|Googlebot|Yahoo|Bot|Crawler") {
            return 403;
        }
        # 反向代理到 GitLab API
        proxy_pass https://api.github.com/repos/co2f2e/subscription/contents/config/clash.yaml;
    }

    #第三个配置文件
    location /singbox/ {
        # 禁止所有其他常见浏览器
        if ($http_user_agent ~* "Mozilla|Chrome|Safari|Opera|Edge|MSIE|Trident|Baiduspider|Yandex|Sogou|360SE|Qihoo|UCBrowser|WebKit|Bing|Googlebot|Yahoo|Bot|Crawler") {
            return 403;
        }
        # 反向代理到 GitLab API
        proxy_pass https://api.github.com/repos/co2f2e/subscription/contents/config/singbox.json;
    }
    
    #获取ip
    location /get-ip {
        default_type text/plain;
        return 200 "$remote_addr";
    }
}

# 拒绝通过 IP 访问
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;  # 这个表示匹配所有未被上面 server 块处理的请求
    return 444;
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;  # 这个表示匹配所有未被上面 server 块处理的请求

    # SSL 证书和私钥文件的路径
    ssl_certificate /root/$DOMAIN.crt;
    ssl_certificate_key /root/$DOMAIN.key;
    
    return 444;

}
"

# 备份原有的默认配置文件
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# 将新配置写入 default 文件
echo "$nginx_config" | sudo tee /etc/nginx/sites-available/default > /dev/null

# 测试 Nginx 配置是否正确
sudo nginx -t

# 如果配置无误，重新加载 Nginx
if [ $? -eq 0 ]; then
    echo "配置正确，重新加载 Nginx..."
    sudo systemctl reload nginx
    echo "Nginx 已重新加载并应用新的配置。"
else
    echo "Nginx 配置有错误，请检查后重试。"
    # 恢复备份的配置文件
    sudo cp /etc/nginx/sites-available/default.bak /etc/nginx/sites-available/default
fi
