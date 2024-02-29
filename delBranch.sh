#!/bin/bash

function isInclude(){
    target="$1"
    included_arr=($2)
    for item in "${included_arr[@]}"; do
        if [[ $target == *"$item"* ]]; then
            return 0;
            break
        fi
    done
	return 1;	     		   
}

echo "即将删除【" $(pwd) "】下的分支，请先找其他人备份好，以免误删！！！！";
echo " "

# 指定要删除的分支名称中需包含的字符（为空则不进行该过滤）
include_filters=$(echo ${1})

# 指定要排除的分支名称中需包含的字符（为空则不进行该过滤）
excluded_filters=$(echo ${2})

# 获取当前系统时间的秒数
current_time=$(date +%s)


# 计算一年前的时间戳
one_years_ago=$((current_time - 3600 * 24 * 365))

# 计算六个月前的时间戳
six_months_ago=$((current_time - 3600 * 24 * 180))

# 计算三个月前的时间戳
three_months_ago=$((current_time - 3600 * 24 * 90))

# 计算两个月前的时间戳
two_months_ago=$((current_time - 3600 * 24 * 60))

# 计算一个月前的时间戳
one_months_ago=$((current_time - 3600 * 24 * 30))

time_range=$(eval echo '$'${3})

echo "更新本地与远端的分支引用"

# 先更新分支引用，确保git branch -r拉取的分支信息，与远端仓库一致（有删除过分支会出现不一致的情况，导致不必要的遍历）
git remote update origin  --prune

echo "仓库更新完毕，开始筛选目标分支..."

branch_all="";
branch_merged="--merged origin/master";
branch_no_merged="--no-merged origin/master";

get_branch_rule=$(eval echo '$'${4})

# 待删除分支
del_branch_arr=()

# 获取(所有/已合并/未合并)的远程分支，并进行循环处理
for branch in `git branch -r ${get_branch_rule} | grep -v '\(release\|develop\|master\|main\)$'` ; do
    # 提取分支名称
    # simple_name=$(echo "$branch" | sed 's#.*origin/##')
    simple_name=${branch#*origin/}

    if [[ -n $excluded_filters ]]; then
        isInclude "$simple_name" "$excluded_filters"; # 包含返回0，不包含返回1
        if [[ $? -eq 0 ]]; then
            continue
        fi
    fi

    if [[ -n $include_filters ]]; then
        isInclude "$simple_name" "$include_filters"; # 包含返回0，不包含返回1
        if [[ $? -eq 1 ]]; then
            continue
        fi
    fi



    # 获取分支最后提交时间
    branch_timestamp=$(git show --format="%at" "$branch" | head -n1)

    # 根据实际需要选择 三个月前 $three_months_ago 两个月$two_months_ago  一个月前$one_months_ago  当前$current_time
    if [[ $branch_timestamp -lt $time_range ]]; then

        del_branch_arr+=($simple_name)
    fi

  done

echo -e "匹配到待删除远端分支：" ${#del_branch_arr[*]} "个:"
echo ${del_branch_arr[*]}
echo "5秒后开始执行删除...，如需取消，请ctrl+c中断执行"
sleep 5;
if [[ ${#del_branch_arr[*]} -ne 0 ]]; then
    for del_branch in "${del_branch_arr[@]}"; do
        echo -n "正在远端删除分支: $del_branch"

        # 删除本地分支，暂不启用
        # git branch -d "$del_branch"

        # 删除远程分支
        git push origin --delete "$del_branch"

        echo " √"
    done
    echo -e ${#del_branch_arr[*]} "清除完成\n"
    echo -e "如需删除本地分支，请执行：\n\ngit branch -d ${del_branch_arr[*]}\n\n"
fi


# if [[ ${#del_branch_arr[*]} -ne 0 ]]; then
#     # read -r -p "是否删除上述远端分支 [Y/n]?" isConfirm</dev/tty;
#     read -r -p "是否删除上述远端分支 [Y/n]?" isConfirm;