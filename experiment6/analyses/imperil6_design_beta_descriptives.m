dataDest = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/design_beta_output';

errorNovel = NaN(30,4,2);
errorRepeated = NaN(45,4,2);

for sbj = 1:7
    curSbj = sprintf('imperil6BetaDataID%d.mat', sbj);
    fileToLoad = fullfile(dataDest, curSbj);

    % Load file
    load(fileToLoad);  

    errorNovel(:,1,sbj) = outputMatrix(outputMatrix(:,23) == 1 & outputMatrix(:,13) == 4, 15);
    errorNovel(:,2,sbj) = outputMatrix(outputMatrix(:,23) == 2 & outputMatrix(:,13) == 4, 15);
    errorNovel(:,3,sbj) = outputMatrix(outputMatrix(:,23) == 3 & outputMatrix(:,13) == 4, 15);
    errorNovel(:,4,sbj) = outputMatrix(outputMatrix(:,23) == 4 & outputMatrix(:,13) == 4, 15);

    errorRepeated(:,1,sbj) = outputMatrix(outputMatrix(:,23) == 1 & outputMatrix(:,13) ~= 4, 15);
    errorRepeated(:,2,sbj) = outputMatrix(outputMatrix(:,23) == 2 & outputMatrix(:,13) ~= 4, 15);
    errorRepeated(:,3,sbj) = outputMatrix(outputMatrix(:,23) == 3 & outputMatrix(:,13) ~= 4, 15);
    errorRepeated(:,4,sbj) = outputMatrix(outputMatrix(:,23) == 4 & outputMatrix(:,13) ~= 4, 15);

end

subjMeansNovel = squeeze(mean(errorNovel, 1, "omitnan"));
subjMeansRepeated = squeeze(mean(errorRepeated, 1, "omitnan"));
stdByCond2 = squeeze(std(errorRepeated, 0, [1 3], "omitnan"));
stdByCond = squeeze(std(errorNovel, 0, [1 3], "omitnan"));

%% Plot individual data

xCond = 1:size(subjMeansRepeated', 2);

figure;
plot(xCond, subjMeansRepeated', '-x', 'LineWidth', 2);
xlabel('Condition');
ylabel('Mean absolute angular error');
title('Repeated item: individual participant means');
xticks(1:4)
xticklabels({'R1 NoChange', 'R1 Change', 'R5 NoChange', 'R5 Change'})
