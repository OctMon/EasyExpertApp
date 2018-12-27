## 计时
SECONDS=0

## 默认值
project=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`

##========================根据实际情况修改(一般不用修改)========================
## true or false 默认true
is_workspace="true"
## 打包方式对应的TARGETS 默认项目名称
target_development=${project}
target_adhoc=${project}
target_appstore=${project}
target_enterprise=${project}
## TARGETS对应的plist 不需要加后缀 默认Info.plist
info_development="Info"
info_adhoc="Info"
info_appstore="Info"
info_enterprise="Info"
## Release or Debug 默认Release
configuration="Release"
## Bitcode开关 默认打开
compileBitcode=true
## 签名方式 默认自动签名，如果打包失败，先用Xcode打一次就正常了
signingStyle="automatic"
## 工作目录 build目录在.gitignore添加忽略
path_build="build"
## 自动修改build方式  不修改:none 跟随时间变化:date 自动加1:number
auto_build="number"
## pgyer APIKey  https://www.pgyer.com/account/api
pgyer_api_key=""
## fir APIKey  https://fir.im/apps
fir_api_token=""
##=========================================================================

##================================选择打包方式================================
if [ -n "$1" ]
then
    method="$1"
else
    echo "\033[41;1m输入序号,选择打包方式,按回车继续 \033[0m"
    echo "\033[31;1m1. development \033[0m"
    echo "\033[32;1m2. ad-hoc      \033[0m"
    echo "\033[33;1m3. app-store   \033[0m"
    echo "\033[34;1m4. enterprise  \033[0m"
    read parameter
    method=${parameter}
fi

target=""
info=""
methodStyle=""

if [ -n ${method} ]
then
    if [ ${method} = "1" ]
    then
        methodStyle="development"
        target=${target_development}
        info=${info_development}
    elif [ ${method} = "2" ]
    then
        methodStyle="ad-hoc"
        target=${target_adhoc}
        info=${info_adhoc}
    elif [ ${method} = "3" ]
    then
        methodStyle="app-store"
        target=${target_appstore}
        info=${info_appstore}
    elif [ ${method} = "4" ]
    then
        methodStyle="enterprise"
        target=${target_enterprise}
        info=${info_enterprise}
    else
        echo "参数错误"
        exit 1
    fi
fi

path_info_plist="${project}/${info}.plist"

if [ "${auto_build}" = "date" ]
then
    #跟随时间变化
    buildDate=$(date +%Y%m%d%H%M%S)
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildDate" "$path_info_plist"
elif [ "${auto_build}" = "number" ]
then
    #自动加1
    buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$path_info_plist")
    buildNumber=$(($buildNumber + 1))
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$path_info_plist"
fi
bundle_build=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ${path_info_plist}`
bundle_version=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ${path_info_plist}`

path_package="${path_build}/${target}_${bundle_build}"
path_archive="${path_package}/${target}.xcarchive"

path_export_options="${path_package}/ExportOptions.plist"

if [ -d "${path_package}" ]
then
    echo "目录${path_package}已存在"
else
    echo "创建目录${path_package}"
    mkdir -pv "${path_package}"
fi

funcExpertOptionFile() {
    if [ -f "$path_export_options" ]
    then
        rm -rf "$path_export_options"
    fi
    
    /usr/libexec/PlistBuddy -c "Add :compileBitcode bool $compileBitcode" "$path_export_options"
    /usr/libexec/PlistBuddy -c "Add :signingStyle string $signingStyle" "$path_export_options"
    /usr/libexec/PlistBuddy -c "Add :method string $methodStyle" "$path_export_options"
}

funcExpertOptionFile
##==========================================================================

##================================填写更新日志================================
path_update_log="${path_package}/UpdateLog.txt"

funcUpdateLog() {
    echo "输入更新日志"
    say "输入更新日志"

    if [ -n "${pgyer_api_key}" -o  -n "${fir_api_token}" ]
    then
        rm -rf "$path_update_log"
        touch "$path_update_log"
        vim "$path_update_log"

        count=1
        history=""

        for line in $(cat "$path_update_log")
        do
            history+="[${count}] ${line}.  "
            count=$[${count}+1]
        done
        
        update_log=${history}
        echo "更新日志:"
        echo ${update_log}
    fi
}

if [ -d "${path_build}" ]
then
    funcUpdateLog
else
    mkdir -pv "${path_build}"
    funcUpdateLog
fi
##==========================================================================

##===================================归档====================================
if $is_workspace
then
    xcodebuild clean -workspace ${project}.xcworkspace \
    -scheme ${target} \
    -configuration ${configuration}

    xcodebuild archive -workspace ${project}.xcworkspace \
    -scheme ${target} \
    -configuration ${configuration} \
    -archivePath ${path_archive}
else
    xcodebuild clean -project ${project}.xcodeproj \
    -scheme ${target} \
    -configuration ${configuration}

    xcodebuild archive -project ${project}.xcodeproj \
    -scheme ${target} \
    -configuration ${configuration} \
    -archivePath ${path_archive}
fi
##==========================================================================

if [ -d "${path_archive}" ]
then
    echo "** Finished archive. Elapsed time: ${SECONDS}s **"
    echo
else
    exit 1
fi

##==================================导出ipa==================================
xcodebuild  -exportArchive \
-archivePath ${path_archive} \
-exportPath ${path_package} \
-exportOptionsPlist ${path_export_options}
##==========================================================================

file_ipa="${path_package}/${target}.ipa"

if [ -f "${file_ipa}" ]
then
    echo "** Finished export. Elapsed time: ${SECONDS}s **"
    say "打包成功"
else
    exit 1
fi

echo

if [ -n "${pgyer_api_key}" ]
then
    #上传到pgyer
    echo "正在上传到pgyer..."
    echo
    curl -F "file=@${file_ipa}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=${update_log}      *https://github.com/OctMon/EasyExpertApp build(${bundle_build})*" https://www.pgyer.com/apiv2/app/upload
    echo
    say "上传pgyer成功"
    echo
fi

if [ -n "${fir_api_token}" ]
then
    #上传到fir
    echo "正在上传到fir..."
    echo
    fir publish "${file_ipa}" -T "${fir_api_token}" -c "${update_log}"
    echo
    say "上传fir成功"
    echo
fi

if [ -n "${pgyer_api_key}" -o  -n "${fir_api_token}" ]
then
    echo "** Finished upload. Elapsed time: ${SECONDS}s **"
    echo
    while [ "$confirmed" != "y" -a "$confirmed" != "Y" -a "$confirmed" != "n" -a "$confirmed" != "N" ]
    do
        read -p "删除${path_package}? (y/n):" confirmed
    done
    if [ "$confirmed" == "y" -o "$confirmed" == "Y" ]; then
        rm -rf ${path_package}
    fi

    unset confirmed
fi

echo

echo "--------------------------------------------------------------------------------"
echo
echo "[${bundle_build}] ${target} version ${bundle_version}"

while [ "$confirmed" != "y" -a "$confirmed" != "Y" -a "$confirmed" != "n" -a "$confirmed" != "N" ]
do
    read -p "提交版本变更到远程仓库? (y/n):" confirmed
done
if [ "$confirmed" == "y" -o "$confirmed" == "Y" ]
then
    echo
    git add "${path_info_plist}"
    git commit -m "[${bundle_build}] ${target} version ${bundle_version}"
    git push
fi

unset confirmed

echo
echo "--------------------------------------------------------------------------------"

echo

echo "--------------------------------------------------------------------------------"
echo "🎉  Congrats"

echo "🚀  ${target} (${bundle_build}) successfully published"
echo "📅  Finished. Elapsed time: ${SECONDS}s"
echo "🌎  https://github.com/OctMon/EasyExpertApp"
echo "👍  Tell your friends!"
echo "--------------------------------------------------------------------------------"

echo

if [ -f "${file_ipa}" ]
then
    open ${path_package}
fi
