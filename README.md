# 企业微信打卡数据每日推送到指定人员

企业微信目前的打卡功能太弱鸡，不满足疫情防控期间的基本需要。临时建了两个弱鸡的shell脚本，帮助打卡弱鸡的功能更上一层楼。（质量不够，数量来凑）

![image](https://github.com/bxy139/qywxDakaApi/blob/master/images/images.jfif)

企业微信打卡API数据获取，处理为CSV表格和打卡数据摘要，通过企业自建应用发送给指定人员。

重点地区人员筛选，定时发送企业微信打卡数据到企业微信




# 数据同步
tongbu.sh
读取企业微信指定部门成员信息、指定标签成员信息


# 获取上下班打卡数据
获取通过数据同步获得的人员信息的打卡记录
每日定时发送摘要和汇总表给指定人员

# 指定标签人员的外出打卡记录
获取指定标签人员的外出打卡记录
每日定时发送摘要和汇总表给指定人员


# 应用
1.设置个定时任务，每天同步一下成员信息
2.定时任务增加获取上下班打卡数据、获取外出打卡记录数据。
3.每天等着收数据




# 企业微信API文档
https://work.weixin.qq.com/api/doc/
