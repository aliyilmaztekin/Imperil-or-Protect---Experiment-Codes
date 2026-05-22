%% Imperil or Protect 6 - Condition Matrix Generator
% Coded by A.Y.

% Conception: 21.04.2026
% Alpha: 23.04.2026 

desiredTrialCount = 480; % Can change to 720
computerHandle = 2; % 0 for ali's pc, 1 for the experiment comp, 2 for the gamma computer

if computerHandle == 0 
    condDest = '/Users/ali/Desktop/visual imperil project/imperil6materials/imperil6ConditionFiles';
elseif computerHandle == 1
    condDest = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\imperil6materials\imperil6ConditionFiles';
elseif computerHandle == 2
    condDest = 'C:\Users\gamalab1\Desktop\Ali Yılmaztekin - imperil6\imperil6ConditionFiles';
end

% Total number of repetition series to generate based on desired trial
% count. 720 total -> 120 series, 4nSeries trials -> nSeries series
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
    nTrainingTrials = 48;
    
    conditionMatrix = NaN(nTrials, 10); 
    conditionMatrix(:,1) = longSequence;
    
    % Count how many rep=1 and rep=5 trials there are dynamically
    % Only do this for the main experimental portion so that the first
    % desiredTrialCount trials are exactly balanced.
    expSequence = longSequence(1:desiredTrialCount);
    nRep1 = sum(expSequence == 1);
    nRep5 = sum(expSequence == 5);
    
    %% Change Assignment 
    
    % Build conditions dynamically
    rep1conds = [repmat([0], nRep1/2, 1); repmat([1], nRep1/2, 1)];
    rep5conds = [repmat([0], nRep5/2, 1); repmat([1], nRep5/2, 1)];
    
    % Randomize within repetition
    rep1random = rep1conds(randperm(nRep1), :);
    rep5random = rep5conds(randperm(nRep5), :);
    
    % Fill in the matrix only in the main experimental portion
    rep1idx = find(longSequence(1:desiredTrialCount) == 1);
    rep5idx = find(longSequence(1:desiredTrialCount) == 5);
    
    conditionMatrix(rep1idx, 2) = rep1random;
    conditionMatrix(rep5idx, 2) = rep5random;
    
    %% Color Assignment
    
    validSetFound = false;
    outerAttempts = 0;
    maxOuterAttempts = 1000;
    
    while ~validSetFound && outerAttempts < maxOuterAttempts
        outerAttempts = outerAttempts + 1;
        
        % Generate 9 numbers per series. 
    
        % First 3 = Mem array 1 items (repeated)
        % Next 6 = Mem array 2 items (one per trial)
    
        % Ensure:
        % Each item in a series is sufficient apart from each other.
    
        colorsVec = [];
        
        for series = 1:nSeries
            colorOffset = 40;
            colors = zeros(1,9);
            
            % Pick one random starting color
            colors(1) = randi([0 359]);
            
            % Generate the remaining 8 colors, each 40 degs apart
            for k = 2:9
                colors(k) = mod(colors(k-1) + colorOffset, 360);
            end
            
            % Shuffle order within this series
            colors = colors(randperm(9));
            
            % Store as a growing column vector
            colorsVec = [colorsVec; colors(:)];
        end
        
        % Break the colors into repetition series
        colorsMat = reshape(colorsVec, 9, nSeries);
        
        % Rearrange colors within a series to prevent across-series
        % interference. 
    
        % Ensure:
        % 1) Memory array 1 items in a series [col(1:3)] are sufficiently
        % apart from mem array 2 items in the next series [col+1(1:3)].
    
        % 2) The last memory array 2 item in a series [col(9)] needs to be
        % sufficiently apart from the first memory array 2 in the next
        % series [col+1(4)].
    
        maxInnerAttempts = 1000;
        
        validSetFound = true;  
        
        for col = 1:(nSeries-1)
            
            success = false;
            attempt = 0;
            
            % Keep reshuffling within-column value orders until the two
            % conditions are met. 
            while ~success && attempt < maxInnerAttempts
                % Attempt counter
                attempt = attempt + 1;
                
                % Shuffle only the next column
                colorsMat(:, col+1) = colorsMat(randperm(9), col+1);
                
                % Check memory array 1 distances across adjacent repetition
                % series
                prevTriplet = colorsMat(1:3, col);
                nextTriplet = colorsMat(1:3, col+1);
                
                % All pairwise circular distances
                distanceMat = abs(prevTriplet - nextTriplet');
                distanceMat = min(distanceMat, 360 - distanceMat);
                
                tripletOK = all(distanceMat(:) >= colorOffset);
                
                % Check memory array 2 distances across adjacent repetition
                % series
                prevLastArray2 = colorsMat(9, col);
                nextFirstArray2 = colorsMat(4, col+1);
                
                distanceMat2 = abs(prevLastArray2 - nextFirstArray2);
                distanceMat2 = min(distanceMat2, 360 - distanceMat2);
                
                array2OK = distanceMat2 >= colorOffset;
                
                % If both conditions are met, break out of the loop
                % If not, increment the counter at the top of the loop
                success = tripletOK && array2OK;
            end
            
            % If conditions are not met after max attempts, loop back to
            % the outer loop and generate new color values
            if ~success
                validSetFound = false;
                break  
            end
        end
    end
    
    if ~validSetFound
        error('Could not generate a fully valid colorsMat after %d outer attempts.', maxOuterAttempts);
    else
        fprintf('Valid colorsMat found after %d outer attempt(s).\n', outerAttempts);
    end
    
    % Store the colors:
    % Col 3: Memory Array 1 Item 1 color
    % Col 4: Memory Array 1 Item 2 color
    % Col 5: Memory Array 1 Item 3 color
    % Col 6: Memory Array 2 color
    
    conditionMatrix(:,3) = reshape([repmat(colorsMat(1,:), 6, 1)], length(conditionMatrix), 1);
    conditionMatrix(:,4) = reshape([repmat(colorsMat(2,:), 6, 1)], length(conditionMatrix), 1);
    conditionMatrix(:,5) = reshape([repmat(colorsMat(3,:), 6, 1)], length(conditionMatrix), 1);
    conditionMatrix(:,6) = reshape(colorsMat(4:9,:), length(conditionMatrix), 1);
    
    %% Location Assignment
    % Memory array 2 items are always to be presented centrally.
    % However, memory array 1 items are to be randomly positioned along an
    % imaginary circle. 
    % Generate theta angles per image. 
    % Also, ensure that there's no overlap in locations at series transitions
    
    thetas = zeros(3,nSeries);
    locationOffset = 45;
    
    for angle = 1:nSeries
        locTripletOK = false;
    
        while ~locTripletOK
            baseAngles = linspace(0, 360, 9);
            baseAngles(end) = [];
    
            offset = randi([0 359]);
            rotatedAngles = mod(baseAngles + offset, 360);
    
            candidate = rotatedAngles(randperm(8,3))';
    
            if angle == 1
                locTripletOK = true;
            else
                distanceMat = abs(candidate - thetas(:,angle-1)');
                distanceMat = min(distanceMat, 360 - distanceMat);
    
                locTripletOK = all(distanceMat(:) >= locationOffset);
            end
        end
    
        thetas(:,angle) = candidate;
    end
    
    % Store theta values of memory array 1 items
    % Col 7: Memory Array 1 Item 1 theta
    % Col 8: Memory Array 1 Item 2 theta
    % Col 9: Memory Array 1 Item 3 theta
    conditionMatrix(:,7) = reshape(repmat(thetas(1,:), 6, 1), length(conditionMatrix), 1);
    conditionMatrix(:,8) = reshape(repmat(thetas(2,:), 6, 1), length(conditionMatrix), 1);
    conditionMatrix(:,9) = reshape(repmat(thetas(3,:), 6, 1), length(conditionMatrix), 1);
    
    %% Triplet Testing Assignment
    % Determine which of the triplet items are to be tested in a series
    
    % 1 = test the first triplet item, 2 = the second & 3 = the third
    % Ensure each item gets tested at least once
    
    orderVec = [];
    
    for testOrder = 1:nSeries
        forcedTest = 1:3;
        randTestValue = randi(3, 1, 3);
        
        testValues = [forcedTest, randTestValue];
        testValues = testValues(randperm(length(testValues)));
    
        orderVec = [orderVec; testValues]; 
    end
    
    conditionMatrix(:,10) = reshape(orderVec', length(conditionMatrix), 1);
    
    trainingMatrix = conditionMatrix(end-59:end, :);
    conditionMatrix(end-59:end, :) = [];
    
    % Canonical context change timeline in training. Same across participants.  
    trainingContext = [0 NaN NaN NaN 1 NaN 1 NaN NaN NaN 0 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN ...
        1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN 1 NaN NaN NaN 1 NaN]';
    
    trainingMatrix(:,2) = trainingContext;

    % Specify the folder where you want to save the file
    saveFolder = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/imperil6ConditionFiles';
    saveFolderTraining = '/Users/ali/Desktop/visual imperil project/imperil6_reactivation_crisis/imperil6ConditionFilesTraining';

    % Build the filename dynamically
    currentLabel = sprintf('imperil6cond%d.mat', condFile);
    currentLabelTrain = sprintf('imperil6TrainCond%d.mat', condFile);

    % Build the full path
    fullPath = fullfile(saveFolder, currentLabel);
    fullPathTrain = fullfile(saveFolderTraining, currentLabelTrain);
    
    % Save the matrices
    save(fullPath, 'conditionMatrix');
    save(fullPathTrain, 'trainingMatrix');
end

% Cols:

% Col 1: Repetition counter
% Col 2: Context change vals
% Col 3: Memory Array 1 Item 1 color
% Col 4: Memory Array 1 Item 2 color
% Col 5: Memory Array 1 Item 3 color
% Col 6: Memory Array 2 color
% Col 7: Memory Array 1 Item 1 theta
% Col 8: Memory Array 1 Item 2 theta
% Col 9: Memory Array 1 Item 3 theta
% Col 10: Mem 1 item to test at Probe 2