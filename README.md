<h1 align="center">
  reverse-proxy
</h1>
使用脚本自动化配置Nginx，通过Nginx反向代理访问Github或Gitlab私有仓库中的文件，降低上手难度，修改方便

## 前提
* 已经安装了Nginx,默认监听80，443，请确保端口没有被别的服务占用
* 已经申请了SSL证书，已存在CA证书

## 注意
* 脚本会自动获取SSL证书路径和CA证书路径，如果获取不到，退出脚本，如果有多条路径，会提示选择
* 若状态码显示200，表示能成功访问到私有仓库文件，只有当脚本运行完成，没有提示错误，正常退出，配置才生效
* 若反代的文件中包含隐私数据，请不要允许浏览器访问，否则会提示弹窗下载，导致数据泄露
* Github私有仓库和Gitlab私有仓库已验证可用，Github只验证了精细化令牌
* 输入二级域名时，会自动校验域名是否已经解析到该服务器，无论该服务器是否只有IPV4地址或IPV6地址
* 脚本功能不完善，不影响正常使用

## 说明
* 禁止浏览器访问，是通过USER-AGENT来判断实现的，并不是所有浏览器都不能访问，目前只判断了以下浏览器： 
  Mozilla,Chrome,Safari,Opera,Edge,MSIE,Trident,Baiduspider,Yandex,Sogou,360SE,Qihoo,UCBrowser,WebKit,Bing,Googlebot,Yahoo,Bot,Crawler
* 终端输出的URL，若选择了不允许浏览器访问，在如上的浏览器是无法打开的

## 证书路径

### 默认CA证书路径
```bash
/etc/ssl/certs/ca-certificates.crt
```
## 环境
Debian 11

## 运行
```bash
bash <(curl -Ls https://raw.githubusercontent.com/co2f2e/reverse-proxy/main/nginx_auto_config.sh)
```
## 持续更新中...
