#!/bin/sh


#/daka/目录下准备获取员工的信息表utf-8格式csv，姓名，ID。命名为list.csv
#定义需要获取打卡人的ID listID
cat /daka/zhongdianID.csv  |cut -d , -f 2 >/daka/listID

#企业信息
corpid=｛企业ID｝
appsecret={打卡应用的secret}

#定义token有效期和有效期检查
expireTime=7100
today=$(date "+%Y-%m-%d %H:%M:%S")
TodayTime=$(date "+%Y年%m月%d日")
currentTimeStamp=$(date +%s)


#只检查当日数据
kaishiTime=`expr $currentTimeStamp - 46800`
jieshuTime=$currentTimeStamp
tokenTime=$(cat /daka/.tokenTime)
leaTime=`expr $currentTimeStamp - $tokenTime`


#获取原始数据行数并准备以90行进行分批次
TotalLens=$(cat /daka/listID |wc -l)
step=90
: > /daka/listID.step
n=$(awk 'BEGIN{printf "%.2f\n",('$TotalLens'/'$step')}' | awk '{print int($1)==$1?$1:int(int($1*10/10+1))}')

#匹配姓名与格式化时间
: > /daka/11.csv
: > /tmp/for.tmp
#循环获取所有人员打开数据，每次获取100个
 for ((i=1;i<=$n;i++))  
	do


hang1=$[ $i * $step - $step + 1]
hang9=$[$i * $step]
baifenbi=$(awk 'BEGIN{printf "%.2f\n",('$hang9'/'$TotalLens'*'100')}')

echo "数据获取中....$baifenbi %"
	
	
sed -n "$hang1,$hang9 p" /daka/listID > /daka/listID.step


#处理指定员工信息表格

userjson=$(jq -R -M -c -s 'split("\n")' </daka/listID.step )
echo $userjson >userjson.json
sed -i "s/[ ]/,/g" userjson.json
sed -i "s/,\"\"//g" userjson.json
#sed -i "s/\"//g" userjson.json
userlist=$(cat userjson.json)



#获取过去指定天数的打卡数据
if [ $leaTime -ge $expireTime ]
then
	#获取新的token
   accesstoken=$(/usr/bin/curl -s "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$corpid&corpsecret=$appsecret" | jq '.access_token' | sed 's/"//g') 
   echo $currentTimeStamp > /daka/.tokenTime
   echo $accesstoken >/daka/.token
 
   
   #获取过去指定天数的打卡数据
    curl -s -X POST -H "Content-type:application/json" -d "{\"opencheckindatatype\":\"2\",\"starttime\":\"$kaishiTime\",\"endtime\":\"$jieshuTime\",\"useridlist\":$userlist}" https://qyapi.weixin.qq.com/cgi-bin/checkin/getcheckindata?access_token=$accesstoken | jq -r '.checkindata[] | [.userid, .checkin_time, .location_title, .location_detail, .exception_type]| @csv' >/daka/today.csv
   
   
   
   #格式化中文姓名
	sed -i 's/\"//g' /daka/today.csv

	exec < /daka/today.csv || exit 1
	IFS=','
	while  read name check_time check_location check_address exception_type;do
		xingming=$(cat /daka/zhongdianID.csv | grep $name |cut -d , -f 1|sed 's/\n//g')
		time=`date '+%m月%d日%H:%M:%S' -d@$check_time`
		echo $xingming,$time,$check_location,$check_address,$exception_type>>/daka/11.csv


	done 
	

   
else
   #读取缓存的token
   accesstoken=$(cat /daka/.token)

   
   #获取过去指定天数的打卡数据
   curl -s -X POST -H "Content-type:application/json" -d "{\"opencheckindatatype\":\"2\",\"starttime\":\"$kaishiTime\",\"endtime\":\"$jieshuTime\",\"useridlist\":$userlist}" https://qyapi.weixin.qq.com/cgi-bin/checkin/getcheckindata?access_token=$accesstoken | jq -r '.checkindata[] | [.userid, .checkin_time, .location_title, .location_detail, .exception_type]| @csv' >/daka/today.csv

   
   #格式化中文姓名
	sed -i 's/\"//g' /daka/today.csv

	exec < /daka/today.csv || exit 1
	IFS=','
	while  read name check_time check_location check_address exception_type;do
		xingming=$(cat /daka/zhongdianID.csv | grep $name |cut -d , -f 1|sed 's/\n//g')
		time=`date '+%m月%d日%H:%M:%S' -d@$check_time`
		echo $xingming,$time,$check_location,$check_address,$exception_type>>/daka/11.csv
		

	done
	
   
fi


		done	
	#去除未打卡记录
	cat /daka/11.csv > /daka/12.csv

	
	#数据生成计算
	xixi=$(cat /daka/12.csv |wc -l)
	
	#添加表头：姓名-打卡时间-打卡地点-详细地址
	#解决中文乱码
    #iconv -f UTF-8 -t GBK /daka/113.csv -o /daka/113.csv
	awk '{print FNR","$0}' /daka/12.csv >/daka/114.csv
	sed -i '1i 序号,姓名,打卡时间,打卡位置,打卡详细地址,异常信息' /daka/114.csv
	sed -i "1i 【$TodayTime重点地区员工打卡记录】" /daka/114.csv
	xiaoxi=$(cat /daka/114.csv | sed 's/,/-/g')
	iconv -f UTF-8 -t GBK /daka/114.csv -o /daka/$TodayTime重点地区打卡数据.csv

	#发送到机器人
	#curl -s 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=00000000-00000-0000-0000-000000000000' \
   #-H 'Content-Type: application/json' \
   #-d "
   #{
    #    \"msgtype\": \"markdown\",
     #   \"markdown\": {
      #      \"content\": \"$TodayTime截止9:30分，今日打卡员工$xixi人。详细数据请查收【远程办公】下发的汇总文档\"
       # }
   #}"

	echo "发送数据到应用通知"
	
#发送数据到应用通知

	#准备远程办公应用的相关基础数据
	yuanchengsecret=｛应用的secret｝
	agentid=｛发消息应用的ID｝	
	touserid="{发给谁}"


	
	#获取素材上传token
	yuanchengaccesstoken=$(/usr/bin/curl -s "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$corpid&corpsecret=$yuanchengsecret" | jq '.access_token' | sed 's/"//g') 
   echo $currentTimeStamp > /daka/.tokenTime.yuancheng
   echo $yuanchengaccesstoken >/daka/.token.yuancheng
	
	
	#上传临时素材到企业微信,获取文件的mediaID	

	filecsvname=$(curl -s -F media=@/daka/$TodayTime重点地区打卡数据.csv "https://qyapi.weixin.qq.com/cgi-bin/media/upload?access_token=$yuanchengaccesstoken&type=file" | jq '.media_id' | sed 's/"//g') 




	#发送消息
	msgsend_url="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=${yuanchengaccesstoken}"
	message_md="> **重点地区打卡摘要** 
				>
                > 人数：$xixi人 
                > 日期：$TodayTime
                >  
                > 打卡明细请查阅附件。 "


	json_params="{\"touser\":\"$touserid\",\"msgtype\":\"file\",\"agentid\":\"$agentid\",\"file\":{\"media_id\":\"${filecsvname}\"},\"safe\":\"0\"}"
	md_json_params="{\"touser\":\"$touserid\",\"msgtype\":\"markdown\",\"agentid\":\"$agentid\",\"markdown\":{\"content\":\"$message_md\"},\"safe\":\"0\"}"
	#echo -e "\n${json_params}" 
	#/usr/bin/curl -X POST ${msgsend_url} -d ${json_params} | jq -r '.errcode'
	/usr/bin/curl -s -X POST "$msgsend_url" -d "$md_json_params"	
	/usr/bin/curl -s -X POST "$msgsend_url" -d "$json_params"
	
