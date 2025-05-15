
T = readtable('C:\Users\PKF\Desktop\abc.xlsx', 'ReadVariableNames', true);  
y = T{:,1};                     % 因变量：失业率
X = T{:,2:end};                 % 自变量矩阵

%% 2. 缺失值检查与处理
% 检查 y 和 X 中的 NaN
nNanY = sum(isnan(y));
nNanX = sum(any(isnan(X),2));
fprintf('原始数据中 y 的 NaN 个数：%d\n', nNanY);
fprintf('原始数据中含 NaN 的行数：%d\n', nNanX);

% 删除任何含 NaN 的行
if nNanY>0 || nNanX>0
    T = rmmissing(T);          % 移除含 NaN 的整行
    y = T{:,1};
    X = T{:,2:end};
    fprintf('已移除缺失值行，剩余样本数：%d\n', size(T,1));
end

%% 3. 常量因变量检测
if var(y) == 0
    error('因变量 y 方差为零（所有值相同），无法进行回归分析，请检查数据。');
end

%% 4. 划分训练集 / 测试集（70% / 30%）
n = numel(y);
cv = cvpartition(n, 'HoldOut', 0.30);
idxTr = training(cv);
idxTe = test(cv);

X_tr = X(idxTr,:);
y_tr = y(idxTr);
X_te = X(idxTe,:);
y_te = y(idxTe);

%% 5. 多元线性回归
mdl_lin = fitlm(X_tr, y_tr);

y_pred_tr_lin = predict(mdl_lin, X_tr);
y_pred_te_lin = predict(mdl_lin, X_te);

%% 6. 随机森林回归
numTrees = 100;
rf = TreeBagger(...
    numTrees, ...
    X_tr, y_tr, ...
    'Method','regression', ...
    'OOBPrediction','On');

y_pred_tr_rf = predict(rf, X_tr);
y_pred_te_rf = predict(rf, X_te);

%% 7. 性能评估
rmse = @(y_true,y_pred) sqrt(mean((y_true - y_pred).^2));
r2   = @(y_true,y_pred) 1 - sum((y_true - y_pred).^2) / sum((y_true - mean(y_true)).^2);

% 线性回归
rmse_tr_lin = rmse(y_tr, y_pred_tr_lin);
r2_tr_lin   = r2(  y_tr, y_pred_tr_lin);
rmse_te_lin = rmse(y_te, y_pred_te_lin);
r2_te_lin   = r2(  y_te, y_pred_te_lin);

% 随机森林
rmse_tr_rf  = rmse(y_tr, y_pred_tr_rf);
r2_tr_rf    = r2(  y_tr, y_pred_tr_rf);
rmse_te_rf  = rmse(y_te, y_pred_te_rf);
r2_te_rf    = r2(  y_te, y_pred_te_rf);

% 打印结果
fprintf('\n=== 多元线性回归 ===\n');
fprintf('Training  RMSE = %.4f, R^2 = %.4f\n', rmse_tr_lin, r2_tr_lin);
fprintf('Testing   RMSE = %.4f, R^2 = %.4f\n', rmse_te_lin, r2_te_lin);

fprintf('\n=== 随机森林回归 ===\n');
fprintf('Training  RMSE = %.4f, R^2 = %.4f\n', rmse_tr_rf, r2_tr_rf);
fprintf('Testing   RMSE = %.4f, R^2 = %.4f\n', rmse_te_rf, r2_te_rf);

%% 8. 绘图：真实 vs 预测（实线 vs 虚线）
% 8.1 线性回归
figure;
subplot(2,1,1); hold on;
plot(y_tr,           '-', 'LineWidth',1.2);
plot(y_pred_tr_lin,  '--','LineWidth',1.2);
title('线性回归 - 训练集');
xlabel('样本序号'); ylabel('失业率');
legend('真实值','预测值','Location','Best');
hold off;

subplot(2,1,2); hold on;
plot(y_te,           '-', 'LineWidth',1.2);
plot(y_pred_te_lin,  '--','LineWidth',1.2);
title('线性回归 - 测试集');
xlabel('样本序号'); ylabel('失业率');
legend('真实值','预测值','Location','Best');
hold off;

% 8.2 随机森林回归
figure;
subplot(2,1,1); hold on;
plot(y_tr,          '-', 'LineWidth',1.2);
plot(y_pred_tr_rf,  '--','LineWidth',1.2);
title('随机森林 - 训练集');
xlabel('样本序号'); ylabel('失业率');
legend('真实值','预测值','Location','Best');
hold off;

subplot(2,1,2); hold on;
plot(y_te,          '-', 'LineWidth',1.2);
plot(y_pred_te_rf,  '--','LineWidth',1.2);
title('随机森林 - 测试集');
xlabel('样本序号'); ylabel('失业率');
legend('真实值','预测值','Location','Best');
hold off;

%% 9. 随机森林 OOB 误差曲线（可选）
figure;
oobErr = oobError(rf);
plot(oobErr, '-o','LineWidth',1);
xlabel('树的数量');
ylabel('OOB 均方误差');
title('随机森林 OOB 误差');
