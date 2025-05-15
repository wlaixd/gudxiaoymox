%% 数据预处理
clear;clc;
data = readtable('C:\Users\PKF\Desktop\sj.xlsx', 'ReadVariableNames', true);

% 生成自定义变量名x1-xn（网页5方案扩展）
varNames = arrayfun(@(x) ['x' num2str(x)], 1:(width(data)-2), 'UniformOutput', false); 
% 注：width(data)-2对应排除的第二列

% 验证数据类型（网页1、网页4方案）
if any(cellfun(@(x) ~strcmp(x,'double'), varfun(@class, data, 'OutputFormat','cell')))
    error('非数值型列存在，请执行: data.VarName = str2double(data.VarName);');
end

%% 数据提取
X = table2array(data(:, [1,3:end]));   % 自变量（排除第二列）
Y = table2array(data(:, 2));           % 因变量

%% 构建回归矩阵
X_design = [ones(size(X,1),1), X];  
n_vars = size(X,2); % 实际自变量数量

%% 多元线性回归（网页2、网页5核心方法）
[b,bint,r,rint,stats] = regress(Y, X_design);

%% 结果输出（修正索引错误）
disp('===== 回归系数 =====');
fprintf('常数项(b0): %12.4f\n', b(1));
for i = 1:n_vars
    fprintf('%s: %12.4f\n', varNames{i}, b(i+1)); % 变量名与系数对齐
end

%% 统计指标输出（网页3标准）
disp('===== 统计指标 =====');
fprintf('R² = %.4f\nF-stat = %.2f\np-value = %.4e\n', stats(1:3));