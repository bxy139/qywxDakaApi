#!/bin/sh
#使用打卡应用获取成员数据


#企业信息\打卡应用appsecret
corpid=｛企业ID｝
appsecret=｛APPsecret｝

#定义token有效期和有效期检查
expireTime=7100
today=$(date "+%Y-%m-%d %H:%M:%S")
TodayTime=$(date "+%Y年%m月%d日")
currentTimeStamp=$(date +%s)
tokenTime=$(cat /daka/.tokenTime.daka)
leaTime=`expr $currentTimeStamp - $tokenTime`



#获取过去指定天数的打卡数据
if [ $leaTime -ge $expireTime ]
then
	#获取新的token
   accesstoken=$(/usr/bin/curl -s "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$corpid&corpsecret=$appsecret" | jq '.access_token' | sed 's/"//g') 
   #缓存token获取时间
   echo $currentTimeStamp > /daka/.tokenTime.daka
   #缓存tonken，明文存储文件
   echo $accesstoken >/daka/.token.daka
   
else
   #读取缓存的token
   accesstoken=$(cat /daka/.token.daka)

fi

  #使用打卡应用获取指定标签成员数据（姓名+ID）
  /usr/bin/curl -s  "https://qyapi.weixin.qq.com/cgi-bin/tag/get?access_token=$accesstoken&tagid=｛标签ID｝" | jq -r '.userlist[] | [.name, .userid]| @csv' >/daka/zhongdianID.csv

	#使用打卡应用获取指定部门成员数据（姓名+ID）
	/usr/bin/curl -s  "https://qyapi.weixin.qq.com/cgi-bin/user/list?access_token=$accesstoken&department_id=｛部门ID｝&fetch_child=1" | jq -r '.userlist[] | [.name, .userid]| @csv' >/daka/jiguan.csv

   
   #格式化基础数据
	sed -i 's/\"//g' /daka/zhongdianID.csv
	sed -i 's/\"//g' /daka/jiguan.csv
