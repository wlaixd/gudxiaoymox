cd"C:\Users\PKF\Desktop\stata分析"
import excel "7.xlsx",firstrow
sum y x1 x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16
* 安装必要命令（如果未安装）
ssc install xttest3
ssc install estout
ssc install logout
 
ssc install asdoc

*描述性统计
asdoc sum y x1	x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16,save(描述性统计2.doc) replace
pwcorr y x1	x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16,sig star(0.05)
asdoc pwcorr y x1	x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16,sig star(0.05) save(相关性矩阵2.doc) replace


*简单回归
reg y x1	x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16
vif
asdoc reg y x1	x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16, save(回归方程.doc) replace

*去除显著性回归
reg y x1 	x3	x4		x8	x9	x10	x11	x12	x13	x15	x16
vif
asdoc reg y x1 	x3	x4		x8	x9	x10	x11	x12	x13	x15	x16, save(回归方程2.doc) replace

*F检验（选择个体固定效应）
xtset id year
xtreg  y x1 	x3	x4		x8	x9	x10	x11	x12	x13	x15	x16,fe
est store fe

esttab fe re using reg2.rtf, r2 ar2 se replace nogap



*Hausman检验（拒绝原假设，选择固定效应）
xtreg  y x1 	x3	x4		x8	x9	x10	x11	x12	x13	x15	x16,fe
est store fe


xtreg  y x1 	x3	x4		x8	x9	x10	x11	x12	x13	x15	x16,re
est store re
*对比2个模型
hausman fe re




*改进
xtset id year
xtreg  y x1 		x10		x13	x15	x16,fe
est store fe




* 固定效应回归
xtreg y  x1 		x10		x13	x15	x16, fe

* Modified Wald检验（固定效应异方差）
xttest3




xtreg y x1 	x10	x13	x15	x16, fe vce(cluster id)


* 普通标准误
xtreg y x1 	x10	x13	x15	x16, fe
est store FE_standard

* 异方差稳健标准误
xtreg y x1 	x10	x13	x15	x16, fe vce(robust)
est store FE_robust

* 聚类稳健标准误（以个体id为聚类单位）
xtreg y x1 	x10	x13	x15	x16, fe vce(cluster id)
est store FE_cluster

* 对比结果
esttab FE_standard FE_robust FE_cluster, se stats(N r2)





xtreg y x1 x10 x13 x15 x16 i.year, fe  // 添加时间固定效应
est store twoway
testparm i.year  // 检验时间效应显著性

* 1. 定义地区分类
* 1. 定义地区分类变量
xtset id
generate region = 1 if inlist(id, 1,2,5,15,24,30,26)       // 东部
replace region = 2 if inlist(id, 9,10,12,13,14,16,21,22,23)  // 中部
replace region = 3 if inlist(id, 3,4,6,7,8,11,17,18,19,20,25,27,28,29,31) // 西部





ssc install suest

ssc install outreg2
net install suest, from(http://www.econometrics.it/stata) replace


* 1. 完善地区标签设置（补全label命令）
label define region_label 1 "东部" 2 "中部" 3 "西部"
label values region region_label
* 2. 验证结果
tab region, missing  // 检查缺失值情况
label list region_label  // 列出标签定义
browse id region      // 交叉验证ID分类

* 3. 地区固定效应模型（双固定：时间+地区）
xtset id year
xtreg y x1 x10 x13 x15 x16 i.year i.region, fe
est store region_fe


*testparm i.region  // 检验地区效应显著性

* 3. 似然比检验（比较是否需加入地区效应）
quietly xtreg y x1 x10 x13 x15 x16 i.year, fe
est store time_fe
lrtest time_fe region_fe  // 若chi2值显著说明需保留地区效应

* 4. 分地区回归（异质性分析）
foreach i in 1 2 3 {
    xtreg y x1 x10 x13 x15 x16 i.year if region==`i', fe
    est store region_`i'
}

* 5. 组间系数差异检验（需要suest）
suest region_1 region_2 region_3
test [region_1_mean]x1 = [region_2_mean]x1 = [region_3_mean]x1  // 联合检验
test [region_1_mean]x10 = [region_2_mean]x10 = [region_3_mean]x10

* 6. 结果输出（需安装outreg2）
outreg2 [time_fe region_fe] using 地区效应检验.doc, replace ///
    keep(x1 x10 x13 x15 x16) addtext(时间效应,YES) ///
    stats(coef se) bdec(3) tdec(2)




* 固定效应模型（控制时间效应）
xtset id year
xtreg y x1 x10 x13 x15 x16 i.year, fe  // 加入年份虚拟变量

* 检验时间效应显著性
testparm i.year  // F检验所有年份虚拟变量是否联合显著
estat ic         // 查看AIC/BIC判断是否保留时间效应

*改进
xtset id year
xtreg  y x1 		x10		x13	x15	x16,fe
est store fe

xtreg  y x1 		x10		x13	x15	x16,re
est store re

esttab fe re using reg3.rtf, r2 ar2 se replace nogap


*reg y x1 x10 x13	x15	x16
*vif



xtset id year
xtreg  y x1 		x10		x13	x15	x16,fe
vif







