%% Imperil or Protect 6 - Condition Matrix Generator
% Coded by A.Y.

% Conception: 21.04.2026
% v1 - 23.04.2026: first version finalized
% v2 - 25.04.2026: Change of design: Mem 1 array items are now to be positioned 
% from each other at a fixed offset of 120°
% and this configuration should be rotated by a random
% theta at every series. 

% v3 - design beta - 18.05.2026
% v4 - design gamma - 22.05.2026
% v5 - design delta - 24.05.2026

nTrials = 900; % Can be 480, 600 or 720

%% Relevant DIRs

% Get the folder where this script is located
experimentRoot = fileparts(mfilename('fullpath'));

% Add all subfolders to MATLAB path
addpath(genpath(experimentRoot));

stimuliDIR = fullfile(experimentRoot, 'TestObjectsTransparentExtended');
trainingStimuliDIR = fullfile(experimentRoot, 'trainingStimuliExp6');

% Total number of repetition series to generate based on desired trial
% count. 720 total -> 120 series, nSeriesMain trials -> nSeriesMain series
% But always add 10 to the nSeriesMain. The extra 10 rep series is for the training.

%% ===================== BASIC COUNTS =====================

if nTrials == 720
    nSeriesMain = nTrials / 6;   
elseif nTrials == 600
    nSeriesMain = nTrials / 6; 
elseif nTrials == 480
    nSeriesMain = nTrials / 6; 
elseif nTrials == 900
    nSeriesMain = nTrials / 6;
    nTrialsPCond = nTrials/6/2;
else
    error('Unexpected nTrials value. nTrials must be 480, 600, or 720.');
end

nTrialsTrain = 60;
nSeriesTrain = nTrialsTrain / 6;

nTrialsTotal = nTrials + nTrialsTrain;
nSeriesTotal = nSeriesMain + nSeriesTrain;

rng('shuffle');

for condFile = 1:1

    %% ===================== REPETITION SEQUENCE =====================

    seriesSequence = (1:6)'; 
    longSequence = repmat(seriesSequence, nSeriesTotal, 1); 
  
    conditionMatrix = NaN(nTrialsTotal, 13); 
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
    
    nCoupleColors = 2;
    nMainColorsPerSeries = 6;
    nColorsPerSeries = nCoupleColors + nMainColorsPerSeries;  % 8
    
    while ~validSetFound && outerAttempts < maxOuterAttempts
        outerAttempts = outerAttempts + 1;
    
        colorsVec = [];
    
        for series = 1:nSeriesTotal
            colors = zeros(1, nColorsPerSeries);
    
            colors(1) = randi([0 359]);
    
            for k = 2:nColorsPerSeries
                colors(k) = mod(colors(k-1) + colorOffset, 360);
            end
    
            colors = colors(randperm(nColorsPerSeries));
            colorsVec = [colorsVec; colors(:)];
        end
    
        colorsMat = reshape(colorsVec, nColorsPerSeries, nSeriesTotal);
    
        maxInnerAttempts = 1000;
        validSetFound = true;
    
        for col = 1:(nSeriesTotal - 1)
    
            success = false;
            attempt = 0;
    
            while ~success && attempt < maxInnerAttempts
                attempt = attempt + 1;
    
                colorsMat(:, col+1) = colorsMat(randperm(nColorsPerSeries), col+1);
    
                prevCouple = colorsMat(1:2, col);
                nextCouple = colorsMat(1:2, col+1);
    
                D = abs(prevCouple - nextCouple');
                circD = min(D, 360 - D);
    
                coupleOK = all(circD(:) >= colorOffset);
    
                prevLast = colorsMat(end, col);
                nextFirst = colorsMat(nCoupleColors + 1, col+1);
    
                D2 = abs(prevLast - nextFirst);
                circD2 = min(D2, 360 - D2);
    
                array2OK = circD2 >= colorOffset;
    
                success = coupleOK && array2OK;
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
    
    colorsMatMain = reshape(colorsMat((nCoupleColors + 1):end, :), nTrialsTotal, 1);

  %% ===================== MAIN IMAGE ASSIGNMENT =====================

stimuliFiles = dir(fullfile(stimuliDIR, '*.png'));
stimuliPaths = fullfile({stimuliFiles.folder}, {stimuliFiles.name});

nStimuli = numel(stimuliPaths);

nMem1PerSeries = 2;     % couple images
nTrialsPerSeries = 6;   % 6-trial streak/miniblock

nSelectMain = nSeriesMain * nMem1PerSeries;

if nSelectMain > nStimuli
    error('Not enough stimuli for main mem1 couple images. Need %d, found %d.', ...
        nSelectMain, nStimuli);
end

if nTrials ~= nSeriesMain * nTrialsPerSeries
    error('nTrials mismatch: expected nSeriesMain * %d = %d, but nTrials = %d.', ...
        nTrialsPerSeries, nSeriesMain * nTrialsPerSeries, nTrials);
end

%% ---------- Main mem1/couple images ----------

% Select 300 images for couples if nSeriesMain = 150.
mem1ImageFiles = randperm(nStimuli, nSelectMain);
mem1ImagePaths = stimuliPaths(mem1ImageFiles);

% Randomize order before assigning to streaks.
mem1ImagePaths = mem1ImagePaths(randperm(numel(mem1ImagePaths)));

% nSeriesMain x 2, then repeat each row for 6 trials.
% Each streak/miniblock has 2 repeated/couple images.
combinedMem1ImagePaths = repelem( ...
    reshape(mem1ImagePaths, nSeriesMain, nMem1PerSeries), ...
    nTrialsPerSeries, ...
    1 ...
);

if size(combinedMem1ImagePaths, 1) ~= nTrials
    error('Mem1 row count mismatch: %d rows for %d main trials.', ...
        size(combinedMem1ImagePaths, 1), nTrials);
end

%% ---------- Main mem2/third-image stream ----------

% Images NOT used as couples.
remainingImageFiles = setdiff(1:nStimuli, mem1ImageFiles);

% For 450 total images and 300 couple images, this should be 150.
nRemaining = numel(remainingImageFiles);

fprintf('Couple images used: %d\n', numel(mem1ImageFiles));
fprintf('Images initially available for third-image stream: %d\n', nRemaining);

% First burn through the images that were not used as couple images.
firstPassFiles = remainingImageFiles(randperm(nRemaining));

% Then recycle/reset the entire 450-image pool as many times as needed.
nStillNeeded = nTrials - numel(firstPassFiles);

if nStillNeeded < 0
    error('More remaining images than needed third-image slots.');
end

recycledFiles = [];

while numel(recycledFiles) < nStillNeeded
    recycledFiles = [recycledFiles, randperm(nStimuli)];
end

recycledFiles = recycledFiles(1:nStillNeeded);

% Final third-image pool has exactly one image per trial.
mem2ImageFiles = [firstPassFiles, recycledFiles];

if numel(mem2ImageFiles) ~= nTrials
    error('Mem2 count mismatch: %d image entries for %d main trials.', ...
        numel(mem2ImageFiles), nTrials);
end

combinedMem2ImagePaths = stimuliPaths(mem2ImageFiles);
combinedMem2ImagePaths = combinedMem2ImagePaths(:);

%% ===================== CONSTRAINED MAIN MEM2 SHUFFLING =====================

minGap = 60;
minColorGap = colorOffset;

maxRestarts = 5000;
triesPerImage = 2000;

colorsMatMainOnly = colorsMatMain(1:nTrials);

[uniqueImgs, ~, imgID] = unique(combinedMem2ImagePaths, 'stable');
counts = accumarray(imgID, 1);

if sum(counts) ~= nTrials
    error('Mem2 count mismatch after unique/counts step: %d entries for %d trials.', ...
        sum(counts), nTrials);
end

fprintf('Unique third-image identities: %d\n', numel(uniqueImgs));
fprintf('Third-image occurrence range: min = %d, max = %d\n', min(counts), max(counts));

success = false;

for restart = 1:maxRestarts

    newOrder = cell(nTrials, 1);
    emptyPos = 1:nTrials;
    failed = false;

    % Place the most frequent images first because they are hardest to fit.
    [~, sortIdx] = sort(counts, 'descend');
    imageOrder = sortIdx(randperm(numel(sortIdx)));

    for ii = 1:numel(imageOrder)

        imgIdx = imageOrder(ii);
        curImg = uniqueImgs(imgIdx);
        nRep = counts(imgIdx);
        pos = [];

        % Find all repeated/couple positions for this same image.
        % This will be empty for images that were not selected as couple images.
        mem1PositionsForCurImg = find( ...
            strcmp(combinedMem1ImagePaths(:,1), curImg) | ...
            strcmp(combinedMem1ImagePaths(:,2), curImg) ...
        );

        for attempt = 1:triesPerImage

            if numel(emptyPos) < nRep
                break;
            end

            candidate = sort(emptyPos(randperm(numel(emptyPos), nRep)));

            %% ---------- Constraint 1: same third image instances far apart ----------

            if nRep > 1
                positionGapOK = all(diff(candidate) >= minGap);
            else
                positionGapOK = true;
            end

            if ~positionGapOK
                continue;
            end

            %% ---------- Constraint 2: same third image has sufficiently different colors ----------

            if nRep > 1
                thisColors = colorsMatMainOnly(candidate);

                D = abs(thisColors - thisColors');
                circD = min(D, 360 - D);

                circD(logical(eye(size(circD)))) = Inf;

                colorGapOK = all(circD(:) >= minColorGap);
            else
                colorGapOK = true;
            end

            if ~colorGapOK
                continue;
            end

            %% ---------- Constraint 3: third image cannot overlap with couple images in same 6-trial miniblock ----------

            miniblockOK = true;

            for cc = 1:numel(candidate)

                curTrial = candidate(cc);

                % Find the 6-trial miniblock containing this trial.
                curSeries = ceil(curTrial / nTrialsPerSeries);

                blockStart = (curSeries - 1) * nTrialsPerSeries + 1;
                blockEnd   = curSeries * nTrialsPerSeries;

                % The two repeated/couple images in this miniblock.
                blockMem1Imgs = combinedMem1ImagePaths(blockStart:blockEnd, :);

                % unique() gives the 2 couple images for this miniblock.
                blockMem1Imgs = unique(blockMem1Imgs(:), 'stable');

                % Current third image must not be one of those 2 couple images.
                if any(strcmp(curImg, blockMem1Imgs))
                    miniblockOK = false;
                    break;
                end
            end

            if ~miniblockOK
                continue;
            end

            %% ---------- Constraint 4: third image must be far from its own couple block ----------

            % This only applies if the current third image was also one of the
            % couple images somewhere in the experiment.
            if ~isempty(mem1PositionsForCurImg)
                mem1Mem2Distances = abs(candidate(:) - mem1PositionsForCurImg(:)');
                mem1Mem2GapOK = all(mem1Mem2Distances(:) >= minGap);
            else
                mem1Mem2GapOK = true;
            end

            if ~mem1Mem2GapOK
                continue;
            end

            %% ---------- If all constraints passed, accept candidate positions ----------

            pos = candidate;
            break;
        end

        if isempty(pos)
            failed = true;
            break;
        end

        newOrder(pos) = repmat(curImg, numel(pos), 1);
        emptyPos = setdiff(emptyPos, pos);
    end

    if failed
        continue;
    end

    combinedMem2ImagePaths = newOrder(:);

    success = true;
    fprintf('Valid MAIN image + color + miniblock + mem1/mem2 spacing solution found at restart %d\n', restart);
    break;
end

if ~success
    error('Could not construct valid MAIN ordering with all constraints.');
end

%% ===================== BUILD FINAL IMAGE MATRIX =====================

imageMatrix = cell(nTrials, 3);

imageMatrix(:,1) = combinedMem1ImagePaths(:,1);
imageMatrix(:,2) = combinedMem1ImagePaths(:,2);
imageMatrix(:,3) = combinedMem2ImagePaths;

  %% ===================== TRAINING IMAGES =====================%% ===================== TRAINING IMAGE ASSIGNMENT =====================

trainingStimuliFiles = dir(fullfile(trainingStimuliDIR, '*.png'));
trainingStimuliPaths = fullfile({trainingStimuliFiles.folder}, {trainingStimuliFiles.name});

trainingImageCount = numel(trainingStimuliPaths);

if trainingImageCount < 32
    error('Training image pool needs at least 32 images. Found %d.', trainingImageCount);
end

if mod(nTrialsTrain, 6) ~= 0
    error('nTrialsTrain must be divisible by 6.');
end

nTrainingSeries = nTrialsTrain / 6;

% With 32 images:
%   4 base series
%   8 images per base series
%       - 2 repeated mem1 images
%       - 6 mem2 images
%
% Then reuse these 4 base series to fill the requested training series.

nBaseTrainingSeries = 4;
nMem1PerTrainingSeries = 2;
nMem2PerTrainingSeries = 6;
nImagesPerTrainingSeries = nMem1PerTrainingSeries + nMem2PerTrainingSeries;

nTrainingBaseImagesNeeded = nBaseTrainingSeries * nImagesPerTrainingSeries;

if trainingImageCount < nTrainingBaseImagesNeeded
    error('Training image pool needs at least %d images. Found %d.', ...
        nTrainingBaseImagesNeeded, trainingImageCount);
end

% Select exactly 32 images and shuffle their order.
trainingBasePool = trainingStimuliPaths(randperm(trainingImageCount, nTrainingBaseImagesNeeded));

% Reshape into 4 base training series, each with 8 images.
trainingBasePool = reshape(trainingBasePool, nBaseTrainingSeries, nImagesPerTrainingSeries);

% First 2 images of each base series are repeated mem1 images.
baseMem1BySeries = trainingBasePool(:, 1:nMem1PerTrainingSeries);

% Last 6 images of each base series are mem2 images.
baseMem2BySeries = trainingBasePool(:, (nMem1PerTrainingSeries + 1):end);

% Decide which base series is used for each actual training series.
% This preserves 6-trial miniblock structure while allowing reuse.
baseSeriesOrder = repmat(1:nBaseTrainingSeries, 1, ceil(nTrainingSeries / nBaseTrainingSeries));
baseSeriesOrder = baseSeriesOrder(1:nTrainingSeries);
baseSeriesOrder = baseSeriesOrder(randperm(numel(baseSeriesOrder)));

% Columns:
%   1 = repeated mem1 image 1
%   2 = repeated mem1 image 2
%   3 = trial-specific mem2 image
trainingImageMatrix = cell(nTrialsTrain, 3);

for s = 1:nTrainingSeries

    blockStart = (s - 1) * 6 + 1;
    blockEnd   = s * 6;

    curBaseSeries = baseSeriesOrder(s);

    curMem1Imgs = baseMem1BySeries(curBaseSeries, :);
    curMem2Imgs = baseMem2BySeries(curBaseSeries, :);

    % Randomize the order of the six mem2 images within this training
    % miniblock each time the base series is reused.
    curMem2Imgs = curMem2Imgs(randperm(nMem2PerTrainingSeries));

    % Repeat the same 2 mem1 images across all 6 trials of this block.
    trainingImageMatrix(blockStart:blockEnd, 1) = repmat(curMem1Imgs(1), 6, 1);
    trainingImageMatrix(blockStart:blockEnd, 2) = repmat(curMem1Imgs(2), 6, 1);

    % One mem2 image per trial.
    trainingImageMatrix(blockStart:blockEnd, 3) = curMem2Imgs(:);
end

  %% ===================== STORE COLORS =====================

if size(conditionMatrix, 1) ~= nTrialsTotal
    error('conditionMatrix has %d rows, but nTrialsTotal is %d.', ...
        size(conditionMatrix, 1), nTrialsTotal);
end

if nTrialsTotal ~= nSeriesTotal * 6
    error('nTrialsTotal must equal nSeriesTotal * 6.');
end

conditionMatrix(:,3) = reshape(repmat(colorsMat(1,:), 6, 1), nTrialsTotal, 1);
conditionMatrix(:,4) = reshape(repmat(colorsMat(2,:), 6, 1), nTrialsTotal, 1);
conditionMatrix(:,5) = reshape(colorsMat((nCoupleColors + 1):end, :), nTrialsTotal, 1);


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
    conditionMatrix(:,6) = rotations;

    %% ===================== SPLIT TRAINING FROM CONDITION MATRIX =====================

    trainingMatrix = conditionMatrix(end-59:end, :);
    conditionMatrix(end-59:end, :) = [];
    
    %% ===================== MAIN CONTEXT REBALANCING =====================
    
    conditionMatrix(conditionMatrix(:,1) == 1, 2) = NaN;
    conditionMatrix(conditionMatrix(:,1) == 5, 2) = NaN;
    
    rep1idx = find(conditionMatrix(:,1) == 1);
    rep5idx = find(conditionMatrix(:,1) == 5);
    
    nRep1 = numel(rep1idx);
    nRep5 = numel(rep5idx);
    
    rep1conds = [zeros(nRep1/2, 1); ones(nRep1/2, 1)];
    rep5conds = [zeros(nRep5/2, 1); ones(nRep5/2, 1)];
    
    conditionMatrix(rep1idx, 2) = rep1conds(randperm(nRep1));
    conditionMatrix(rep5idx, 2) = rep5conds(randperm(nRep5));
    
    %% ===================== TRAINING CONTEXT OVERRIDE =====================
    
    trainingContext = [0 NaN NaN NaN 1 NaN 1 NaN NaN NaN 0 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN ...
                       1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN]';
    
    trainingMatrix(:,2) = trainingContext;


    %% TESTING ASSIGNMENT
    % In this design, three images appear at encoding, and one is tested at
    % probing.

    % Constrained randomized allocation:

    % In critical trials (reps 1 & 5), all three must be tested at fixed
    % probs

    % 75 trials per condition:
    % 30 trials -> novel item tested
    % 45 trials -> repeated item tested
    % 22 or 23 trials -> rep 1 item 
    % 22 or 23 trials -> rep 2 item

    mainTestOrder = NaN(nTrials,1);

    novelProb = 0.40;
    repeatedProb = 0.60;
    rep1Prob = 0.30;
    rep2Prob = 0.30;

    rep1ctx0 = find(conditionMatrix(:,2) == 0 & conditionMatrix(:,1) == 1);
    rep1ctx1 = find(conditionMatrix(:,2) == 1 & conditionMatrix(:,1) == 1);
    rep5ctx0 = find(conditionMatrix(:,2) == 0 & conditionMatrix(:,1) == 5);
    rep5ctx1 = find(conditionMatrix(:,2) == 1 & conditionMatrix(:,1) == 5);

    novelItemVals = repmat(3,1,nTrialsPCond*novelProb);
    repItemValsCond1 = [repmat(1,1,23),repmat(2,1,22)];
    repItemValsCond2 = [repmat(1,1,22),repmat(2,1,23)];
    repItemValsCond3 = [repmat(1,1,23),repmat(2,1,22)];
    repItemValsCond4 = [repmat(1,1,22),repmat(2,1,23)];

    perCond1 = [repItemValsCond1';novelItemVals'];
    perCond2 = [repItemValsCond2';novelItemVals'];
    perCond3 = [repItemValsCond3';novelItemVals'];
    perCond4 = [repItemValsCond4';novelItemVals'];

    mainTestOrder(rep1ctx0) = perCond1(randperm(length(perCond1)));
    mainTestOrder(rep1ctx1) = perCond2(randperm(length(perCond2)));
    mainTestOrder(rep5ctx0) = perCond3(randperm(length(perCond3)));
    mainTestOrder(rep5ctx1) = perCond4(randperm(length(perCond4)));

    remTrials = nTrials - nTrialsPCond*4;
    remNovel = repmat(3,1,remTrials*novelProb);
    remRep1 = repmat(1,1,remTrials*rep1Prob);
    remRep2 = repmat(2,1,remTrials*rep2Prob);
   
    allRemTestIdx = [remNovel';remRep1';remRep2'];
    allRemTestIdx = allRemTestIdx(randperm(length(allRemTestIdx)));

    for testOrder = 1:nSeriesMain
  
        nonCriticalTrials = [2 3 4 6];

        if testOrder == 1

            curQuad = allRemTestIdx(end-3:end);
            mainTestOrder(nonCriticalTrials) = curQuad;

            allRemTestIdx(end-3:end) = [];

        elseif testOrder >= 2

            curQuad = allRemTestIdx(end-3:end);
   

            mainTestOrder((testOrder-1)*6+2:(testOrder-1)*6+4) = curQuad(1:3);
            mainTestOrder((testOrder-1)*6+6) = curQuad(4);
           
            allRemTestIdx(end-3:end) = [];

        end

    end

    conditionMatrix(:,7) = mainTestOrder;

    %% Testing Assignment for Training
    % Same rules. So simply sample randomly from the main matrix.

    randSliceIdx = randperm(nSeriesMain, 10);   % choose 10 series without replacement
    
    trialIdx = (randSliceIdx(:)-1)*6 + (1:6);   % 10 x 6 matrix of trial indices
    trialIdx = trialIdx(:);                     % convert to 60 x 1 vector
    
    randSlices = mainTestOrder(trialIdx);
    
    trainingMatrix(:,7) = randSlices;

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

    %% Rewrite image names

    % Loop over trials
    for rewrite = 1:nTrials

        curRow = imageMatrix(:,rewrite);
        
        % Loop over each memory item
        for item = 1:3

            frontEnd = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_delta\TestObjectsTransparentExtended\obj';
            backEnd = '-resized.png';
            
            curRow = erase(curRow(item), frontEnd); curRow = erase(curRow(item), backEnd);
            curColor = num2str(conditionMatrix(rewrite,2+item));
            
            newName = 'stim_'+ curRow(item) + '_deg_' + curColor + '.png';

            curRow(item) = newName;
        end
        
        imageMatrix(:, rewrite) = curRow;
    end

    %% Spell out item location coordinates

    wheelRadius = 225;
    
    % Returns x and y coordinates
    coords = @(degs) [wheelRadius * cos(deg2rad(degs)), -wheelRadius * sin(deg2rad(degs))];

    rotateRads = NaN(nTrials, 6);

    for thetas = 1:nTrials

        % Get rotation increment
        curTheta = conditionMatrix(thetas,6);

        % Compute rotated cart coordinates
        rotateRep1 = coords(0+curTheta);
        rotateRep2 = coords(120+curTheta);
        rotateNovel = coords(240+curTheta);

        % Add the results to the condition matrix
        conditionMatrix(thetas,8:9) = rotateRep1(:);
        conditionMatrix(thetas,10:11) = rotateRep2(:);
        conditionMatrix(thetas,12:13) = rotateNovel(:);
    end

    %% ===================== SAVE =====================

    % saveFolder = fullfile(experimentRoot, 'imperil6DeltaConditionFiles');
    % saveFolderTraining = fullfile(experimentRoot, 'imperil6DeltaConditionFilesTraining');
    % 
    % currentLabel = sprintf('imperil6Deltacond%d.mat', condFile);
    % currentLabelTrain = sprintf('imperil6DeltaTrainCond%d.mat', condFile);
    % 
    % fullPath = fullfile(saveFolder, currentLabel);
    % fullPathTrain = fullfile(saveFolderTraining, currentLabelTrain);
    % 
    % save(fullPath, 'conditionMatrix', 'imageMatrix');
    % save(fullPathTrain, 'trainingMatrix', 'trainingImageMatrix');

    %% Save the results in the JavaScript format
    fid = fopen('conditionMatrix.json', "w"); 
    fprintf(fid, '%s', jsonencode(conditionMatrix)); 
    fclose(fid);

    fid = fopen('imageMatrix.json', "w"); 
    fprintf(fid, '%s', jsonencode(imageMatrix)); 
    fclose(fid);
end

%% Cols:
% Col 1: Repetition counter
% Col 2: Context change vals
% Col 3: Memory Array 1 Item 1 color
% Col 4: Memory Array 1 Item 2 color
% Col 5: Memory Array 2 color
% Col 6: Memory Array rotation angle
% Col 7: Test Item Index


%% Cols: 
% CONDITION MATRIX:

% Col 1: Repetition counter
% Col 2: Context change vals
% Col 3: Repeated Item 1 color
% Col 4: Repeated Item 2 color
% Col 5: Novel Item color
% Col 6: Rotation angle
% Col 7: Probe index
% Col 8: Position 1 x coord
% Col 9: Position 1 y coord
% Col 10: Position 2 x coord
% Col 11: Position 2 y coord
% Col 12: Position 3 x coord
% Col 13: Position 3 y coord

% IMAGE MATRIX:
% Col 1: Repeated Item 1 DIR
% Col 2: Repeated Item 2 DIR
% Col 3: Novel Item DIR