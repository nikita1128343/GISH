% Лабораторная работа 1: расстояние пешком, методы 1 и 2.
% Файл Excel должен лежать в той же папке, что и этот скрипт.
% Закройте Excel перед включением записи результатов в файл.
clear; clc;
here = fileparts(mfilename('fullpath'));
book = fullfile(here, 'Лабораторная_1_расстояние_пешком.xlsx');
writeResultsToExcel = false;  % true: обновить результаты метода 2 в Excel

labels = {'0–1','1–2','2–3','3–4','4–5','5–6'};
names = {'Близко','Средне','Далеко'};
x = 0.5:1:5.5;  % середины интервалов, км

%% Метод 1: число голосов экспертов / 5
votes = zeros(3,6,5);  % терм, интервал, эксперт
for e = 1:5
    firstRow = 2 + 3*(e-1);
    range = sprintf('C%d:H%d', firstRow, firstRow+2);
    votes(:,:,e) = readmatrix(book, 'Sheet', 'Метод 1', 'Range', range);
end
if any(~ismember(votes(:), [0 1]))
    error('В методе 1 все оценки экспертов должны быть равны 0 или 1.');
end
mu1 = (sum(votes,3)/5).';  % 6 интервалов × 3 терма

%% Метод 2: главный собственный вектор каждой матрицы
ranges = {'B28:G33','B40:G45','B52:G57'};
W = zeros(6,3);
mu2 = zeros(6,3);
lambdaMax = zeros(3,1);
for t = 1:3
    raw = readmatrix(book, 'Sheet', 'Метод 2', 'Range', ranges{t});
    if ~isequal(size(raw), [6 6])
        error('Матрица %d должна иметь размер 6 на 6.', t);
    end
    A = eye(6);
    for i = 1:6
        for j = i+1:6
            value = raw(i,j);  % читаем только жёлтую верхнюю часть
            if ~isfinite(value) || value <= 0
                error('В матрице %d, строка %d, столбец %d нужна положительная оценка.', t, i, j);
            end
            A(i,j) = value;
            A(j,i) = 1/value;
        end
    end

    [V,D] = eig(A);  % встроенная функция MATLAB, без таблицы итераций
    eigenvalues = diag(D);
    [~,index] = max(real(eigenvalues));
    lambdaMax(t) = real(eigenvalues(index));
    w = real(V(:,index));
    if sum(w) < 0
        w = -w;
    end
    W(:,t) = w/sum(w);      % сумма компонент W равна 1
    mu2(:,t) = W(:,t)/max(W(:,t));  % максимум принадлежности равен 1
end
delta = lambdaMax - 6;

disp('Метод 1: степени принадлежности (близко, средне, далеко)');
disp(mu1);
disp('Метод 2: собственные векторы W (по столбцам)');
disp(W);
disp('Метод 2: степени принадлежности (близко, средне, далеко)');
disp(mu2);
disp('Собственные значения и отклонения от 6:');
disp(table(names.', lambdaMax, delta, ...
    'VariableNames', {'Терм','lambdaMax','lambdaMaxMinus6'}));

if writeResultsToExcel
    writematrix(mu2, book, 'Sheet', 'Метод 2', 'Range', 'B8');
    writematrix([lambdaMax delta], book, 'Sheet', 'Метод 2', 'Range', 'B18');
end

%% Графики в MATLAB
colors = [0.145 0.514 0.357; 0.835 0.541 0.180; 0.773 0.325 0.353];
for method = 1:2
    figure('Name', sprintf('Метод %d',method), 'Color', 'w');
    hold on;
    if method == 1
        mu = mu1;
    else
        mu = mu2;
    end
    for t = 1:3
        plot(x, mu(:,t), '-o', 'LineWidth', 1.8, ...
            'MarkerSize', 5, 'Color', colors(t,:));
    end
    hold off;
    grid on;
    xticks(x);
    xticklabels(labels);
    ylim([0 1.05]);
    xlabel('Расстояние пешком, км');
    ylabel('Степень принадлежности');
    title(sprintf('Функции принадлежности: метод %d',method));
    legend(names, 'Location', 'best');
end
