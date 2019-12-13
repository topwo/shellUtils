#!/bin/bash
CURRENT_DIR=$(cd $(dirname ${BASH_SOURCE}); pwd)

all_file_num=0
special_ini_file="${CURRENT_DIR}/fixFuncName.ini"
special_filename_file="${CURRENT_DIR}/special_filename.txt"
special_keyword_file="${CURRENT_DIR}/special_keyword.txt"
special_include_file="${CURRENT_DIR}/special_include.txt"
has_setting_file="${CURRENT_DIR}/setting_filename.txt"

###
#1、提取#########################################################################################################
###

#筛选所有文件名包含xi开头的，写入ini文件
function iniSpecialFile(){
	if [[ -f ${special_filename_file} ]];then
		cat ${special_filename_file} | while read file_path ;do
			echo "iniSpecialFile "${file_path}
			source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "Files" ${file_path//${sourceParentPath}/} ${file_path##*/}
		done
	fi
}

#筛选所有行中的关键字，并包含xi开头的，写入ini文件
function iniSpecialKeyword(){
	if [[ -f ${special_keyword_file} ]];then
		#剔除非关键字
		grep -o '[a-zA-Z0-9_][a-zA-Z0-9_]*' ${special_keyword_file} | grep "[^0-9]" | grep -i "^xi" > "tmp.txt" #(?![0-9])
		awk '!a[$0]++' "tmp.txt" | awk '{print $0" "length($0)}' | sort -n -k2 | awk '{print $1}' > ${special_keyword_file}
		rm -rf "tmp.txt"

		cat ${special_keyword_file} | while read line ;do
			source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "Keyword" $line $line
		done
	fi
}

#筛选所有include包含xi开头的，写入ini文件
function iniSpecialInclude(){
	if [[ -f ${special_include_file} ]];then
		sed -i '' 's/#include //g' ${special_include_file}
		sed -i '' 's/#import //g' ${special_include_file}
		sed 's/ //g' ${special_include_file} > "tmp.txt"
		awk '{print $0" "length($0)}' "tmp.txt" | sort -n -k2 | awk '{print $1}' > ${special_include_file}
		rm -rf "tmp.txt"
		cat ${special_include_file} | while read line ;do
			echo "iniSpecialInclude "${line}
			source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "_Include" ${line} ${line}
		done
	fi
}

#筛选所有文件名包含xi开头的,拥有build setting的，写入ini文件
function iniSpecialSetting(){
	if [[ -f ${has_setting_file} ]];then
		cat ${has_setting_file} | while read file_path ;do
			echo "iniSpecialSetting "${file_path}

			setting=`ruby "${CURRENT_DIR}/editProj.rb" "getBuildSetting" ${xcodeProjPath} ${xcodeTarget} ${file_path}`
			if [[ ${setting} != "" ]];then
				source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "COMPILER_FLAGS" ${file_path} ${setting}
			fi
		done
	fi
}

#记录本次提取的信息
function iniInfo(){
	source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "_Info" "useNum" 0
	source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "_Info" "sourceParentPath" ${sourceParentPath}
	source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "_Info" "xcodeTarget" ${xcodeTarget}
	source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "_Info" "xcodeProjPath" ${xcodeProjPath}
	source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "_Info" "affectPath" ${affectPath}
	source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "_Info" "sourcePath" ${sourcePath}
}

#如果是头文件要记录影响到的目录include的内容
function recordHeaderFileInclude(){
	if [[ $1 == *.h ]];then
		if [[ -d $2 ]] ;then #注意此处之间一定要加上空格，否则会报错
			for file in `ls $2` ;do #注意此处这是两个反引号，表示运行系统命令\
				if [[ $2 == */ ]]; then
					recordHeaderFileInclude $1 $2$file
				else
					recordHeaderFileInclude $1 $2"/"$file
				fi
			done
		elif [[ $2 == *.h ]] || [[ $2 == *.m ]] || [[ $2 == *.mm ]] || [[ $2 == *.c ]] || [[ $2 == *.cpp ]];then
			grep -i "#include[<> a-zA-Z0-9_.\"/]*$1" $2 >> ${special_include_file}
			grep -i "#import[<> a-zA-Z0-9_.\"/]*$1" $2 >> ${special_include_file}
		fi
	fi
}

#获取oc头文件声明的类名、变量名和函数名
function recordHeaderFileKeyword(){
	local file_path=$1
	if [[ $file_path == *.h ]];then
	    grep "^@.*$" $file_path | grep -v "^@end" >> ${special_keyword_file}
	    grep "^+.*$" $file_path >> ${special_keyword_file}
	    grep "^-.*$" $file_path >> ${special_keyword_file}
	    echo "" >> ${special_keyword_file}
	fi
}

#记录文件的路径
function fileHandle(){
	local file_path=$1
	if [[ -f ${file_path} ]]; then
		#记录文件
    	echo ${file_path} >> ${special_filename_file}

    	#记录头文件中想要的
		recordHeaderFileKeyword ${file_path}
		#检查是否有include这个文件的
		recordHeaderFileInclude ${file_path##*/} ${affectPath}

		#文件在项目中是否有特殊的配置
		setting=`ruby "${CURRENT_DIR}/editProj.rb" "getBuildSetting" ${xcodeProjPath} ${xcodeTarget} ${file_path}`
		if [[ ${setting} != "" ]];then
			echo ${file_path} >> ${has_setting_file}
		fi
	fi
}

#倒序搜索文件
function searchFileByReverseOrder(){
	local file_or_dir=$1
	if [[ -d $file_or_dir ]] ;then #注意此处之间一定要加上空格，否则会报错
		for file in `ls -r $file_or_dir` ;do #注意此处这是两个反引号，表示运行系统命令\
			if [[ $file_or_dir == */ ]]; then
				searchFileByReverseOrder $file_or_dir$file
			else
				searchFileByReverseOrder $file_or_dir"/"$file
			fi
		done
		source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "Dirs" ${file_or_dir//${sourceParentPath}/} ${file_or_dir##*/}
	else
		all_file_num=`expr $all_file_num + 1`
		fileHandle $file_or_dir
	fi
}

###
#2、应用#########################################################################################################
###

#修改oc
function modifyOC(){
	cocos2dPath=${affectPath%/*}
	cocos2dPath=${cocos2dPath%/*}
	JavaScriptObjCBridgePath="${cocos2dPath}/cocos2d-x/cocos/scripting/js-bindings/manual/platform/ios/JavaScriptObjCBridge.mm"
	search_content='const char* fixFuncName(const char *func_name){';
	search_content_format=${search_content//\*/\\\*}
	line=`sed -n "/${search_content_format}/=" ${JavaScriptObjCBridgePath}`
	if [[ ${line} == "" ]]; then
		echo "no"
		search_content='JS_BINDED_FUNC_IMPL(JavaScriptObjCBridge, callStaticMethod){';
		search_content_format=${search_content//\*/\\\*}
		cat "${CURRENT_DIR}/octemplate.mm" | while read replace_content; do
			line=`sed -n "/${search_content_format}/=" ${JavaScriptObjCBridgePath}`
			replace_content_format=${replace_content//\*/\\\*}
			sed -i '' "${line}i\\
			${replace_content_format}\\
			" ${JavaScriptObjCBridgePath}
		done
	fi
	sed -i '' 's/CallInfo call(.*/CallInfo call(fixFuncName(arg0.get()),fixFuncName(arg1.get()));/' ${JavaScriptObjCBridgePath}

	replace_content=""
	source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "Keyword"
	for (( i = 0; i < ${#dealIniReturnOptions[@]}; i++ )); do
		k_v=(${dealIniReturnOptions[i]})
		oldKeyword=${k_v[0]}
		newKeyword=${k_v[2]}
		if [[ ${replace_content} != "" ]]; then
			replace_content=${replace_content}","
		fi
		replace_content=${replace_content}"\\\\\""${oldKeyword}"\\\\\":\\\\\""${newKeyword}"\\\\\""
	done
	replace_content_format=${replace_content//\*/\\\*}

	search_content='NSString *class_method_str';
	search_content_format=${search_content//\*/\\\*}
	line=`sed -n "/^[	]*${search_content_format}/=" ${JavaScriptObjCBridgePath}`
	echo ${line}
	sed -i '' "${line}s/@.*/@\"{${replace_content_format}}\";/" ${JavaScriptObjCBridgePath}
	# content=${content//\@/\\\@}
	# content=${content//\{/\\\{}
	# content=${content//\}/\\\}}
	# content=${content//\"/\\\"}
	# content=${content//\;/\\\;}
}

#遍历目录替换字符
function replaceWords(){
	if [[ -d $1 ]] ;then #注意此处之间一定要加上空格，否则会报错
		for file in `ls $1` ;do #注意此处这是两个反引号，表示运行系统命令\
			if [[ $1 == */ ]]; then
				replaceWords $1$file $2 $3
			else
				replaceWords $1"/"$file $2 $3
			fi
		done
	elif ([[ $1 == *.h ]] || [[ $1 == *.m ]] || [[ $1 == *.mm ]] || [[ $1 == *.c ]] || [[ $1 == *.cpp ]]);then
		sed2=${2}
		sed3=${3}
		sed2=${sed2//\//\\\/}
		sed3=${sed3//\//\\\/}
		seds="s/${sed2}/${sed3}/g"
		sed -i '' ${seds} $1
	fi
}

#获取文件夹新的路径
function getDirNewPath(){
	local old_path=$1
	echo "old_path "${old_path}
	if [[ ${old_path} != "" ]];then
		local dealIniReturnValue=""
		source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "Dirs" ${old_path}
		local parent_path=${old_path%/*}
		if [[ ${parent_path} != ${old_path} ]] ;then
			getDirNewPath ${parent_path}
		fi
		get_dir_new_path_return=${get_dir_new_path_return}"/"${dealIniReturnValue}
	fi
}

#应用修改
function applyModify(){
	interNameOld=${sourcePath##*/}
	interNameNew=${interNameOld}

	#文件夹重命名为新的
	source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "Dirs"
	for (( i = 0; i < ${#dealIniReturnOptions[@]}; i++ )); do
		k_v=(${dealIniReturnOptions[i]})
		oldsrc=${k_v[0]}
		newName=${k_v[2]}

		get_dir_new_path_return=""
		getDirNewPath ${oldsrc%/*}
		oldsrc=${get_dir_new_path_return}"/"${oldsrc##*/}
		newsrc=${get_dir_new_path_return}"/"${newName}
		echo "get_dir_new_path_return "${get_dir_new_path_return}
		if [[ -d ${sourceParentPath}"/"${oldsrc} ]] && [[ ${oldsrc} != ${newsrc} ]];then
			mv -vf ${sourceParentPath}"/"${oldsrc} ${sourceParentPath}"/"${newsrc}
		fi
		if [[ ${interNameOld} == ${oldsrc##*/} ]];then
			interNameNew=${newName}
		fi
	done

	#文件重命名为新的
	iniOptionsFilesNew=()
	source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "Files"
	for (( i = 0; i < ${#dealIniReturnOptions[@]}; i++ )); do
		k_v=(${dealIniReturnOptions[i]})
		oldsrc=${k_v[0]}
		newFileName=${k_v[2]}
		oldFileName=${oldsrc##*/}
		get_dir_new_path_return=""
		getDirNewPath ${oldsrc%/*}
		newDir=${get_dir_new_path_return}
		iniOptionsFilesNew[i]="${oldsrc} = ${newDir}"/"${newFileName}"
		if [[ -f ${sourceParentPath}"/"${newDir}"/"${oldFileName} ]] && [[ ${oldFileName} != ${newFileName} ]];then
			mv -vf ${sourceParentPath}"/"${newDir}"/"${oldFileName} ${sourceParentPath}"/"${newDir}"/"${newFileName}
		fi
	done

	# #把新的文件夹和文件加到xcode项目中，并删除老的引用不到的文件夹和文件
	# echo "${affectPath} ${xcodeProjPath} ${xcodeTarget} ${interNameOld} ${interNameNew}"
	# ruby "${CURRENT_DIR}/editProj.rb" "editProj" ${affectPath} ${xcodeProjPath} ${xcodeTarget} ${interNameOld} ${interNameNew}

	#老的include修改为新的include的md5
	source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "_Include"
	for (( i = 0; i < ${#dealIniReturnOptions[@]}; i++ )); do
		k_v=(${dealIniReturnOptions[i]})
		oldInclude=${k_v[0]}
		for (( j = 0; j < ${#iniOptionsFilesNew[@]}; j++ )); do
			k_v=(${iniOptionsFilesNew[j]})
			oldsrc=${k_v[0]}
			newsrc=${k_v[2]}
			oldIncludeNoSign=${oldInclude//\"/}
			oldIncludeNoSign=${oldIncludeNoSign//..\//}
			if [[ ${oldsrc} != ${oldsrc//${oldIncludeNoSign}/} ]]; then
				notInclude=${oldsrc//${oldIncludeNoSign}/}
				get_dir_new_path_return=""
				getDirNewPath ${notInclude%/*}
				newNotInclude=${get_dir_new_path_return}
				newInclude0=${newsrc//${newNotInclude}/}
				newInclude0=${newInclude0#*/}
				newInclude=${oldInclude//${oldIncludeNoSign}/${newInclude0}}
				if [[ ${oldInclude} != ${newInclude} ]]; then
					newIncludeMd5="{"`echo -n ${newInclude} | md5`"}"
					echo "replaceWords ${affectPath} ${oldInclude} ${newIncludeMd5}"
					replaceWords ${affectPath} ${oldInclude} ${newIncludeMd5}
				fi
			fi
		done
	done

	#老的关键字修改为新的关键字的md5
	source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "Keyword"
	for (( i = 0; i < ${#dealIniReturnOptions[@]}; i++ )); do
		k_v=(${dealIniReturnOptions[i]})
		oldKeyword=${k_v[0]}
		newKeyword=${k_v[2]}
		if [[ ${oldKeyword} != ${newKeyword} ]]; then
			newKeywordMd5="{"`echo -n ${newKeyword} | md5`"}"
			echo "replaceWords ${affectPath} ${oldKeyword} ${newKeywordMd5}"
			replaceWords ${affectPath} ${oldKeyword} ${newKeywordMd5}
		fi
	done

	#新的include的md5修改为新的include
	source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "_Include"
	for (( i = 0; i < ${#dealIniReturnOptions[@]}; i++ )); do
		k_v=(${dealIniReturnOptions[i]})
		oldInclude=${k_v[0]}
		for (( j = 0; j < ${#iniOptionsFilesNew[@]}; j++ )); do
			k_v=(${iniOptionsFilesNew[j]})
			oldsrc=${k_v[0]}
			newsrc=${k_v[2]}
			oldIncludeNoSign=${oldInclude//\"/}
			oldIncludeNoSign=${oldIncludeNoSign//..\//}
			if [[ ${oldsrc} != ${oldsrc//${oldIncludeNoSign}/} ]]; then
				notInclude=${oldsrc//${oldIncludeNoSign}/}
				get_dir_new_path_return=""
				getDirNewPath ${notInclude%/*}
				newNotInclude=${get_dir_new_path_return}
				newInclude0=${newsrc//${newNotInclude}/}
				newInclude0=${newInclude0#*/}
				newInclude=${oldInclude//${oldIncludeNoSign}/${newInclude0}}
				if [[ ${oldInclude} != ${newInclude} ]]; then
					newIncludeMd5="{"`echo -n ${newInclude} | md5`"}"
					echo "replaceWords ${affectPath} ${newIncludeMd5} ${newInclude}"
					replaceWords ${affectPath} ${newIncludeMd5} ${newInclude}
				fi
			fi
		done
	done

	#新的关键字的md5修改为新的关键字
	source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "Keyword"
	for (( i = 0; i < ${#dealIniReturnOptions[@]}; i++ )); do
		k_v=(${dealIniReturnOptions[i]})
		oldKeyword=${k_v[0]}
		newKeyword=${k_v[2]}
		if [[ ${oldKeyword} != ${newKeyword} ]]; then
			newKeywordMd5="{"`echo -n ${newKeyword} | md5`"}"
			echo "replaceWords ${affectPath} ${newKeywordMd5} ${newKeyword}"
			replaceWords ${affectPath} ${newKeywordMd5} ${newKeyword}
		fi
	done

	# ruby "${CURRENT_DIR}/editProj.rb" "removeUnuse" ${xcodeProjPath} ${xcodeTarget}

	# #老的build file存在setting的加上
	# source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "COMPILER_FLAGS"
	# for (( i = 0; i < ${#dealIniReturnOptions[@]}; i++ )); do
	# 	k_v=(${dealIniReturnOptions[i]})
	# 	src=${k_v[0]}
	# 	setting=${k_v[2]}
	# 	oldsrc1=${src//${sourceParentPath}/}
	# 	get_dir_new_path_return=""
	# 	getDirNewPath ${oldsrc1%/*}
	# 	newsrc=${sourceParentPath}${get_dir_new_path_return}"/"${src##*/}
	# 	for (( j = 0; j < ${#iniOptionsFilesNew[@]}; j++ )); do
	# 		k_v=(${iniOptionsFilesNew[j]})
	# 		oldsrc=${k_v[0]}
	# 		if [[ ${oldsrc1} == ${oldsrc} ]]; then
	# 			newsrc=${sourceParentPath}${k_v[2]}
	# 			break
	# 		fi
	# 	done
	# 	ruby "${CURRENT_DIR}/editProj.rb" "setBuildSetting" ${xcodeProjPath} ${xcodeTarget} ${newsrc} ${setting}
	# done

	modifyOC
}

function main(){
	read -p "请输入模式[g是提取出来，s是设置回去]:" mode
	if [[ ${mode} == "g" ]]; then
		read -p "请输入提取的目录:" sourcePath
		if [[ ! -d ${sourcePath} ]]; then
			echo "目录不存在=>${sourcePath}"
			exit 1
		fi
		sourceParentPath=${sourcePath%/*}

		read -p "请输入引用到提取目录的最外层目录:" affectPath
		if [[ ${affectPath} == "" ]]; then
			echo "无效的目录=>${affectPath}"
			exit 1
		fi

		read -p "请输入.xcodeproj的完整路径:" xcodeProjPath
		if [[ ! -d ${xcodeProjPath} ]]; then
			echo ".xcodeproj不存在=>${xcodeProjPath}"
			exit 1
		fi

		read -p "请输入.xcodeproj里面对应的target:" xcodeTarget
		if [[ ${xcodeTarget} == "" ]]; then
			echo "无效的target=>${xcodeTarget}"
			exit 1
		fi

		rm -rf ${special_ini_file}
		if [[ -d $sourcePath ]];then
			searchFileByReverseOrder $sourcePath
		fi

		iniSpecialFile
		iniSpecialKeyword
		iniSpecialInclude
		iniSpecialSetting
		iniInfo
		rm -rf ${special_filename_file}
		rm -rf ${special_keyword_file}
		rm -rf ${special_include_file}
		rm -rf ${has_setting_file}
		echo "总共搜索了"$all_file_num"个文件"
	elif [[ ${mode} == "s" ]]; then
		dealIniReturnValue=""
		dealIniReturnOptions=()
		source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "_Info" "sourcePath"
		sourcePath=${dealIniReturnValue}
		source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "_Info" "affectPath"
		affectPath=${dealIniReturnValue}
		source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "_Info" "xcodeProjPath"
		xcodeProjPath=${dealIniReturnValue}
		source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "_Info" "xcodeTarget"
		xcodeTarget=${dealIniReturnValue}
		source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "_Info" "sourceParentPath"
		sourceParentPath=${dealIniReturnValue}
		source "${CURRENT_DIR}/dealIni.sh" ${special_ini_file} "_Info" "useNum"
		useNum=${dealIniReturnValue}
		if [[ ${useNum} > 0 ]]; then
			echo "已经设置回去了，不能重复设置回去，会造成未知后果，如果要强行再设置一遍，请修改配置中的useNum = 0"
			exit -1
		fi
		useNum=`expr ${useNum} + 1`
		echo ${useNum}
		source "${CURRENT_DIR}/dealIni.sh" -w ${special_ini_file} "_Info" "useNum" 1

		applyModify
	else
		echo "模式输入的不对"
		exit 1
	fi
}

main