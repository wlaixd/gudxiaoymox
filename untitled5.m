%% =======================================
% 全流程主成分分析（PCA）完整脚本（含95%累计贡献率选取）
% 文件名：run_pca_full_updated.m
%% =======================================

%% 0. 清理环境
clearvars; close all; clc;

%% 1. 读取数据
T = readtable('C:\Users\PKF\Desktop\副本1995-2023 - 副本.xlsx', 'ReadVariableNames', true);

%% 2. 文本型数据转换为数值型
vars = T.Properties.VariableNames;
for i = 1:numel(vars)
    col = T.(vars{i});
    if iscell(col)
        T.(vars{i}) = str2double(col);
    end
end

%% 3. 缺失值填充
T{:, vars} = fillmissing(T{:, vars}, 'linear', 1);

%% 4. 构造数据矩阵
X = T{:,:};

%% 5. 标准化
Xz = zscore(X);

%% 6. 执行 PCA
[coeff, score, latent, ~, explained] = pca(Xz);

%% 7. 碎石图（Scree Plot）
figure; pareto(explained);
xlabel('主成分序号'); ylabel('方差贡献率 (%)'); title('PCA 碎石图');

%% 8. 前两主成分散点图
figure; scatter(score(:,1), score(:,2), 50, 'filled');
xlabel('主成分 1 得分'); ylabel('主成分 2 得分'); title('PCA 前两主成分散点图'); grid on;

%% 9. 双标图（Biplot）
figure; biplot(coeff(:,1:2), 'Scores', score(:,1:2), 'VarLabels', vars);
title('PCA 双标图');

%% 10. 输出所有主成分的线性表达式
fprintf('\n===== 主成分线性表达式（基于标准化后的变量） =====\n');
[nVar, nPC] = size(coeff);
for k = 1:nPC
    expr = sprintf('PC%d = ', k);
    for j = 1:nVar
        w = coeff(j,k);
        term = sprintf('%.4f×%s', w, vars{j});
        if j < nVar
            expr = [expr, term, ' + '];
        else
            expr = [expr, term];
        end
    end
    fprintf('%s\n', expr);
end

%% 11. 累计贡献率表
cumExplained = cumsum(explained);
Tcum = table((1:length(explained))', explained, cumExplained, ...
    'VariableNames', {'PC', 'Explained(%)', 'CumExplained(%)'});
disp('===== 主成分贡献率及累计贡献率 ====='); disp(Tcum);

%% 12. 主成分载荷矩阵表格展示
PCnames = strcat('PC', string(1:nPC));
LoadingsTable = array2table(coeff, ...
    'VariableNames', PCnames, ...
    'RowNames', vars);
disp('===== 主成分载荷矩阵（载荷表） ====='); disp(LoadingsTable);

%% 13. 选取累计贡献率>=95%的主成分并输出新表
% 找到达到95%累计贡献的最小主成分数量
K95 = find(cumExplained >= 95, 1, 'first');
PCnames95 = strcat('PC', string(1:K95));

% 提取前K95个主成分得分
scores95 = score(:, 1:K95);

% 构造新表：原始指标数据 + 选取的主成分得分
T_scores = [T, array2table(scores95, 'VariableNames', PCnames95)];
disp('===== 原始数据与选取主成分得分合并表 ====='); disp(T_scores);

% （可选）将结果另存为 Excel 文件
writetable(T_scores, 'C:\Users\PKF\Desktop\sj_pca_scores_95.xlsx');
