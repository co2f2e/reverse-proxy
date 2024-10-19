#!/bin/bash
export LANG="en_US.UTF-8"
apt-get update
apt-get install sudo

check_git_installation() {
    if ! command -v git &>/dev/null; then
        echo -e "正在安装Git..."
        if [[ "$release" == "Debian" || "$release" == "Ubuntu" ]]; then
            sudo apt update
            sudo apt install git -y
        else
            sudo yum install -y git
        fi
    fi
}

push_file_to_gitlab() {
    local REPO_NAME=""   #仓库名
    local BRANCH_NAME="main"  #分支名
    local USER_NAME=""  #用户名
    local TOKEN="" #令牌
    local NEED_PUSH_FILE_PASH=""  #需要推送文件的全路径
    
    local FILE_NAME=$(basename "$NEED_PUSH_FILE_PASH")
    check_git_installation
    git config --global user.name "$USER_NAME"
    git config --global user.email "$USER_NAME@example.com"
    cd /usr || exit
    if [ -d "$REPO_NAME" ]; then
        rm -r "$REPO_NAME"
    fi
    mkdir "$REPO_NAME"
    cd "$REPO_NAME" || exit
    git init -b "$BRANCH_NAME"
    git remote add origin https://"$USER_NAME":"$TOKEN"@gitlab.com/"$USER_NAME"/"$REPO_NAME".git
    git pull origin "$BRANCH_NAME"
    cp "$NEED_PUSH_FILE_PASH" /usr/"$REPO_NAME"/"$FILE_NAME"
    git add "$FILE_NAME"
    git commit -m "本次提交"
    git push -u origin "$BRANCH_NAME"
    if [ $? -eq 0 ]; then
        echo -e "推送成功"
    else
        echo -e "推送失败"
    fi
    cd ..
    rm -r "$REPO_NAME"
}
push_file_to_gitlab
