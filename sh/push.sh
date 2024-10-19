#!/bin/bash

export LANG="en_US.UTF-8"

apt-get update
apt-get install sudo

# 检查 git 包是否安装
check_git_installation() {
    if ! command -v git &>/dev/null; then
        echo -e "${yellow}正在安装Git...${nc}"
        if [[ "$release" == "Debian" || "$release" == "Ubuntu" ]]; then
            sudo apt update
            sudo apt install git -y
        else
            sudo yum install -y git
        fi
    fi
}

push_file_to_gitlab() {

    local repo_name=""
    local branch_name="main"
    local user_name=""
    local token=""
    local need_push_file_path=""
    
    # 获取要推送的文件名
    local file_name=$(basename "$need_push_file_path")

    check_git_installation

    # 配置Git全局用户信息
    git config --global user.name "$user_name"
    git config --global user.email "$user_name@example.com"
    
    cd /usr || exit

    if [ -d "$repo_name" ]; then
        rm -r "$repo_name"
    fi
    
    mkdir "$repo_name"
    cd "$repo_name" || exit
    
    # 初始化本地仓库，指定初始化时创建的分支名和GitLab分支名一致
    git init -b "$branch_name"
    
    # 设置远程仓库
    git remote add origin https://"$user_name":"$token"@gitlab.com/"$user_name"/"$repo_name".git
    
    # 拉取最新
    git pull origin "$branch_name"
    
    # 复制文件到仓库目录
    cp "$need_push_file_path" /usr/"$repo_name"/"$file_name"
    
    # 添加文件
    git add "$file_name"
    
    # 提交
    git commit -m "本次提交"
    
    # 推送到远程仓库的指定分支
    git push -u origin "$branch_name"
    
    # 检查命令执行结果
    if [ $? -eq 0 ]; then
        echo -e "推送成功..."
    else
        echo -e "推送失败"
    fi
    
    # 删除本地仓库
    cd ..
    rm -r "$repo_name"
}

# 主函数
push_file_to_gitlab