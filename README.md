<h1 align="center">
  使用说明
</h1>

* 已经申请了SSL证书，没有校验SSL证书和CA证书路径，若出现报错，会还原原来的配置
* 必须有github令牌，已验证精细化令牌
* 暂时只能使用github私有仓库，功能不全，持续更新中...
```shell
bash <(curl -Ls https://raw.githubusercontent.com/co2f2e/reverse-proxy/main/nginx_auto_config.sh)
```
