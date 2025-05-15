%%  关闭窗口
warning off
clear all
close all
clc
rng(2)  % 设置随机种子

%% 导入数据（已使用您的数据）
data = readtable('C:\Users\PKF\Desktop\sj.xlsx', 'ReadVariableNames', true);

X = table2array(data(:, [1,3:end]));  % 自变量（排除第二列）
Y = table2array(data(:, 2));          % 因变量（第二列）

%% 数据集划分
total_samples = size(X, 1);  % 获取总样本数
temp = randperm(total_samples);  % 随机打乱顺序

% 转置数据以适应神经网络输入格式（特征×样本）
input_all = X(temp, :)';
output_all = Y(temp)';

% 划分比例（70%训练，30%测试）
num_train = round(total_samples * 0.7);

input_train = input_all(:, 1:num_train);
output_train = output_all(:, 1:num_train);

input_test = input_all(:, num_train+1:end);
output_test = output_all(:, num_train+1:end);

disp(['训练样本个数：', num2str(num_train)])
disp(['测试样本个数：', num2str(total_samples - num_train)])

%% 数据归一化
[input_norm, input_ps] = mapminmax(input_train, 0, 1);
[output_norm, output_ps] = mapminmax(output_train);

input_test_norm = mapminmax('apply', input_test, input_ps);
output_test_norm = mapminmax('apply', output_test, output_ps);

%% 网络参数
input_num = size(input_train, 1);  % 输入层节点数（自动获取特征数）
hidden_num = 11;  % 隐藏层节点数
output_num = size(output_train, 1);  % 输出层节点数

%% 创建BP网络
net = newff(input_norm, output_norm, hidden_num, {'tansig', 'purelin'}, 'trainlm');

%% 训练参数配置
net.trainParam.epochs = 1000;
net.trainParam.lr = 0.001;  % 修正学习率符号
net.trainParam.goal = 1e-3;
net.trainParam.max_fail = 6;

%% 网络训练
net = train(net, input_norm, output_norm);

%% 模型测试
pred_norm = sim(net, input_test_norm);
pred = mapminmax('reverse', pred_norm, output_ps);

%% 性能评估
disp(' ')
disp('BP神经网络性能指标:')

% R²
SS_res = sum((output_test - pred).^2);
SS_tot = sum((output_test - mean(output_test)).^2);
R2 = 1 - (SS_res / SS_tot);
disp(['测试集R²: ', num2str(R2)])

% MAE
MAE = mean(abs(output_test - pred));
disp(['测试集MAE: ', num2str(MAE)])

% MSE
MSE = mean((output_test - pred).^2);
disp(['测试集MSE: ', num2str(MSE)])

% RMSE
RMSE = sqrt(MSE);
disp(['测试集RMSE: ', num2str(RMSE)])

% MAPE（添加容错处理）
valid_idx = output_test ~= 0;  % 排除零值
MAPE = mean(abs((output_test(valid_idx) - pred(valid_idx))./output_test(valid_idx)))*100;
disp(['测试集MAPE: ', num2str(MAPE), '%'])

%% 可视化结果
figure
plot(output_test, 'bo-', 'LineWidth', 1.2)
hold on
plot(pred, 'r*-', 'LineWidth', 1.2)
legend('真实值', '预测值')
xlabel('测试样本编号')
ylabel('因变量值')  % 请根据实际修改ylabel
title('BP神经网络预测性能对比')
set(gca, 'FontSize', 12)
grid on