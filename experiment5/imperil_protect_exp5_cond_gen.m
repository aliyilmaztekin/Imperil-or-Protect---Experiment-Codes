%% Imperil or Protect - 5: Eye Tracking
%% Condition Matrix Generator
% First started: 16.11.2025 
% Coded by A.Y.

% Finalized: 16.12.2025 

% First and foremost, I believe in the ultimate randomness of the universe
rng('shuffle');

%% Generator Parameters
% Enter the trial count, and condition number
nTrials = 384;

nBlock = nTrials/48;

% Running on what?
aliscomputer = true;
experimentcomputer = false; 

% Where should the output files go?
if aliscomputer 
    condDest = '/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment5/imperil5ConditionFiles';
elseif experimentcomputer
    condDest = 'C:\Users\eeglab\Documents\MACCLab\Ali Yılmaztekin\imperil5\imperil5ConditionFiles';
end

for condFile = 1:15
    % Create an empty number array. 
    conditionMatrix = NaN(nTrials, 8);
    
    % Composition:
    % 1st col: Trial number: [1 - nTrials]
    % 2nd col: Repetition sequence: (1,2,3,4,5,6)
    % 3rd col: Block type (repeat versus non-repeat)
    % 4th col: Context change commands: 0= No change, 1= Change
    % 5th col: Encoding site (on which half should the image appear for
    % studying): 0= left visual half, 1= right visual half.
    % 6th col: Testing site (on which half should the memory item appear
    % against the foil at testing): 0= same as study, 1= the other side.
    % 7th col: The original rotation angle 
    % 8th col: Foil rotation angle for the wrong answer at testing. 
    
    liveTrial = (1:nTrials)';
    repetitionSequence = [1 2 3 4 5 6]';
    conditionMatrix(:,1) = liveTrial;
    conditionMatrix(:,2) = repmat(repetitionSequence, nTrials/6, 1);
    
    % Find how many trials will get the context change commands and assign.
    idxRep = conditionMatrix(:,2) == 1 | conditionMatrix(:,2) == 5;
    nAssign = sum(idxRep);  
    
    contextChange = [zeros(nAssign/2,1); ones(nAssign/2,1)];  
    contextChange = contextChange(randperm(nAssign));
    conditionMatrix(idxRep, 4) = contextChange;
    
    % Encoding site has to stay the same throughout a repetition series.
    idxRep = conditionMatrix(:,2) == 1;
    nAssign = sum(idxRep);  
    
    encodingSite = [zeros(nAssign/2,1); ones(nAssign/2,1)];
    encodingSite = encodingSite(randperm(nAssign));
    conditionMatrix(:,5) = repelem(encodingSite, 6);
    
    % But testing site can be totally random.
    testingSite = [zeros(nTrials/2,1);ones(nTrials/2,1)];
    testingSite = testingSite(randperm(nTrials));
    conditionMatrix(:, 6) = testingSite;  
    
    %% Rotation Angle Generation
    % The below code works by the following conceptual logic: 
    
    % Begin by randomly picking a random number from 1 to 359. 
    
    % Every foil angle has to be different enough from the original angle to be
    % perceptually distinguishable, yet not too different to stick out as
    % different. The literature suggests that the sweet spot of possible value
    % range is about 5-15 degrees, or 5-20. It is also good practice to pick
    % values off this range as if drawing from a normal distribution.  
    
    % Here, the offset of the foil angle from the original one is selected as
    % if drawing from a normal dist with a mean of 10, and an SD of 3, with
    % degrees 5 and 15 spanning 95% of the offset range. 
    
    % Randomly select whether the offset should be clockwise or
    % counter-clockwise to the original rotation. 
    
    % Importantly, since the rotation space is a circular one, we need to make
    % sure that the values that exceed 359 are wrapped around. 
    
    % As a last control, we need to make sure each original rotation is at
    % least 40 degrees apart from the one before both CW and CCW. 
    
    % It also handles the generation of 6 foils per 1 original angle. 
    
    %% Parameters
    numOriginals = (nTrials/6)/2 + (nTrials/2); 
    numOriginals = numOriginals + 8; % 8 more unique angles for training
    forbiddenRadius = 40;    % 40° around previous rotation
    numFoilsPerOriginal = 6;
    minOffset = 5;           % min foil distance from original
    maxOffset = 15;          % max foil distance from original
    meanOffset = 10;         % mean for the offset range
    sdOffset = 3;            % SD for the offset range
    
    % Generate original rotations
    originals = zeros(1, numOriginals);
    
    % First rotation random
    originals(1) = randi([1 359], 1);
    
    for i = 2:numOriginals
        prev = originals(i-1);
        
        % Forbidden zone: forbiddenRadius
        forbidden = mod((prev - forbiddenRadius):(prev + forbiddenRadius), 359);
        forbidden(forbidden == 0) = 359;  % MATLAB mod quirks
        
        % Allowed values
        allowed = setdiff(1:359, forbidden);
        
        % Pick randomly among allowed
        originals(i) = allowed(randi(length(allowed)));
    end

    % Store and cut out training angles  
    trainingAngles = originals(1:8);
    originals(1:8) = [];

    % From the remaining, store some as repeating angles for the main phase
    repeatingOriginalsIdx = originals(1: (nTrials/6)/2);
    originals(1: (nTrials/6)/2) = [];

    % Let the remaining be non-repeating
    nonRepeatingOriginals = originals';

    repeatingOriginals = repelem(repeatingOriginalsIdx, 6)';  % repeating originals

    
    combineOriginals = [repeatingOriginals; nonRepeatingOriginals]; 

    %% Generate foils for each original
    foils = zeros(length(combineOriginals), 1);

    for i = 1:length(combineOriginals)
        rot = combineOriginals(i);

        % Sample offset from truncated normal
        offset = round(normrnd(meanOffset, sdOffset));
        offset = max(minOffset, min(maxOffset, offset));

        % Random direction
        if rand < 0.5
            offset = -offset;
        end

        % Circular wrap-around
        foils(i) = mod(rot + offset - 1, 359) + 1;
    end

    % Divide into blocks
    blockedCombineOriginals = reshape(combineOriginals, nTrials/nBlock, nBlock);

    blockedCombineFoils = reshape(foils, nTrials/nBlock, nBlock);
    
    % Randomization key
    randomBlockOrder = randperm(nBlock);
    
    % Reorder blocks
    randomizedOriginals = blockedCombineOriginals(:, randomBlockOrder);
    
    % Squeeze back to a column vector
    randomizedOriginals = randomizedOriginals(:);

    randomizedFoils = blockedCombineFoils(:, randomBlockOrder);
    randomizedFoils = randomizedFoils(:);

    conditionMatrix(:,7) = randomizedOriginals;
    conditionMatrix(:,8) = randomizedFoils;

    % Assign block types
    block_types = zeros(1,8);
    block_types(:, randomBlockOrder(:) >= 5) = 1;
    block_types = repelem(block_types, 48)';
    conditionMatrix(:,3) = block_types;

    %% Training Matrix:
    % Training is 18 trials. Two series are repeats, and one is a
    % non-repeat. 

    trainingRepeating = repelem(trainingAngles(1:2), 6)';  % 12 trials
    trainingNonRepeating = trainingAngles(3:8)';          % 6 trials
    trainingOriginals = [trainingRepeating; trainingNonRepeating];  % 18 trials

    % Parameters (reuse from main code)
    minOffset = 5;
    maxOffset = 15;
    meanOffset = 10;
    sdOffset = 3;

    trainingFoils = zeros(length(trainingOriginals),1);

    for i = 1:length(trainingOriginals)
        rot = trainingOriginals(i);

        % Sample offset from truncated normal
        offset = round(normrnd(meanOffset, sdOffset));
        offset = max(minOffset, min(maxOffset, offset));

        % Random direction
        if rand < 0.5
            offset = -offset;
        end

        % Circular wrap-around
        trainingFoils(i) = mod(rot + offset - 1, 359) + 1;
    end

    trainingMatrix = nan(18,8);      
    trainingMatrix(:,7:8) = [trainingOriginals, trainingFoils];

    % Fill other columns 
    trainingMatrix(:,1) = (1:18)'; 
    trainingMatrix(:,2) = repmat(1:6, 1, 3)';           
    trainingMatrix(:,3) = repelem([0 0 1], 6)';      
    trainingMatrix(:,4) = [0 NaN NaN NaN 1 NaN 0 NaN NaN NaN 1 NaN ...
        1 NaN NaN NaN 1 NaN];                       
    
    trainingEncoding = [0 1 randi([0 1],1,1)]; 
    trainingEncoding = trainingEncoding(randperm(3));
    
    trainingMatrix(:,5) = repelem(trainingEncoding, 6)';     
    trainingMatrix(:,6) = randi([0 1],18,1);       

    conditionMatrix = [conditionMatrix; trainingMatrix];
    
    % Specify the folder where you want to save the file
    saveFolder = condDest;
    
    % Build the filename dynamically
    currentLabel = sprintf('imperil5cond%d.mat', condFile);
    
    % Build the full path
    fullPath = fullfile(saveFolder, currentLabel);
    
    % Save the matrix
    save(fullPath, 'conditionMatrix');
end

fprintf('15 new conditions files have been generated!\n');