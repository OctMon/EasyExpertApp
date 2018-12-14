## 计时
SECONDS=0

## 默认值
project=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`

##========================根据实际情况修改(一般不用修改)========================
## true or false
workspace="true"
## TARGETS对应的Scheme 默认项目名称
scheme=$project
# scheme=$project
## TARGETS对应的plist 不需要加后缀 默认Info.plist
info="Info"
## Release or Debug 默认Release
configuration="Release"
## 蒲公英APIKey  https://www.pgyer.com/account/api
pgyer_api_key=""
##=========================================================================

##================================选择打包方式================================
echo "\033[41;1m输入序号,选择打包方式,按回车继续 \033[0m"
echo "\033[31;1m1. development \033[0m"
echo "\033[32;1m2. ad-hoc      \033[0m"
echo "\033[33;1m3. app-store   \033[0m"
echo "\033[34;1m4. enterprise  \033[0m"
read parameter
method=$parameter
path_export_options=""
if [ -n $method ]
then
    if [ $method = "1" ] ; then
    path_export_options="development.plist"
    elif [ $method = "2" ] ; then
    path_export_options="ad-hoc.plist"
    elif [ $method = "3" ] ; then
    path_export_options="app-store.plist"
    elif [ $method = "4" ] ; then
    path_export_options="enterprise.plist"
    else
    echo "参数错误"
    exit 1
    fi
fi
##==========================================================================

path_build=build
path_archive="$path_build/$scheme.xcarchive"
 
##===================================归档====================================
if $is_workspace ; then
xcodebuild clean -workspace ${project}.xcworkspace \
                 -scheme ${scheme} \
                 -configuration ${configuration}

xcodebuild archive -workspace ${project}.xcworkspace \
                   -scheme ${scheme} \
                   -configuration ${configuration} \
                   -archivePath ${path_archive}
else
xcodebuild clean -project ${project}.xcodeproj \
                 -scheme ${scheme} \
                 -configuration ${configuration}

xcodebuild archive -project ${project}.xcodeproj \
                   -scheme ${scheme} \
                   -configuration ${configuration} \
                   -archivePath ${path_archive}
fi
##==========================================================================

path_info_plist="$project/$info.plist"
bundle_build=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $path_info_plist`

path_package="${path_build}/${scheme}_${bundle_build}"

##==================================导出ipa==================================
xcodebuild  -exportArchive \
            -archivePath ${path_archive} \
            -exportPath ${path_package} \
            -exportOptionsPlist ${path_export_options}
##==========================================================================

mv $path_archive $path_package

#上传到pgy
curl -F "file=@${path_package}/${scheme}.ipa" -F "_api_key=${pgyer_api_key}" -F "buildUpdateDescription=EasyExpertApp自动构建($bundle_build)" https://www.pgyer.com/apiv2/app/upload

echo
echo "** 上传完成 用时: ${SECONDS}s **"