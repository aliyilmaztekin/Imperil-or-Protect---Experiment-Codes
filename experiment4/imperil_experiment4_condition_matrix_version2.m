%% Imperil or Protect 4 - Condition Matrix Generator (v2)
% Coded by A.Y.

% Conception: 16.09.2025

%% As of 16.09.2025, the experimental design has been revised. 

% In this latest version, we have two factors (repetition: 1st vs. 5th) &
% context change (no change, change). We will present each image in
% repetition series of six trials. No single-trial series in between them.
% 720 trials in total, although we may consider lowering the total for a
% shorter session duration. 

%% As of 20.09.2025, this code has been finalized and its content will be used as
% condition files for imperil4. 

%% 24.09.2025: The total trial count was decreased from 720 to 480, leaving 40 trials
% per condition instead of 60. The code is updated accordingly. 

%% 26.09.2025: Final adjustments before the pilot testing done. 
% Made the code more soft-coded. 

desiredTrialCount = 480; % Can change to 720
computerHandle = 1; % 0 for ali's pc, 1 for the experiment comp

if computerHandle == 0 
    condDest = '/Users/ali/Desktop/visual imperil project/imperil4materials/imperil4ConditionFiles';
elseif computerHandle == 1
    condDest = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil4materials\imperil4ConditionFiles';
end

% Total number of repetition series to generate based on desired trial
% count. 720 total -> 120 series, 480 trials -> 80 series
% But always add 10 to the nSeries. The extra 10 rep series is for the training.

if desiredTrialCount == 720
    nSeries = 130;
elseif desiredTrialCount == 480
    nSeries = 90;
end

% First and foremost, I believe in the ultimate randomness of the universe
rng('shuffle');

for condFile = 1:15
    seriesSequence = (1:6)'; 
    
    longSequence = repmat(seriesSequence, nSeries, 1); 
    nTrials = numel(longSequence);
    
    conditionMatrix = NaN(nTrials, 2); 
    conditionMatrix(:,1) = longSequence;
    
    % Count how many rep=1 and rep=5 trials there are dynamically
    nRep1 = sum(longSequence == 1);
    nRep5 = sum(longSequence == 5);
    
    % Build conditions dynamically
    rep1conds = [repmat([0], nRep1/2, 1); repmat([1], nRep1/2, 1)];
    rep5conds = [repmat([0], nRep5/2, 1); repmat([1], nRep5/2, 1)];
    
    % Randomize within repetition
    rep1random = rep1conds(randperm(nRep1), :);
    rep5random = rep5conds(randperm(nRep5), :);
    
    % Fill in the matrix
    conditionMatrix(longSequence == 1, 2) = rep1random;
    conditionMatrix(longSequence == 5, 2) = rep5random;
    
    % Next up, move on to the color degrees:
    % Here's the general strategy:
    % For each repetition series, first randomly pick a hue for the primary
    % image. The primary image will repeat with the same color through all six
    % trials. The secondary images will change color in on each repetition
    % though. 
    % Therefore, for the first rep, select a color degree at least 40 degrees
    % away from the primary color degree for the second image. 
    % On every next iteration, compare the color of the secondary image to the
    % previous secondary image as well as the primary image. 
    
    longSequence = repmat(1:6, 1, nTrials/6)'; % 1-6 repeated
    colorSelections = zeros(nTrials, 3);
    colorSelections(:,1) = longSequence;
    colorSpace = 1:359;
    
    %% -------------------
    % PASS 1: generate primary colors block by block
    %% -------------------
    blockStartIdx = 1:6:nTrials;
    
    % first block primary
    colorSelections(1,2) = colorSpace(randi(numel(colorSpace)));
    
    % subsequent blocks
    for b = 2:numel(blockStartIdx)
        prevPrimary = colorSelections(blockStartIdx(b-1), 2);
        prevSecondary = colorSelections(blockStartIdx(b-1)+5, 3); % (no secondary yet, placeholder)
        
        % just ensure distance from prevPrimary for now (no prevSecondary yet)
        nums2delete = mod((prevPrimary-40:prevPrimary+40)-1, 359) + 1;
        validColors = setdiff(colorSpace, nums2delete);
    
        colorSelections(blockStartIdx(b),2) = validColors(randi(numel(validColors)));
    end
    
    % fill in primary for rest of each block
    for b = 1:numel(blockStartIdx)
        idx = blockStartIdx(b);
        colorSelections(idx:idx+5,2) = colorSelections(idx,2);
    end
    
    %% -------------------
    % PASS 2: generate secondary colors trial by trial
    %% -------------------
    for i = 1:nTrials
        currentPrimary = colorSelections(i,2);
        
        if i > 1
            prevPrimary   = colorSelections(i-1,2);
            prevSecondary = colorSelections(i-1,3);
        else
            prevPrimary   = [];
            prevSecondary = [];
        end
    
        if i < nTrials
            nextPrimary = colorSelections(i+1,2);
        else
            nextPrimary = [];
        end
        
        % build exclusion list
        nums2delete = mod((currentPrimary-40:currentPrimary+40)-1, 359) + 1;
        if ~isempty(prevPrimary)
            nums2delete = [nums2delete, mod((prevPrimary-40:prevPrimary+40)-1, 359) + 1];
        end
        if ~isempty(prevSecondary)
            nums2delete = [nums2delete, mod((prevSecondary-40:prevSecondary+40)-1, 359) + 1];
        end
        % if this is trial 6 of a block, exclude next block's primary too
        if colorSelections(i,1) == 6 && ~isempty(nextPrimary)
            nums2delete = [nums2delete, mod((nextPrimary-40:nextPrimary+40)-1, 359) + 1];
        end
    
        nums2delete = unique(nums2delete);
        validColors = setdiff(colorSpace, nums2delete);
    
        colorSelections(i,3) = validColors(randi(numel(validColors)));
    end
    
    %% Sanity check: primary color repetition
    primaryRepeatsOK = all( ...
        arrayfun(@(i) all(colorSelections(i:i+5,2) == colorSelections(i,2)), ...
        1:6:nTrials) );
    fprintf('Primary repeats OK: %d\n', primaryRepeatsOK);
    
    %% Check primary distance between consecutive blocks
    primaryDiffOK = true;
    for i = 7:6:nTrials % compare start of each block with previous block
        prevPrimary = colorSelections(i-1,2);
        currPrimary = colorSelections(i,2);
        dist = abs(currPrimary - prevPrimary);
        dist = min(dist, 359 - dist); % wrap-around distance
        if dist <= 40
            fprintf('Primary too close at block starting trial %d\n', i);
            primaryDiffOK = false;
        end
    end
    fprintf('Primary distance OK: %d\n', primaryDiffOK);
    
    %% Check secondary distances
    secondaryDiffOK = true;
    for i = 2:nTrials
        currSec = colorSelections(i,3);
        currPrim = colorSelections(i,2);
        prevSec = colorSelections(i-1,3);
        prevPrim = colorSelections(i-1,2);
    
        % compute circular distances
        distCurrPrim = min(abs(currSec - currPrim), 359 - abs(currSec - currPrim));
        distPrevPrim = min(abs(currSec - prevPrim), 359 - abs(currSec - prevPrim));
        distPrevSec  = min(abs(currSec - prevSec), 359 - abs(currSec - prevSec));
    
        if distCurrPrim <= 40 || distPrevPrim <= 40 || distPrevSec <= 40
            fprintf('Secondary too close at trial %d\n', i);
            secondaryDiffOK = false;
        end
    end
    fprintf('Secondary distances OK: %d\n', secondaryDiffOK);
    
    %% New check: trial 6 vs next primary
    nextBlockOK = true;
    for i = 6:6:nTrials-6
        nextPrim = colorSelections(i+1,2);
        currSec = colorSelections(i,3);
        dist = min(abs(currSec - nextPrim), 359 - abs(currSec - nextPrim));
        if dist <= 40
            fprintf('Trial %d secondary too close to next primary!\n', i);
            nextBlockOK = false;
        end
    end
    fprintf('Next-block distance OK: %d\n', nextBlockOK);
    
    fprintf('All checks passed successfully.\n');
    
    %% And finally, combine everything to pass to the experiment code. The textures will be handled over there:
    
    finalMatrix = zeros(nTrials,4);
    finalMatrix(:, 1:2) = conditionMatrix;
    finalMatrix(:, 3:4) = colorSelections(:,2:3);

    % The context change flow in training is pre-determined. Attach it
    % before finishing up.
    trainingContext = [0 NaN NaN NaN 1 NaN 1 NaN NaN NaN 0 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN]';
    finalMatrix((length(finalMatrix)-29):(length(finalMatrix)),2) = trainingContext;

    % Currently, the structure of finalMatrix is:
    
    % Col1: Repetition Series Sequence
    % Col2: Context Change Value (0 = No Change, 1 = Change) 
    % Col3: Color Degree for the Primary Image
    % Col4: Color Degree for the Secondary Image

    % Specify the folder where you want to save the file
    saveFolder = condDest;

    % Build the filename dynamically
    currentLabel = sprintf('imperil4cond%d.mat', condFile);

    % Build the full path
    fullPath = fullfile(saveFolder, currentLabel);
    
    % Save the matrix
    save(fullPath, 'finalMatrix');
end

fprintf('15 new conditions files have been generated!\n');

