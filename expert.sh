## 计时
SECONDS=0

## 默认值
project=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`

##========================根据实际情况修改(一般不用修改)========================
## true or false
workspace="true"
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
## 蒲公英APIKey  https://www.pgyer.com/account/api
pgyer_api_key=""
##=========================================================================

##================================填写更新日志================================
rm -rf update_log
touch update_log
open update_log

read -p "更新日志(同一条日志不要有空格)写好后按回车继续 " answer

count=1
history=""
for line in $(cat update_log)
do
history+="[${count}] ${line}.  "
count=$[${count}+1]
done

rm -rf update_log
update_log=${history}
echo "更新日志:"
echo ${update_log}
##==========================================================================

##================================选择打包方式================================
echo "\033[41;1m输入序号,选择打包方式,按回车继续 \033[0m"
echo "\033[31;1m1. development \033[0m"
echo "\033[32;1m2. ad-hoc      \033[0m"
echo "\033[33;1m3. app-store   \033[0m"
echo "\033[34;1m4. enterprise  \033[0m"
read parameter
method=${parameter}
path_export_options=""
target=""
info=""
if [ -n ${method} ]
then
if [ ${method} = "1" ] ; then
path_export_options="development.plist"
target=${target_development}
info=${info_development}
elif [ ${method} = "2" ] ; then
path_export_options="ad-hoc.plist"
target=${target_adhoc}
info=${info_adhoc}
elif [ ${method} = "3" ] ; then
path_export_options="app-store.plist"
target=${target_appstore}
info=${info_appstore}
elif [ ${method} = "4" ] ; then
path_export_options="enterprise.plist"
target=${target_enterprise}
info=${info_enterprise}
else
echo "参数错误"
exit 1
fi
fi
##==========================================================================

path_build=build
path_archive="${path_build}/${target}.xcarchive"

##===================================归档====================================
if $is_workspace ; then
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

if [ -d "${path_archive}" ] ; then
echo "** Finished archive. Total time: ${SECONDS}s **"
echo
else
exit 1
fi

path_info_plist="${project}/${info}.plist"
bundle_build=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ${path_info_plist}`

path_package="${path_build}/${target}_${bundle_build}"

##==================================导出ipa==================================
xcodebuild  -exportArchive \
-archivePath ${path_archive} \
-exportPath ${path_package} \
-exportOptionsPlist ${path_export_options}
##==========================================================================

mv $path_archive $path_package

file_ipa="${path_package}/${target}.ipa"

if [ -f "${file_ipa}" ] ; then
echo "** Finished export. Total time: ${SECONDS}s **"
echo
else
exit 1
fi

if [ -n "${pgyer_api_key}" ] ; then
#上传到pgyer
curl -F "file=@${file_ipa}" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=${update_log}      *https://github.com/OctMon/EasyExpertApp build(${bundle_build})*" https://www.pgyer.com/apiv2/app/upload
echo
echo
echo "** Finished upload. Total time: ${SECONDS}s **"
else
echo "** 如果需要上传到pgyer 请填写蒲公英APIKey  https://www.pgyer.com/account/api **"
open ${path_package}
fi

echo
