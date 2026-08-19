design = "Delta"; % "Beta" or "Gamma"
test = "Repeated"; % "Novel" or "Repeated" or "Delta"

dataDest = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/design_'+lower(design)+'_output';

if strcmp(design,"Gamma")
    nSbj = [9 10];
elseif strcmp(design,"Beta")
    nSbj = 1:7;
elseif strcmp(design,"Delta")
    nSbj = 1:2;
end

errorNovel = NaN(30,4,length(nSbj));
errorRepeated = NaN(45,4,length(nSbj));

for sbj = nSbj
    curSbj = sprintf('imperil6%sDataID%d.mat', design, sbj);
    fileToLoad = fullfile(dataDest, curSbj);

    % Load file
    load(fileToLoad);  

    errorNovel(:,1,sbj) = outputMatrix(outputMatrix(:,23) == 1 & outputMatrix(:,13) == 3, 15);
    errorNovel(:,2,sbj) = outputMatrix(outputMatrix(:,23) == 2 & outputMatrix(:,13) == 3, 15);
    errorNovel(:,3,sbj) = outputMatrix(outputMatrix(:,23) == 3 & outputMatrix(:,13) == 3, 15);
    errorNovel(:,4,sbj) = outputMatrix(outputMatrix(:,23) == 4 & outputMatrix(:,13) == 3, 15);

    errorRepeated(:,1,sbj) = outputMatrix(outputMatrix(:,23) == 1 & outputMatrix(:,13) ~= 3, 15);
    errorRepeated(:,2,sbj) = outputMatrix(outputMatrix(:,23) == 2 & outputMatrix(:,13) ~= 3, 15);
    errorRepeated(:,3,sbj) = outputMatrix(outputMatrix(:,23) == 3 & outputMatrix(:,13) ~= 3, 15);
    errorRepeated(:,4,sbj) = outputMatrix(outputMatrix(:,23) == 4 & outputMatrix(:,13) ~= 3, 15);

end

subjMeansNovel = squeeze(mean(errorNovel, 1, "omitnan"));
subjMeansRepeated = squeeze(mean(errorRepeated, 1, "omitnan"));

% subjMeansNovel = reshape(mean(errorNovel, 1, "omitnan"), 4, []);
% subjMeansRepeated = reshape(mean(errorRepeated, 1, "omitnan"), 4, []);


stdByCond2 = squeeze(std(errorRepeated, 0, [1 3], "omitnan"));
stdByCond = squeeze(std(errorNovel, 0, [1 3], "omitnan"));

%% Plot individual data

if test == "Novel"
    plotData = subjMeansNovel;
elseif test == "Repeated"
    plotData = subjMeansRepeated;
end
xCond = 1:size(plotData', 2);

figure;
plot(xCond, plotData', '-x', 'LineWidth', 2);
xlabel('Condition');
ylabel('Mean absolute angular error');
title(test + ' item: individual participant means');
xticks(1:4)
xticklabels({'R1 NoChange', 'R1 Change', 'R5 NoChange', 'R5 Change'})


% if test == "Novel"
%     plotData = subjMeansNovel;
% elseif test == "Repeated"
%     plotData = subjMeansRepeated;
% end
% 
% xCond = 1:4;
% 
% figure;
% plot(xCond, plotData, '-x', 'LineWidth', 2);
% xlabel('Condition');
% ylabel('Mean absolute angular error');
% title(test + ' item: individual participant means');
% xticks(1:4)
% xticklabels({'R1 NoChange', 'R1 Change', 'R5 NoChange', 'R5 Change'})