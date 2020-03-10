#!/bin/sh

#/daka/目录下准备获取员工的信息表utf-8格式csv，姓名，ID。命名为list.csv
#定义需要获取打卡人的ID listID
cat /daka/list.csv  |cut -d , -f 2 >/daka/listID

#企业信息
corpid=“更换为企业ID”
appsecret=“应用ID”

#定义token有效期和有效期检查
expireTime=7100
today=$(date "+%Y-%m-%d %H:%M:%S")
currentTimeStamp=$(date +%s)


#设置检查时间区段（只检查当日数据）
kaishiTime=`expr $currentTimeStamp - 32400`
jieshuTime=$currentTimeStamp
tokenTime=$(cat /daka/.tokenTime)
leaTime=`expr $currentTimeStamp - $tokenTime`



TotalLens=$(cat /daka/listID |wc -l)
step=100

: > /tmp/for.tmp

n=$(awk 'BEGIN{printf "%.2f\n",('$TotalLens'/'$step')}' | awk '{print int($1)==$1?$1:int(int($1*10/10+1))}')

 for ((i=1;i<=$n;i++))  
	do
#每次取值起始
hang1=$i*$step-$step+1
hang9=$i*$step 

sed -n “$hang1,$hang9“ /daka/listID > /daka/listID.step


#处理指定员工信息表格

userjson=$(jq -R -M -c -s 'split("\n")' </daka/listID.step )

echo $userjson >userjson.json

sed -i "s/,\"\"//g" userjson.json
sed -i "s/\"//g" userjson.json

userlist=$(cat userjson.json)

#匹配姓名与格式化时间
: > /daka/11.csv




#获取过去14天的打卡数据
if [ $leaTime -ge $expireTime ]
then
	#获取新的token
   accesstoken=$(/usr/bin/curl "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$corpid&corpsecret=$appsecret" | jq '.access_token' | sed 's/"//g') 
   echo $currentTimeStamp > /daka/.tokenTime
   echo $accesstoken >/daka/.token
 
   
   #获取过去14天打卡数据
   curl -s -X POST -H "Content-type:application/json" -d "{\"opencheckindatatype\":\"2\",\"starttime\":\"$kaishiTime\",\"endtime\":\"$jieshuTime\",\"useridlist\":$userlist}" https://qyapi.weixin.qq.com/cgi-bin/checkin/getcheckindata?access_token=$accesstoken | jq -r '.checkindata[] | [.userid, .checkin_time, .location_title, .location_detail]| @csv' >/daka/today.csv

   echo $(cat /daka/today.csv) > /daka/tmp.data
     
   
   
   #格式化中文姓名
	sed -i 's/\"//g' /daka/today.csv

	exec < /daka/today.csv || exit 1
	IFS=','
	while  read name check_time check_location check_address;do
		xingming=$(cat /daka/list.csv | grep $name |cut -d , -f 1|sed 's/\n//g')
		time=`date '+%m月%d日%H:%M:%S' -d@$check_time`
		echo $xingming,$time,$check_location,$check_address>>/daka/11.csv


	done 
	

   
else
   #读取缓存的token
   accesstoken=$(cat /daka/.token)

   
   #读取过去14天的打卡数据
   curl -s -X POST -H "Content-type:application/json" -d "{\"opencheckindatatype\":\"2\",\"starttime\":\"$kaishiTime\",\"endtime\":\"$jieshuTime\",\"useridlist\":$userlist}" https://qyapi.weixin.qq.com/cgi-bin/checkin/getcheckindata?access_token=$accesstoken | jq -r '.checkindata[] | [.userid, .checkin_time, .location_title, .location_detail]| @csv' >/daka/today.csv
   
   
   #格式化中文姓名
	sed -i 's/\"//g' /daka/today.csv

	exec < /daka/today.csv || exit 1
	IFS=','
	while  read name check_time check_location check_address;do
		xingming=$(cat /daka/list.csv | grep $name |cut -d , -f 1|sed 's/\n//g')
		time=`date '+%m月%d日%H:%M:%S' -d@$check_time`
		echo $xingming,$time,$check_location,$check_address>>/daka/11.csv
		

	done
	
   
fi


		done	
	
	
	#添加表头：姓名-打卡时间-打卡地点-详细地址
	#解决中文乱码
    #iconv -f UTF-8 -t GBK /daka/113.csv -o /daka/113.csv
	awk '{print ">`"FNR"`"$0}' /daka/11.csv >/daka/114.csv
	sed -i '1i `序号`,`姓名`,`打卡时间`,`打卡位置`,`打卡详细地址`' /daka/114.csv
	sed -i '1i 【今日重点地区员工位置上报情况】' /daka/114.csv
	xiaoxi=$(cat /daka/114.csv | sed 's/,/-/g')
	iconv -f UTF-8 -t GBK /daka/114.csv -o /daka/114.csv








	#发送到机器人
	
	curl -s 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=00000000-50000-4003-8007-20000000000000' \
   -H 'Content-Type: application/json' \
   -d "
   {
        \"msgtype\": \"markdown\",
        \"markdown\": {
            \"content\": \"$n\"
        }
   }"

	
	
	
	
