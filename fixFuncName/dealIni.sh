#该脚本必须用 source 命令 而且结果获取为${var}获取，不是return 如：source readIni.sh 否则变量无法外传
# dealIni.sh dealIniParamFile dealIniParamSection dealIniParamOption
# read
# param[1] : dealIniParamFile
# returm sections (element: section ) --- a str[]
# use: arr_length=${#dealIniReturnSections[*]}}  element=${dealIniReturnSections[0]}

# param[2] : dealIniParamFile dealIniParamSection
# return options (element: option = value) --- a str[]
# use: arr_length=${#dealIniReturnOptions[*]}}  element=${dealIniReturnOptions[0]}

# param[3] : dealIniParamFile dealIniParamSection dealIniParamOption
# return value --- a str
# use: ${dealIniReturnValue}

# write
# param : -w dealIniParamFile dealIniParamSection dealIniParamOption dealIniParamValue
# add new dealIniParamSection dealIniParamOption
# result:if not--->creat, have--->update, exist--->do nothing
# dealIniParamOption ,dealIniParamValue can not be null
 
#params
dealIniParamFile=$1
dealIniParamSection=$2
dealIniParamOption=$3
#sun
dealIniParamMode="iniR"
echo $@ | grep "\-w" >/dev/null&&dealIniParamMode="iniW"
if [ "$#" = "5" ]&&[ "$dealIniParamMode" = "iniW" ];then
   dealIniParamFile=$2
   dealIniParamSection=$3
   dealIniParamOption=$4
   dealIniParamValue=$5
   #echo $dealIniParamFile $dealIniParamSection $dealIniParamOption $dealIniParamValue
fi

function dealIniCheckIniFile()
{
    if [ "${dealIniParamFile}" = ""  ] || [ ! -f ${dealIniParamFile} ];then
        echo "[error]:file:${dealIniParamFile} not exist!"
        touch ${dealIniParamFile}
    fi
}
 
function dealIniReadIniFile()
{
    #检查文件
    dealIniCheckIniFile
    if [ "${dealIniParamSection}" = "" ];then
        #通过如下两条命令可以解析成一个数组
        dealIniLocalAllSections=$(awk -F '[][]' '/\[.*]/{print $2}' ${dealIniParamFile})
        dealIniReturnSections=(${dealIniLocalAllSections// /})
        echo "[info]:dealIniReturnSections size:[${#dealIniReturnSections[@]}]"
        # echo ${dealIniReturnSections[@]}
    elif [ "${dealIniParamSection}" != "" ] && [ "${dealIniParamOption}" = "" ];then
        #判断dealIniParamSection是否存在
        dealIniLocalAllSections=$(awk -F '[][]' '/\[.*]/{print $2}' ${dealIniParamFile})
        echo $dealIniLocalAllSections|grep ${dealIniParamSection}
        if [ "$?" = "1" ];then
            echo "[error]:dealIniParamSection:[${dealIniParamSection}] not exist!"
            return 0
        fi
        #正式获取options
        #a=(获取匹配到的dealIniParamSection之后部分|去除第一行|去除空行|去除每一行行首行尾空格|将行内空格变为@G@(后面分割时为数组时，空格会导致误拆))
        a=$(awk "/\[${dealIniParamSection}\]/{a=1}a==1"  ${dealIniParamFile}|sed -e '1d' -e '/^$/d' -e "s/[ 	]*$//g" -e "s/^[ 	]*//g" -e 's/[ ]/@G@/g' -e '/\[/,$d' )
        b=(${a})
        for i in ${b[@]};do
			#剔除非法字符，转换@G@为空格并添加到数组尾
			if [ -n "${i}" ]||[ "${i}" i!= "@S@" ];then
				dealIniReturnOptions[${#dealIniReturnOptions[@]}]=${i//@G@/ }
			fi
        done
        echo "[info]:dealIniParamSection:[${dealIniParamSection}] dealIniReturnOptions size:[${#dealIniReturnOptions[@]}]"
        # echo ${dealIniReturnOptions[@]}
    elif [ "${dealIniParamSection}" != "" ] && [ "${dealIniParamOption}" != "" ];then
 
        # dealIniReturnValue=`awk -F '=' '/\['${dealIniParamSection}'\]/{a=1}a==1&&$1~/'${dealIniParamOption}'/{print $2;exit}' $dealIniParamFile|sed -e 's/^[ \t]*//g' -e 's/[ \t]*$//g'`
        # awk 找出出 dealIniParamSection 之后的内容
        # sed 条件1：去除第一行 条件2：去除空行 条件3：去除其他dealIniParamSection的内容 条件4：去除不匹配${key}=的行 条件5：将${key}=字符剔除
        dealIniParamOption=${dealIniParamOption//\//\\\/}
        dealIniReturnValue=`awk -F '=' "/\[${dealIniParamSection}\]/{a=1}a==1" ${dealIniParamFile}|sed -e '1d' -e '/^$/d' -e '/^\[.*\]/,$d' -e "/^${dealIniParamOption} =.*/!d" -e "s/^${dealIniParamOption}.*= *//"`
        echo "[info]:dealIniParamSection:[${dealIniParamSection}] dealIniParamOption:[${dealIniParamOption}] dealIniReturnValue value:[${dealIniReturnValue}]"
    fi
}
 
function dealIniWriteIniFile()
{
    #检查文件
    dealIniCheckIniFile
    dealIniLocalAllSections=$(awk -F '[][]' '/\[.*]/{print $2}' ${dealIniParamFile})
    dealIniLocalSections=(${dealIniLocalAllSections// /})
    #判断是否要新建dealIniParamSection
    dealIniParamSectionFlag="0"
    for temp in ${dealIniLocalSections[@]};do
        if [ "${temp}" = "${dealIniParamSection}" ];then
            dealIniParamSectionFlag="1"
            break
        fi
    done
 
    if [ "$dealIniParamSectionFlag" = "0" ];then
        echo "[${dealIniParamSection}]" >>${dealIniParamFile}
    fi
    #加入或更新dealIniParamValue
    awk "/\[${dealIniParamSection}\]/{a=1}a==1" ${dealIniParamFile}|sed -e '1d' -e '/^$/d' -e 's/[ \t]*$//g' -e 's/^[ \t]*//g' -e '/\[/,$d'|grep "${dealIniParamOption}.\?=">/dev/null
    if [ "$?" = "0" ];then
        #更新
        #找到制定dealIniParamSection行号码
        dealIniParamSectionNum=$(sed -n -e "/\[${dealIniParamSection}\]/=" ${dealIniParamFile})
        echo "${dealIniParamSectionNum},/^\[.*\]/s/\(${dealIniParamOption}.\?=\).*/\1 ${dealIniParamValue}/g"
        if [[ ${dealIniParamSectionNum} ]];then
            sed -i '' "${dealIniParamSectionNum},/^\[.*\]/s/\(${dealIniParamOption} *=\).*/\1 ${dealIniParamValue}/g" ${dealIniParamFile}
            echo "[success] update [$dealIniParamFile][$dealIniParamSection][$dealIniParamOption][$dealIniParamValue]"
        fi
    else
        #新增
        #echo sed -i "/^\[${dealIniParamSection}\]/a\\${dealIniParamOption}=${dealIniParamValue}" ${dealIniParamFile}
        sed -i '' "/^\[${dealIniParamSection}\]/a\\
        ${dealIniParamOption} = ${dealIniParamValue}\\
        " $dealIniParamFile
        echo "[success] add [$dealIniParamFile][$dealIniParamSection][$dealIniParamOption][$dealIniParamValue]"
    fi
}
 
#main
if [ "${dealIniParamMode}" = "iniR" ];then
    if [ "${dealIniParamSection}" = "" ];then
        dealIniReturnSections=()
    elif [ "${dealIniParamSection}" != "" ] && [ "${dealIniParamOption}" = "" ];then
        dealIniReturnOptions=()
    elif [ "${dealIniParamSection}" != "" ] && [ "${dealIniParamOption}" != "" ];then
        dealIniReturnValue=""
    fi
    dealIniReadIniFile
elif [ "${dealIniParamMode}" = "iniW" ];then
    dealIniWriteIniFile
fi