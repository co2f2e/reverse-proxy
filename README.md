<h1 align="center">
  reverse-proxy
</h1>
使用脚本自动化配置Nginx，通过Nginx反向代理访问Github或Gitlab私有仓库中的文件，降低上手难度，修改方便

## 注意
* 已经申请了SSL证书，没有校验SSL证书和CA证书路径，若出现报错，会还原原来的配置
* 若状态码显示200，最后提示错误，请检查二级域名
* 若反代的文件中包含隐私数据，请不要允许浏览器访问
* Github私有仓库和Gitlab私有仓库已验证可用，Github只验证了精细化令牌
* 脚本功能不完善，不影响正常使用
* 输入二级域名时，会自动校验域名是否已经解析到该服务器，无论该服务器是否只有IPV4地址或IPV6地址
## 证书路径
### SSL证书
```bash
/root/domain.crt
/root/domain.key
```
### CA证书
```bash
/etc/ssl/certs/ca-certificates.crt
```
## 环境
Debian 11
## 运行
```bash
bash <(curl -Ls https://raw.githubusercontent.com/co2f2e/reverse-proxy/main/nginx_auto_config.sh)
```
