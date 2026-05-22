%% Imperil or Protect 6 - Condition Matrix Generator
% Coded by A.Y.

% Conception: 21.04.2026
% v1 - 23.04.2026: first version finalized
% v2 - 25.04.2026: Change of design: Mem 1 array items are now to be positioned 
% from each other at a fixed offset of 120°
% and this configuration should be rotated by a random
% theta at every series. 

nTrials = 600; % Can be 480, 600 or 720
computerHandle = 1; % 0 for ali's pc, 1 for the experiment comp, 2 for the gamma computer

if computerHandle == 0
    condDest = '/Users/ali/Desktop/visual imperil project/imperil6materials/imperil6ConditionFiles';
    stimuliDIR = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/TestObjectsTransparentExtended'; 
    trainingStimuliDIR = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/trainingStimuliExp6';
elseif computerHandle == 1
    condDest = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\imperil6ConditionFilesV2';
    stimuliDIR = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\TestObjectsTransparentExtended';
    trainingStimuliDIR = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\trainingStimuliExp6';
elseif computerHandle == 2
    condDest = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - imperil6\imperil6ConditionFiles';
end

% Total number of repetition series to generate based on desired trial
% count. 720 total -> 120 series, nSeriesMain trials -> nSeriesMain series
% But always add 10 to the nSeriesMain. The extra 10 rep series is for the training.

%% ===================== BASIC COUNTS =====================

%% ===================== BASIC COUNTS =====================

if nTrials == 720
    nSeriesMain = nTrials / 6;   
elseif nTrials == 600
    nSeriesMain = nTrials / 6; 
elseif nTrials == 480
    nSeriesMain = nTrials / 6;     
else
    error('Unexpected nTrials value. nTrials must be 480, 600, or 720.');
end

nTrialsTrain = 60;
nSeriesTrain = nTrialsTrain / 6;

nTrialsTotal = nTrials + nTrialsTrain;
nSeriesTotal = nSeriesMain + nSeriesTrain;

rng('shuffle');

for condFile = 1:15

    %% ===================== REPETITION SEQUENCE =====================

    seriesSequence = (1:6)'; 
    longSequence = repmat(seriesSequence, nSeriesTotal, 1); 
  
    conditionMatrix = NaN(nTrialsTotal, 8); 
    conditionMatrix(:,1) = longSequence;

    %% ===================== CONTEXT CHANGE VALUES =====================

    nRep1 = sum(longSequence == 1);
    nRep5 = sum(longSequence == 5);

    rep1conds = [repmat(0, nRep1/2, 1); repmat(1, nRep1/2, 1)];
    rep5conds = [repmat(0, nRep5/2, 1); repmat(1, nRep5/2, 1)];

    rep1random = rep1conds(randperm(nRep1));
    rep5random = rep5conds(randperm(nRep5));

    rep1idx = find(longSequence == 1);
    rep5idx = find(longSequence == 5);

    conditionMatrix(rep1idx, 2) = rep1random;
    conditionMatrix(rep5idx, 2) = rep5random;

    %% ===================== COLOR ASSIGNMENT =====================

    validSetFound = false;
    outerAttempts = 0;
    maxOuterAttempts = 1000;
    colorOffset = 40;

    while ~validSetFound && outerAttempts < maxOuterAttempts
        outerAttempts = outerAttempts + 1;

        colorsVec = [];

        for series = 1:nSeriesTotal
            colors = zeros(1,9);

            colors(1) = randi([0 359]);

            for k = 2:9
                colors(k) = mod(colors(k-1) + colorOffset, 360);
            end

            colors = colors(randperm(9));
            colorsVec = [colorsVec; colors(:)];
        end

        colorsMat = reshape(colorsVec, 9, nSeriesTotal);

        maxInnerAttempts = 1000;
        validSetFound = true;

        for col = 1:(nSeriesTotal - 1)

            success = false;
            attempt = 0;

            while ~success && attempt < maxInnerAttempts
                attempt = attempt + 1;

                colorsMat(:, col+1) = colorsMat(randperm(9), col+1);

                prevTriplet = colorsMat(1:3, col);
                nextTriplet = colorsMat(1:3, col+1);

                D = abs(prevTriplet - nextTriplet');
                circD = min(D, 360 - D);

                tripletOK = all(circD(:) >= colorOffset);

                prevLast = colorsMat(9, col);
                nextFirst = colorsMat(4, col+1);

                D2 = abs(prevLast - nextFirst);
                circD2 = min(D2, 360 - D2);

                array2OK = circD2 >= colorOffset;

                success = tripletOK && array2OK;
            end

            if ~success
                validSetFound = false;
                break;
            end
        end
    end

    if ~validSetFound
        error('Could not generate valid colorsMat.');
    end

    fprintf('Valid colorsMat found after %d attempts.\n', outerAttempts);

    colorsMatMain = reshape(colorsMat(4:9,:), nTrialsTotal, 1);

    %% ===================== MAIN IMAGE ASSIGNMENT =====================

    stimuliFiles = dir(fullfile(stimuliDIR, '*.png'));
    stimuliPaths = fullfile({stimuliFiles.folder}, {stimuliFiles.name});

    nStimuli = numel(stimuliPaths);

    nSelectMain = nSeriesMain * 3;

    if nSelectMain > nStimuli
        error('Not enough stimuli for main mem1 images. Need %d, found %d.', ...
            nSelectMain, nStimuli);
    end

    % Main mem1 images
    mem1ImageFiles = randperm(nStimuli, nSelectMain);
    mem1ImagePaths = stimuliPaths(mem1ImageFiles);
    mem1ImagePaths = mem1ImagePaths(randperm(numel(mem1ImagePaths)));

    combinedMem1ImagePaths = repelem(reshape(mem1ImagePaths, nSeriesMain, 3), 6, 1);

    % Main mem2 images from remaining main pool
    mem2ImagePaths = setdiff(stimuliPaths, mem1ImagePaths, 'stable');

    nMem2Needed = nTrials;
    nMem2Unique = numel(mem2ImagePaths);

    baseReps = floor(nMem2Needed / nMem2Unique);
    extraReps = mod(nMem2Needed, nMem2Unique);

    combinedMem2ImagePaths = repelem(mem2ImagePaths(:), baseReps, 1);

    if extraReps > 0
        extraImages = mem2ImagePaths(randperm(nMem2Unique, extraReps));
        combinedMem2ImagePaths = [combinedMem2ImagePaths; extraImages(:)];
    end

    %% ===================== CONSTRAINED MAIN MEM2 SHUFFLING =====================

    minGap = 60;
    minColorGap = 30;

    maxRestarts = 5000;
    triesPerImage = 2000;

    colorsMatMainOnly = colorsMatMain(1:nTrials);

    [uniqueImgs, ~, imgID] = unique(combinedMem2ImagePaths, 'stable');
    counts = accumarray(imgID, 1);

    if numel(combinedMem2ImagePaths) ~= nTrials
        error('Mem2 count mismatch: %d image entries for %d main trials.', ...
            numel(combinedMem2ImagePaths), nTrials);
    end

    success = false;

    for restart = 1:maxRestarts

        newOrder = cell(nTrials, 1);
        emptyPos = 1:nTrials;
        failed = false;

        imageOrder = randperm(numel(uniqueImgs));

        for ii = 1:numel(imageOrder)

            imgIdx = imageOrder(ii);
            nRep = counts(imgIdx);
            pos = [];

            for attempt = 1:triesPerImage

                candidate = sort(emptyPos(randperm(numel(emptyPos), nRep)));

                positionGapOK = all(diff(candidate) >= minGap);

                if ~positionGapOK
                    continue;
                end

                thisColors = colorsMatMainOnly(candidate);

                D = abs(thisColors - thisColors');
                circD = min(D, 360 - D);

                circD(logical(eye(size(circD)))) = Inf;

                colorGapOK = all(circD(:) >= minColorGap);

                if colorGapOK
                    pos = candidate;
                    break;
                end
            end

            if isempty(pos)
                failed = true;
                break;
            end

            newOrder(pos) = uniqueImgs(imgIdx);
            emptyPos = setdiff(emptyPos, pos);
        end

        if failed
            continue;
        end

        combinedMem2ImagePaths = newOrder(:);

        success = true;
        fprintf('Valid MAIN image + color solution found at restart %d\n', restart);
        break;
    end

    if ~success
        error('Could not construct valid MAIN ordering with both constraints.');
    end

    imageMatrix = cell(nTrials, 4);
    imageMatrix(:,1) = combinedMem1ImagePaths(:,1);   
    imageMatrix(:,2) = combinedMem1ImagePaths(:,2);   
    imageMatrix(:,3) = combinedMem1ImagePaths(:,3);   
    imageMatrix(:,4) = combinedMem2ImagePaths;

    %% ===================== TRAINING IMAGES =====================

    trainingStimuliFiles = dir(fullfile(trainingStimuliDIR, '*.png'));
    trainingStimuliPaths = fullfile({trainingStimuliFiles.folder}, {trainingStimuliFiles.name});

    trainingImageCount = numel(trainingStimuliPaths);

    if trainingImageCount < 36
        error('Training image pool needs at least 36 images. Found %d.', trainingImageCount);
    end

    % Original logic: 24 base training rows, then extend to 60 rows.
    nTrainingBaseTrials = 24;

    % Triplet images: 12 images = 4 series x 3 mem1 items
    trainingMem1ImagePaths = trainingStimuliPaths(randperm(trainingImageCount, 12));

    % Singular images from remaining training pool
    trainingMem2ImagePaths = setdiff(trainingStimuliPaths, trainingMem1ImagePaths, 'stable');
    trainingMem2ImagePaths = trainingMem2ImagePaths(randperm(numel(trainingMem2ImagePaths)));

    if numel(trainingMem2ImagePaths) < nTrainingBaseTrials
        error('Not enough training mem2 images. Need %d, found %d.', ...
            nTrainingBaseTrials, numel(trainingMem2ImagePaths));
    end

    trainingMem1ImagePaths = repelem(reshape(trainingMem1ImagePaths, 4, 3), 6, 1);
    trainingMem2ImagePaths = trainingMem2ImagePaths(1:nTrainingBaseTrials)';

    combinedTrainingImagePaths = [trainingMem1ImagePaths trainingMem2ImagePaths];

    combinedTrainingImagePathsExtend = ...
        combinedTrainingImagePaths(randperm(size(combinedTrainingImagePaths,1)), :);

    combinedTrainingImagePathsExtend2 = ...
        combinedTrainingImagePaths(randperm(size(combinedTrainingImagePaths,1)), :);

    finalTrainingImagePaths = [combinedTrainingImagePaths; ...
        combinedTrainingImagePathsExtend; ...
        combinedTrainingImagePathsExtend2(1:size(combinedTrainingImagePathsExtend2,1)/2, :)];

    if size(finalTrainingImagePaths,1) ~= nTrialsTrain
        error('Training image matrix has %d rows, expected %d.', ...
            size(finalTrainingImagePaths,1), nTrialsTrain);
    end

    trainingImageMatrix = cell(nTrialsTrain, 4);
    trainingImageMatrix(:,1) = finalTrainingImagePaths(:,1);   
    trainingImageMatrix(:,2) = finalTrainingImagePaths(:,2);   
    trainingImageMatrix(:,3) = finalTrainingImagePaths(:,3);   
    trainingImageMatrix(:,4) = finalTrainingImagePaths(:,4);  

    %% ===================== STORE COLORS =====================

    conditionMatrix(:,3) = reshape(repmat(colorsMat(1,:), 6, 1), nTrialsTotal, 1);
    conditionMatrix(:,4) = reshape(repmat(colorsMat(2,:), 6, 1), nTrialsTotal, 1);
    conditionMatrix(:,5) = reshape(repmat(colorsMat(3,:), 6, 1), nTrialsTotal, 1);
    conditionMatrix(:,6) = reshape(colorsMat(4:9,:), nTrialsTotal, 1);

    %% ===================== LOCATION ASSIGNMENT =====================

    rotations = zeros(nSeriesTotal, 1);
    spatialOffset = 45;

    rotations(1) = randi([0 359]);
    locationSpace = 0:359;

    for theta = 2:nSeriesTotal
        shadedRange = mod(rotations(theta-1)-spatialOffset : rotations(theta-1)+spatialOffset, 360);
        remSpace = setdiff(locationSpace, shadedRange, "stable");
        rotations(theta) = remSpace(randi(numel(remSpace)));
    end

    rotations = repelem(rotations, 6, 1);
    conditionMatrix(:,7) = rotations;

    %% ===================== TRIPLET TESTING ASSIGNMENT =====================

    orderVec = [];

    for testOrder = 1:nSeriesTotal
        forcedTest = 1:3;
        randTestValue = randi(3, 1, 3);

        testValues = [forcedTest, randTestValue];
        testValues = testValues(randperm(length(testValues)));

        orderVec = [orderVec; testValues]; 
    end

    conditionMatrix(:,8) = reshape(orderVec', nTrialsTotal, 1);

    %% ===================== SPLIT TRAINING FROM CONDITION MATRIX =====================

    trainingMatrix = conditionMatrix(end-59:end, :);
    conditionMatrix(end-59:end, :) = [];

    %% ===================== TRAINING CONTEXT OVERRIDE =====================

    trainingContext = [0 NaN NaN NaN 1 NaN 1 NaN NaN NaN 0 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN]';

    trainingMatrix(:,2) = trainingContext;

    %% ===================== FINAL SANITY CHECKS =====================

    if size(conditionMatrix,1) ~= nTrials
        error('Main conditionMatrix has %d rows, expected %d.', ...
            size(conditionMatrix,1), nTrials);
    end

    if size(trainingMatrix,1) ~= nTrialsTrain
        error('trainingMatrix has %d rows, expected %d.', ...
            size(trainingMatrix,1), nTrialsTrain);
    end

    if size(imageMatrix,1) ~= nTrials
        error('Main imageMatrix has %d rows, expected %d.', ...
            size(imageMatrix,1), nTrials);
    end

    if size(trainingImageMatrix,1) ~= nTrialsTrain
        error('trainingImageMatrix has %d rows, expected %d.', ...
            size(trainingImageMatrix,1), nTrialsTrain);
    end

    %% ===================== SAVE =====================

    saveFolder = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\imperil6ConditionFilesV2';
    saveFolderTraining = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\imperil6ConditionFilesTrainingV2';

    currentLabel = sprintf('imperil6cond%dV2.mat', condFile);
    currentLabelTrain = sprintf('imperil6TrainCond%dV2.mat', condFile);

    fullPath = fullfile(saveFolder, currentLabel);
    fullPathTrain = fullfile(saveFolderTraining, currentLabelTrain);

    save(fullPath, 'conditionMatrix', 'imageMatrix');
    save(fullPathTrain, 'trainingMatrix', 'trainingImageMatrix');

end

%% Cols:
% Col 1: Repetition counter
% Col 2: Context change vals
% Col 3: Memory Array 1 Item 1 color
% Col 4: Memory Array 1 Item 2 color
% Col 5: Memory Array 1 Item 3 color
% Col 6: Memory Array 2 color
% Col 7: Memory Array 1 rotation angle
% Col 8: Mem 1 item to test at Probe 2