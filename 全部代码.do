cd"C:\Users\PKF\Desktop\stata分析"
import excel "2.xlsx",firstrow
sum y x1	x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16

ssc install estout
ssc install logout
 
ssc install asdoc
asdoc sum y x1	x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16,save(描述性统计2.doc) replace
pwcorr y x1	x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16,sig star(0.05)
asdoc pwcorr y x1	x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16,sig star(0.05) save(相关性矩阵2.doc) replace


reg y x1	x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16
vif
asdoc reg y x1	x2	x3	x4	x5	x6	x7	x8	x9	x10	x11	x12	x13	x14	x15	x16, save(回归方程.doc) replace

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

hausman fe re



*改进
xtset id year
xtreg  y x1 		x10		x13	x15	x16,fe
est store fe


* 安装必要命令（如果未安装）
ssc install xttest3

* 固定效应回归
xtreg y  x1 		x10		x13	x15	x16, fe

* Modified Wald检验（固定效应异方差）
xttest3



xtreg  y x1 		x10	x11	x13	x15	x16,re
est store re


xtreg y x1 		x10		x13	x15	x16, fe vce(cluster id)




xtreg y x1 x10 x13 x15 x16 i.year, fe  // 添加时间固定效应
est store twoway
testparm i.year  // 检验时间效应显著性

* 1. 定义地区分类
generate region = 1 if inlist(id, 1,2,5,15,24,30)    // 东部
replace region = 2 if inlist(id, 9,10,12,13,14,16,21,22,23) // 中部
replace region = 3 if inlist(id, 3,4,6,7,8,11,17,18,19,20,25,27,28,29,31) // 西部
label define region_label 1 "东部" 2 "中部" 3 "西部"
label values region region_label

* 2. 按省份分组回归并保存结果
sort id year
statsby beta=_b se=_se r2=e(r2) F=e(F) N=e(N), by(id) saving("province_reg.dta", replace): reg y x1 x10 x13 x15 x16

* 3. 合并数据并汇总地区均值
merge m:1 id using "province_reg.dta", nogen
collapse (mean) beta_* se_* r2 F N, by(region)  // 按变量实际名称汇总

* 4. 分地区回归及结果输出
eststo east: reg y x1 x10 x13 x15 x16 if region==1, robust
eststo central: reg y x1 x10 x13 x15 x16 if region==2, robust
eststo west: reg y x1 x10 x13 x15 x16 if region==3, robust

* 导出三线表
esttab east central west using "地区回归结果.rtf", replace ///
       mtitle("东部" "中部" "西部") b(%6.3f) se(%6.3f) ///
       star(* 0.1 ** 0.05 *** 0.01) r2 ar2

* 5. 联合检验系数差异
suest east central west
test [east_mean]x1 = [central_mean]x1 = [west_mean]x1



predict residuals, e  // 保存残差
estat hettest  // BP检验
imtest, white  // White检验
esttab fe re using reg3.rtf, r2 ar2 se replace nogap


reg y x1 		x10		x13	x15	x16
vif









xtset id year
xtreg  y x1 		x9		x11	x12,fe

reg y x1 		x9		x11	x12
vif
