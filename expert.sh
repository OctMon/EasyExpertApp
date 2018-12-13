## 计时
SECONDS=0

## 默认值
cd ..
project=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`
workspace="true"
scheme=$project
info="Info"
configuration="Release"

##========================根据实际情况修改(一般不用修改)========================
# workspace='false'
## TARGETS对应的Scheme 默认项目名称
# scheme="beta"
## TARGETS对应的plist 不需要加后缀 默认Info.plist
# info="Info-beta"
## 配置，默认Release
# configuration="Debug"
##=========================================================================

path_info_plist="$project/$info.plist"
bundle_build=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $path_info_plist`
path_export=build
path_archive="$path_export/$scheme-$bundle_build.xcarchive"
path_ipa=$path_export

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
    path_export_options="./EasyExpertApp/development.plist"
    elif [ $method = "2" ] ; then
    path_export_options="./EasyExpertApp/ad-hoc.plist"
    elif [ $method = "3" ] ; then
    path_export_options="./EasyExpertApp/app-store.plist"
    elif [ $method = "4" ] ; then
    path_export_options="./EasyExpertApp/enterprise.plist"
    else
    echo "参数错误"
    exit 1
    fi
fi
##==========================================================================

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

##==================================导出ipa==================================
xcodebuild  -exportArchive \
            -archivePath ${path_archive} \
            -exportPath ${path_ipa} \
            -exportOptionsPlist ${path_export_options}
##==========================================================================

echo "** 用时: ${SECONDS}s **"