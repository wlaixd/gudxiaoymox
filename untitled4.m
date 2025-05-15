%% 数据读取与预处理
% 读取Excel文件（自动识别数值型数据）
[data, ~, raw] = xlsread('C:\Users\PKF\Desktop\sj.xlsx', 'Sheet1');

% 获取有效数据列（从第2列开始）
numeric_data = data(:, 2:end);  % 假设第1列为标识列

% 数据清洗（删除包含缺失值的行）
clean_data = rmmissing(numeric_data);

% 数据标准化（Z-score标准化）
data_normalized = zscore(clean_data);

%% 主成分分析
[coeff, score, latent, ~, explained] = pca(data_normalized);

%% 可视化分析
figure('Position', [100, 100, 1200, 800])

% 1. 方差解释曲线
subplot(2,2,1)
plot(cumsum(explained), 'bo-', 'LineWidth', 2)
hold on
yline(95, '--r', '95% Threshold')
xlabel('主成分数量')
ylabel('累计方差解释率 (%)')
title('累计方差解释率')
grid on

% 2. 主成分载荷矩阵
subplot(2,2,2)
heatmap(abs(coeff(:,1:3)),...
    'XData', {'PC1','PC2','PC3'},...
    'YData', raw(1, 2:size(coeff,1)+1),... % 使用原始列名
    'Colormap', turbo,...
    'ColorLimits', [0 1]);
title('主成分载荷绝对值')

% 3. 主成分得分分布
subplot(2,2,3)
gscatter(score(:,1), score(:,2), ones(size(score,1),1),...
    linspace(1,64,size(score,1)), 'o', 15)
colorbar
xlabel('PC1')
ylabel('PC2')
title('主成分得分时空分布')
grid on

% 4. 平行坐标图
subplot(2,2,4)
parallelcoaxes(score(:,1:3), 'Quantile', 0.25)
title('主成分平行坐标分析')

%% 结果输出
fprintf('数据维度信息:\n')
fprintf('原始数据: %d×%d\n', size(raw))
fprintf('清洗后数据: %d×%d\n\n', size(clean_data))

disp('前5个主成分解释率:')
disp(array2table([explained(1:5) cumsum(explained(1:5))],...
    'VariableNames', {'单成分贡献率','累计贡献率'},...
    'RowNames', {'PC1','PC2','PC3','PC4','PC5'}))