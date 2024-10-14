<h1 align="center">
  使用说明
</h1>

* 已经申请了SSL证书，没有校验SSL证书和CA证书路径，若出现报错，会还原原来的配置
* Github已验证精细化令牌
* 若状态码显示200，最后提示错误，请检查二级域名
* 若反代的文件中包含隐私数据，请不要允许浏览器访问
* Github私有仓库和Gitlab私有仓库已验证可用
* 脚本存在BUG,逻辑不严谨,不影响正常使用
  
```shell
bash <(curl -Ls https://raw.githubusercontent.com/co2f2e/reverse-proxy/main/nginx_auto_config.sh)
```
