addpath(genpath('/Users/ali/Desktop/imperil6_delta_mouse_data'))
mouseDataDest = '/Users/ali/Desktop/imperil6_delta_mouse_data';
trajFiles = dir(mouseDataDest);
trajFiles = trajFiles(~ismember({trajFiles.name}, {'.', '..'}));
nSbj = size(trajFiles, 1);

for sbj = 26:nSbj
    
    % Load current participant data
    curSbj = sprintf('imperil6DeltaDataMouseID%d.mat', sbj);
    fileToLoad = fullfile(mouseDataDest, curSbj);
    load(fileToLoad);  

    % Remove empty cells
    if size(trackingData,2) <= 1
        continue;
    else
        trackingData(:,2:900) = [];
    end

    for trial = 1:900
        curRow = trackingData{trial,1};
        curRow = reshape(curRow, size(curRow,2)/3, 3);
        trackingData{trial,1} = [];
        trackingData{trial,1} = curRow;
    end

    % Save the new version
    save(fullfile(mouseDataDest, curSbj), 'trackingData')
end