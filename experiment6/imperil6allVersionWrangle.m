%% Imperil 6 - All versions
% Data display code

clear 
version = 'Gamma'; % 'Beta', 'Gamma', 'Delta'
probe = 'Repeat'; % 'Repeat', 'Novel', 'Both'

if ~strcmp(version, 'Alpha')
    testIdxCol = 13;
    absErrorCol = 15;
    repCol = 5;
    novelIdx = 4;
elseif strcmp(version, 'Alpha')
    repCol = 5;
    if strcmp(probe, 'Novel')
        absErrorCol = 15;
    elseif strcmp(probe, 'Repeat')
        absErrorCol = 23;
    end
end

filesAt = ['/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/design_' lower(version) '_output'];
files = dir(filesAt);
files = files(~ismember({files.name}, {'.', '..', '.DS_Store'}));
nSbj = size(files, 1);

realIDs = str2double(erase({files.name}, {['imperil6' version 'DataID'], '.mat'}));
missingSbjs = setdiff(1:max(realIDs), realIDs);

sbjs = sort(realIDs);
nSbj = numel(sbjs);
errorMat = NaN(2, 6, nSbj);
errorMat(1,:,:) = repmat(1:6, 1, 1, nSbj);

for curSbj = sbjs

    curSbjFileName = ['/imperil6' version 'DataID' num2str(curSbj) '.mat'];
    curSbjFileDIR = [filesAt curSbjFileName];
    
    load(curSbjFileDIR);
    
    for rep = 1:6
        if strcmp(version, 'Alpha')
            if strcmp(probe, 'Both')
                error('Not possible in design Alpha. Enter either "Novel" or "Repeat"')
            else
                errorIdx = outputMatrix(:,repCol) == rep;
            end
        else
            if strcmp(probe, 'Both')
                errorIdx = outputMatrix(:,repCol) == rep;
            else
                errorIdx = outputMatrix(:,repCol) == rep & outputMatrix(:,testIdxCol) == novelIdx;
            end
        end
    
        errorVals = [outputMatrix(errorIdx, absErrorCol)]';
        errorMat(2,rep,curSbj) = mean(errorVals, 'omitnan');

    end

end

figure
hold on
colors = turbo(nSbj);   

for s = 1:nSbj
    plot(1:6, errorMat(2,:,s), '-o', ...
        'Color', colors(s,:), ...
        'DisplayName', sprintf('Sbj %d', sbjs(s)));
end

hold off
xticks(1:6)
title(sprintf('Tested Item: %s', probe))
xlabel('Repetition')
ylabel('Mean Angular Error (°)')
legend('Location', 'bestoutside')