#!/bin/bash
export LANG="en_US.UTF-8"
apt-get update
apt-get install sudo

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
    
    local file_name=$(basename "$need_push_file_path")
    check_git_installation
    git config --global user.name "$user_name"
    git config --global user.email "$user_name@example.com"
    cd /usr || exit
    if [ -d "$repo_name" ]; then
        rm -r "$repo_name"
    fi
    mkdir "$repo_name"
    cd "$repo_name" || exit
    git init -b "$branch_name"
    git remote add origin https://"$user_name":"$token"@gitlab.com/"$user_name"/"$repo_name".git
    git pull origin "$branch_name"
    cp "$need_push_file_path" /usr/"$repo_name"/"$file_name"
    git add "$file_name"
    git commit -m "本次提交"
    git push -u origin "$branch_name"
    if [ $? -eq 0 ]; then
        echo -e "推送成功..."
    else
        echo -e "推送失败"
    fi
    cd ..
    rm -r "$repo_name"
}
push_file_to_gitlab
