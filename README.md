<h1 align="center">
  reverse-proxy
</h1>
使用脚本自动化配置Nginx，通过Nginx反向代理访问Github或Gitlab私有仓库中的文件，降低上手难度，修改方便

## 注意
* 已经申请了SSL证书，没有校验SSL证书和CA证书路径，若出现报错，会还原原来的配置
* Github已验证精细化令牌
* 若状态码显示200，最后提示错误，请检查二级域名
* 若反代的文件中包含隐私数据，请不要允许浏览器访问
* Github私有仓库和Gitlab私有仓库已验证可用
* 脚本存在BUG,逻辑不严谨,不影响正常使用
## 证书路径
### SSL证书：
```bash
/root/domain.crt
/root/domain.key
```
### CA证书：
```bash
/etc/ssl/certs/ca-certificates.crt
```
## 环境
Debian 11
## 运行
```bash
bash <(curl -Ls https://raw.githubusercontent.com/co2f2e/reverse-proxy/main/nginx_auto_config.sh)
```
