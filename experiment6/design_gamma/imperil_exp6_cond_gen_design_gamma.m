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

nTrials = 900; % Can be 480, 600 or 720
computerHandle = 1; % 0 for ali's pc, 1 for the experiment comp, 2 for the gamma computer

if computerHandle == 0
    condDest = '/Users/ali/Desktop/visual imperil project/imperil6materials/imperil6ConditionFiles';
    stimuliDIR = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/TestObjectsTransparentExtended'; 
    trainingStimuliDIR = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/trainingStimuliExp6';
elseif computerHandle == 1
    stimuliDIR = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma\TestObjectsTransparentExtended'; 
    trainingStimuliDIR = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma\trainingStimuliExp6';
elseif computerHandle == 2
    condDest = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - imperil6\imperil6ConditionFiles';
end

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
% There are nSeriesMain miniblocks.
% Each miniblock gets 3 repeated images.
mem1ImageFiles = randperm(nStimuli, nSelectMain);
mem1ImagePaths = stimuliPaths(mem1ImageFiles);
mem1ImagePaths = mem1ImagePaths(randperm(numel(mem1ImagePaths)));

% nSeriesMain x 3, then repeat each row for 6 trials
combinedMem1ImagePaths = repelem(reshape(mem1ImagePaths, nSeriesMain, 3), 6, 1);

% Main mem2 images reuse the same main image pool.
% Each image appears twice across nTrials as the non-repeating item.
mem2ImagePaths = mem1ImagePaths(randperm(numel(mem1ImagePaths)));

nMem2Needed = nTrials;
nMem2Unique = numel(mem2ImagePaths);

combinedMem2ImagePaths = repelem(mem2ImagePaths(:), 2, 1);

if numel(combinedMem2ImagePaths) ~= nTrials
    error('Mem2 count mismatch: %d image entries for %d main trials.', ...
        numel(combinedMem2ImagePaths), nTrials);
end

%% ===================== CONSTRAINED MAIN MEM2 SHUFFLING =====================

minGap = 60;
minColorGap = 40;

maxRestarts = 5000;
triesPerImage = 2000;

colorsMatMainOnly = colorsMatMain(1:nTrials);

[uniqueImgs, ~, imgID] = unique(combinedMem2ImagePaths, 'stable');
counts = accumarray(imgID, 1);

if numel(uniqueImgs) ~= nMem2Unique
    error('Unexpected number of unique mem2 images: %d instead of %d.', ...
        numel(uniqueImgs), nMem2Unique);
end

if any(counts ~= 2)
    error('Each mem2 image should appear exactly twice, but counts are not all 2.');
end

success = false;

for restart = 1:maxRestarts

    newOrder = cell(nTrials, 1);
    emptyPos = 1:nTrials;
    failed = false;

    imageOrder = randperm(numel(uniqueImgs));

    for ii = 1:numel(imageOrder)

        imgIdx = imageOrder(ii);
        curImg = uniqueImgs(imgIdx);
        nRep = counts(imgIdx);
        pos = [];

        % Find all main repeated-item positions for this same image.
        % Since the image is a mem1 repeated image, this should usually be
        % the 6 trials of its own miniblock.
        mem1PositionsForCurImg = find( ...
            strcmp(combinedMem1ImagePaths(:,1), curImg) | ...
            strcmp(combinedMem1ImagePaths(:,2), curImg) | ...
            strcmp(combinedMem1ImagePaths(:,3), curImg) ...
        );

        if isempty(mem1PositionsForCurImg)
            error('Image appears in mem2 pool but not in mem1 pool.');
        end

        for attempt = 1:triesPerImage

            candidate = sort(emptyPos(randperm(numel(emptyPos), nRep)));

            %% ---------- Constraint 1: same mem2 image instances far apart ----------

            positionGapOK = all(diff(candidate) >= minGap);

            if ~positionGapOK
                continue;
            end

            %% ---------- Constraint 2: same mem2 image has sufficiently different colors ----------

            thisColors = colorsMatMainOnly(candidate);

            D = abs(thisColors - thisColors');
            circD = min(D, 360 - D);

            circD(logical(eye(size(circD)))) = Inf;

            colorGapOK = all(circD(:) >= minColorGap);

            if ~colorGapOK
                continue;
            end

            %% ---------- Constraint 3: mem2 image cannot overlap with mem1 images in same 6-trial miniblock ----------

            miniblockOK = true;

            for cc = 1:numel(candidate)

                curTrial = candidate(cc);

                % Find the 6-trial miniblock containing this trial
                curSeries = ceil(curTrial / 6);

                blockStart = (curSeries - 1) * 6 + 1;
                blockEnd   = curSeries * 6;

                % The three repeated mem1 images in this miniblock
                blockMem1Imgs = combinedMem1ImagePaths(blockStart:blockEnd, :);

                % Since mem1 images are repeated across the 6 trials,
                % unique() just gives the 3 images for this miniblock.
                blockMem1Imgs = unique(blockMem1Imgs(:), 'stable');

                % Current mem2 image must not be one of those 3 repeated images
                if any(strcmp(curImg, blockMem1Imgs))
                    miniblockOK = false;
                    break;
                end
            end

            if ~miniblockOK
                continue;
            end

            %% ---------- Constraint 4: mem2 image must be far from its own mem1 block ----------

            mem1Mem2Distances = abs(candidate(:) - mem1PositionsForCurImg(:)');
            mem1Mem2GapOK = all(mem1Mem2Distances(:) >= minGap);

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

        newOrder(pos) = curImg;
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

imageMatrix = cell(nTrials, 4);

imageMatrix(:,1) = combinedMem1ImagePaths(:,1);
imageMatrix(:,2) = combinedMem1ImagePaths(:,2);
imageMatrix(:,3) = combinedMem1ImagePaths(:,3);
imageMatrix(:,4) = combinedMem2ImagePaths;

%% ===================== DIAGNOSTIC CHECKS =====================

fprintf('\n===== MAIN IMAGE ASSIGNMENT DIAGNOSTICS =====\n');

%% Check mem2 counts

[uniqueMem2Final, ~, idMem2Final] = unique(imageMatrix(:,4), 'stable');
mem2CountsFinal = accumarray(idMem2Final, 1);

fprintf('Unique mem2 images: %d\n', numel(uniqueMem2Final));
fprintf('Min mem2 count: %d\n', min(mem2CountsFinal));
fprintf('Max mem2 count: %d\n', max(mem2CountsFinal));

if numel(uniqueMem2Final) ~= nMem2Unique
    error('Final mem2 unique image count is wrong.');
end

if any(mem2CountsFinal ~= 2)
    error('Final mem2 counts are not all exactly 2.');
end

%% Check gap between the two mem2 instances of each image

minObservedGap = Inf;

for ii = 1:numel(uniqueMem2Final)

    curPos = find(strcmp(imageMatrix(:,4), uniqueMem2Final(ii)));

    if numel(curPos) ~= 2
        error('Image %d appears %d times in mem2, expected 2.', ii, numel(curPos));
    end

    curGap = abs(diff(curPos));
    minObservedGap = min(minObservedGap, curGap);

    if curGap < minGap
        error('Mem2 spacing violation: image %d has gap %d.', ii, curGap);
    end
end

fprintf('Minimum observed mem2 spacing gap: %d trials\n', minObservedGap);

%% Check color gap between the two mem2 instances of each image

minObservedColorGap = Inf;

for ii = 1:numel(uniqueMem2Final)

    curPos = find(strcmp(imageMatrix(:,4), uniqueMem2Final(ii)));

    curColors = colorsMatMainOnly(curPos);

    D = abs(curColors(1) - curColors(2));
    circD = min(D, 360 - D);

    minObservedColorGap = min(minObservedColorGap, circD);

    if circD < minColorGap
        error('Mem2 color-gap violation: image %d has circular color gap %.2f.', ...
            ii, circD);
    end
end

fprintf('Minimum observed mem2 color gap: %.2f degrees\n', minObservedColorGap);

%% Check same-trial mem1/mem2 collision

sameTrialCollision = ...
    strcmp(imageMatrix(:,4), imageMatrix(:,1)) | ...
    strcmp(imageMatrix(:,4), imageMatrix(:,2)) | ...
    strcmp(imageMatrix(:,4), imageMatrix(:,3));

fprintf('Same-trial mem1/mem2 collisions: %d\n', sum(sameTrialCollision));

if any(sameTrialCollision)
    error('There are same-trial mem1/mem2 image collisions.');
end

%% Check 6-trial miniblock mem1/mem2 collision

miniblockCollisionCount = 0;

for s = 1:nSeriesMain

    blockStart = (s - 1) * 6 + 1;
    blockEnd   = s * 6;

    blockMem1Imgs = imageMatrix(blockStart:blockEnd, 1:3);
    blockMem1Imgs = unique(blockMem1Imgs(:), 'stable');

    blockMem2Imgs = imageMatrix(blockStart:blockEnd, 4);

    for mm = 1:numel(blockMem2Imgs)
        if any(strcmp(blockMem2Imgs(mm), blockMem1Imgs))
            miniblockCollisionCount = miniblockCollisionCount + 1;
        end
    end
end

fprintf('6-trial miniblock mem1/mem2 collisions: %d\n', miniblockCollisionCount);

if miniblockCollisionCount > 0
    error('There are mem1/mem2 image collisions within at least one 6-trial miniblock.');
end

%% Check spacing between each image's mem1 block and its mem2 appearances

minObservedMem1Mem2Gap = Inf;

for ii = 1:numel(uniqueMem2Final)

    curImg = uniqueMem2Final(ii);

    mem2Pos = find(strcmp(imageMatrix(:,4), curImg));

    mem1Pos = find( ...
        strcmp(imageMatrix(:,1), curImg) | ...
        strcmp(imageMatrix(:,2), curImg) | ...
        strcmp(imageMatrix(:,3), curImg) ...
    );

    if isempty(mem1Pos)
        error('Image appears in mem2 but not in mem1.');
    end

    D = abs(mem2Pos(:) - mem1Pos(:)');
    curMinGap = min(D(:));

    minObservedMem1Mem2Gap = min(minObservedMem1Mem2Gap, curMinGap);

    if curMinGap < minGap
        error('Mem1/mem2 spacing violation for image %d: minimum gap is %d trials.', ...
            ii, curMinGap);
    end
end

fprintf('Minimum observed mem1/mem2 same-image spacing gap: %d trials\n', ...
    minObservedMem1Mem2Gap);

fprintf('All MAIN image assignment checks passed.\n');
fprintf('============================================\n\n');

  %% ===================== TRAINING IMAGES =====================

trainingStimuliFiles = dir(fullfile(trainingStimuliDIR, '*.png'));
trainingStimuliPaths = fullfile({trainingStimuliFiles.folder}, {trainingStimuliFiles.name});

trainingImageCount = numel(trainingStimuliPaths);

if trainingImageCount < 36
    error('Training image pool needs at least 36 images. Found %d.', trainingImageCount);
end

if mod(nTrialsTrain, 6) ~= 0
    error('nTrialsTrain must be divisible by 6.');
end

nTrainingSeries = nTrialsTrain / 6;

% With 36 images:
%   4 base series
%   9 images per base series
%       - 3 repeated mem1 images
%       - 6 mem2 images
%
% Then reuse these 4 base series to fill the requested 10 training series.

nBaseTrainingSeries = 4;
nImagesPerTrainingSeries = 9;
nTrainingBaseImagesNeeded = nBaseTrainingSeries * nImagesPerTrainingSeries;

if trainingImageCount < nTrainingBaseImagesNeeded
    error('Training image pool needs at least %d images. Found %d.', ...
        nTrainingBaseImagesNeeded, trainingImageCount);
end

% Select exactly 36 images and shuffle their order.
trainingBasePool = trainingStimuliPaths(randperm(trainingImageCount, nTrainingBaseImagesNeeded));

% Reshape into 4 base training series, each with 9 images.
trainingBasePool = reshape(trainingBasePool, nBaseTrainingSeries, nImagesPerTrainingSeries);

% First 3 images of each base series are repeated mem1 images.
baseMem1BySeries = trainingBasePool(:, 1:3);

% Last 6 images of each base series are mem2 images.
baseMem2BySeries = trainingBasePool(:, 4:9);

% Decide which base series is used for each of the 10 actual training series.
% This preserves 6-trial miniblock structure while allowing reuse.
baseSeriesOrder = repmat(1:nBaseTrainingSeries, 1, ceil(nTrainingSeries / nBaseTrainingSeries));
baseSeriesOrder = baseSeriesOrder(1:nTrainingSeries);
baseSeriesOrder = baseSeriesOrder(randperm(numel(baseSeriesOrder)));

trainingImageMatrix = cell(nTrialsTrain, 4);

for s = 1:nTrainingSeries

    blockStart = (s - 1) * 6 + 1;
    blockEnd   = s * 6;

    curBaseSeries = baseSeriesOrder(s);

    curMem1Imgs = baseMem1BySeries(curBaseSeries, :);
    curMem2Imgs = baseMem2BySeries(curBaseSeries, :);

    % Optional: randomize the order of the six mem2 images within this
    % training miniblock each time the base series is reused.
    curMem2Imgs = curMem2Imgs(randperm(6));

    % Repeat the same 3 mem1 images across all 6 trials of this block.
    trainingImageMatrix(blockStart:blockEnd, 1) = repmat(curMem1Imgs(1), 6, 1);
    trainingImageMatrix(blockStart:blockEnd, 2) = repmat(curMem1Imgs(2), 6, 1);
    trainingImageMatrix(blockStart:blockEnd, 3) = repmat(curMem1Imgs(3), 6, 1);

    % One mem2 image per trial.
    trainingImageMatrix(blockStart:blockEnd, 4) = curMem2Imgs(:);
end

%% ===================== TRAINING IMAGE DIAGNOSTICS =====================

fprintf('\n===== TRAINING IMAGE ASSIGNMENT DIAGNOSTICS =====\n');

if size(trainingImageMatrix,1) ~= nTrialsTrain
    error('Training image matrix has %d rows, expected %d.', ...
        size(trainingImageMatrix,1), nTrialsTrain);
end

trainingMiniblockCollisionCount = 0;

for s = 1:nTrainingSeries

    blockStart = (s - 1) * 6 + 1;
    blockEnd   = s * 6;

    blockMem1Imgs = trainingImageMatrix(blockStart:blockEnd, 1:3);
    blockMem1Imgs = unique(blockMem1Imgs(:), 'stable');

    blockMem2Imgs = trainingImageMatrix(blockStart:blockEnd, 4);
    blockMem2Unique = unique(blockMem2Imgs, 'stable');

    % Check that there are exactly 3 repeated mem1 images in the miniblock.
    if numel(blockMem1Imgs) ~= 3
        error('Training miniblock %d does not have exactly 3 unique mem1 images.', s);
    end

    % Check that each mem1 image is repeated across all 6 trials.
    for jj = 1:3
        if numel(unique(trainingImageMatrix(blockStart:blockEnd, jj), 'stable')) ~= 1
            error('Training miniblock %d mem1 column %d is not constant across 6 trials.', ...
                s, jj);
        end
    end

    % Check that there are 6 unique mem2 images within the miniblock.
    if numel(blockMem2Unique) ~= 6
        error('Training miniblock %d does not have 6 unique mem2 images.', s);
    end

    % Check that mem2 does not overlap with the miniblock's mem1 images.
    for mm = 1:numel(blockMem2Imgs)
        if any(strcmp(blockMem2Imgs(mm), blockMem1Imgs))
            trainingMiniblockCollisionCount = trainingMiniblockCollisionCount + 1;
        end
    end
end

fprintf('Training base series used: %s\n', mat2str(baseSeriesOrder));
fprintf('Training 6-trial miniblock mem1/mem2 collisions: %d\n', ...
    trainingMiniblockCollisionCount);

if trainingMiniblockCollisionCount > 0
    error('There are training mem1/mem2 image collisions within at least one 6-trial miniblock.');
end

fprintf('All TRAINING image assignment checks passed.\n');
fprintf('================================================\n\n');

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
    % In this design, four images appear at encoding, and one is tested at
    % probing.

    mainTestOrder = NaN(nTrials,1);
    rep1ctx0 = find(conditionMatrix(:,2) == 0 & conditionMatrix(:,1) == 1);
    rep1ctx1 = find(conditionMatrix(:,2) == 1 & conditionMatrix(:,1) == 1);
    rep5ctx0 = find(conditionMatrix(:,2) == 0 & conditionMatrix(:,1) == 5);
    rep5ctx1 = find(conditionMatrix(:,2) == 1 & conditionMatrix(:,1) == 5);

    novelProb = 0.40;
    repeatedProb = 0.60;
    rep1Prob = 0.20;
    rep2Prob = 0.20;
    rep3Prob = 0.20;

    perCond = [repmat([1 2 3],1,nTrialsPCond*rep1Prob),repmat(4,1,nTrialsPCond*novelProb)];

    mainTestOrder(rep1ctx0) = perCond(randperm(length(perCond)));
    mainTestOrder(rep1ctx1) = perCond(randperm(length(perCond)));
    mainTestOrder(rep5ctx0) = perCond(randperm(length(perCond)));
    mainTestOrder(rep5ctx1) = perCond(randperm(length(perCond)));

    forcedTest = [1 2 3 4];
   
    for testOrder = 1:nSeriesMain
        % Constrained randomized allocation:

        % In each mini-block, all four must be tested at least once
        % In critical trials, all four must be tested equally

        % 75 trials per condition:
        % 30 trials -> novel item tested
        % 45 trials -> repeated item tested
        % 15 trials -> rep 1 item 
        % 15 trials -> rep 2 item
        % 15 trials -> rep 3 item

        if testOrder == 1

            randForcedTest = forcedTest(randperm(length(forcedTest)));
            mainTestOrder([2 3 4 6]) = randForcedTest;

        elseif testOrder >= 2

            randForcedTest = forcedTest(randperm(length(forcedTest)));

            mainTestOrder((testOrder-1)*6+2:(testOrder-1)*6+4) = randForcedTest(1:3);
            mainTestOrder((testOrder-1)*6+6) = randForcedTest(4);
        end

    end

    conditionMatrix(:,8) = mainTestOrder;

    %% Testing Assignment for Training
    % Same rules. So simply sample randomly from the main matrix.

    randSliceIdx = randperm(nSeriesMain, 10);   % choose 10 series without replacement
    
    trialIdx = (randSliceIdx(:)-1)*6 + (1:6);   % 10 x 6 matrix of trial indices
    trialIdx = trialIdx(:);                     % convert to 60 x 1 vector
    
    randSlices = mainTestOrder(trialIdx);
    
    trainingMatrix(:,8) = randSlices;

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

    saveFolder = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma\imperil6GammaConditionFiles';
    saveFolderTraining = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\design_gamma\imperil6GammaConditionFilesTraining';

    currentLabel = sprintf('imperil6Gammacond%d.mat', condFile);
    currentLabelTrain = sprintf('imperil6GammaTrainCond%d.mat', condFile);

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
% Col 8: Test Item Index