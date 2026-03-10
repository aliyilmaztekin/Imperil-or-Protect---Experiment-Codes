%% Imperil or Protect - 5: Eye Tracking
%% Condition Matrix Generator
%% Updated, final design
% First started and finalized: 20.12.2025 
% Coded by A.Y.

% Design update: 9.1.2026
% Fixed again for the new design: 14.1.2026

% First and foremost, I believe in the ultimate randomness of the universe
rng('shuffle');

%% Generator Parameters
% Adjust as desired

nTrials = 576;
trialPerBlock = 36;
nBlock = nTrials / trialPerBlock;
assert(mod(nTrials,trialPerBlock)==0,'nTrials must divide evenly into blocks');
nFile = 15;
nTrialsTraining = 18;

% Running on what?
aliscomputer = true;
experimentcomputer = false; 

% Where should the output files go?
if aliscomputer 
    condDest = '/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment5/imperil5ConditionFiles';
elseif experimentcomputer
    condDest = 'C:\Users\eeglab\Documents\MACCLab\Ali Yılmaztekin\imperil5\imperil5ConditionFiles';
end

for condFile = 1:nFile
    % Create an empty number array. 
    mainMatrix = NaN(nTrials, 9);
    
    % Composition:
    % 1st col: Trial number: [1 - nTrials]
    % 2nd col: Repetition sequence: (1,2,3,4,5,6)
    % 3rd col: Context change commands: 0= No change, 1= Change
    % 4th col: Encoding site (on which half should the image appear for
    % studying): 0= left visual half, 1= right visual half.
    % 5th col: Testing site (on which half should the memory item appear
    % against the foil at testing): 0= same as study, 1= the other side.
    % 6th col: The original rotation angle 
    % 7th col: Foil rotation angle for the wrong answer at testing.
    % 8th col: Foil rotation angle for the irrelevant cue at encoding. 
    % 9th col: Relevance cue. (What encoding item color is to be tested).
    
    liveTrial = (1:nTrials)';
    repetitionSequence = [1 2 3 4 5 6]';
    mainMatrix(:,1) = liveTrial;
    mainMatrix(:,2) = repmat(repetitionSequence, nTrials/6, 1);
    
    % Find how many trials could feature a context change.
    % Assign context change separately for rep 1 and rep 5
    for r = [1 5]
        idx = mainMatrix(:,2) == r;
        n = sum(idx);
        
        cc = [zeros(n/2,1); ones(n/2,1)];
        cc = cc(randperm(n));
        
        mainMatrix(idx,3) = cc;
    end
    
    % Encoding site may vary in a repetition series. 
    encodingSite = [zeros(nTrials/2,1); ones(nTrials/2,1)];
    encodingSite = encodingSite(randperm(nTrials));

    mainMatrix(:, 4) = encodingSite;
    
    % Just as the testing site
    testingSite = [zeros(nTrials/2,1);ones(nTrials/2,1)];
    testingSite = testingSite(randperm(nTrials));

    mainMatrix(:, 5) = testingSite;  
    
    %% Rotation Angle Generation
    % The below code works by the following conceptual logic: 
    
    % Begin by randomly picking a random number from 1 to 359. 
    
    % Every foil angle has to be different enough from the original angle to be
    % perceptually distinguishable, yet not too different to stick out as
    % the incorrect answer.
    % 
    % The literature (e.g., Zhang & Luck, 2008) suggests that the ideal range of possible value
    % is about 5-15 degrees, or 5-20. It is also good practice choose values from this
    % range as if drawing from a normal distribution.  
    
    % The parameters of that normal dist are: mean of 10, and an SD of 3, with
    % degrees 5 and 15 spanning 95% of the offset range. 
    
    % Also, make sure to randomly select whether the offset should be clockwise or
    % counter-clockwise to the original rotation. 
    
    % Crucially, since the rotation space is circular, foil angles exceeding 359 must be wrapped around. 
    
    % As a last control, we need to make sure each original rotation is at
    % least 30 degrees apart from the one before both CW and CCW. 
    
    
    %% Parameters
    numTarget = nTrials/6 + nTrialsTraining/6; % Every image repeats 6 times % Extra images for the training phase
    numDist = nTrials/6 + nTrialsTraining/6; % Those are the non-target foil angles at encoding
    
    % Some parameters for the upcoming orientation generator
    itemsPerTrial = 2;      % now two orientations per trial
    forbiddenRadius = 30;   % minimum difference between image rotations
    maxAttempts = 1000;     % so that the loop doesn't get stuck
    
    % Helper function to compute circular difference
    % This is not a simple subtraction method, but one that takes into
    % account the circular wrap-around of a response wheel. 

    circDiff = @(a,b) min(mod(a-b,360), mod(b-a,360));
    
    % Run the loop for the length of unique orientation pairs.
    % Both target and distractor angles generated are stored here
    combinedAngles = zeros(numTarget, itemsPerTrial);

    for t = 1:numTarget

        attempt = 0;
        valid = false;
        
        % Keep searching until the upper limit has been reached.

        while ~valid && attempt < maxAttempts
            attempt = attempt + 1;
            
            % Randomly pick two orientations
            candidate = randi([1 359], 1, itemsPerTrial);
            
            % Check the difference of the first pair
            if circDiff(candidate(1), candidate(2)) >= forbiddenRadius
                % Check the difference with previous trial (only after the first
                % trial)
                if t > 1
                    diffsPrev = [circDiff(candidate(1), combinedAngles(t-1,1)), ...
                                 circDiff(candidate(1), combinedAngles(t-1,2)), ...
                                 circDiff(candidate(2), combinedAngles(t-1,1)), ...
                                 circDiff(candidate(2), combinedAngles(t-1,2))];
                    
                    % Now, all four comparisons are checked for minimum
                    % distance. If any violates, another attempt is a go. 
                    if any(diffsPrev < forbiddenRadius)
                        continue;
                    else
                        % Otherwise, save the current pair and move on to the
                        % next angle generation.
    
                        % If all checks are successful, store the current rotation pair
                        combinedAngles(t,:) = candidate;
                        valid = true;
                    end
                
                else
                    % If this is the first iteration, save the angle pair
                    % and move along.

                    combinedAngles(t,:) = candidate;
                    valid = true;
                end
            end    
        end
        
        % Only way out of this bit is to exhaust the attempt limit.
        if ~valid
            error('Could not find valid orientations for trial %d. Try reducing forbiddenRadius.', t);
        end
    end
    
    % Repeat each trial 6 times
    combinedAngles = repelem(combinedAngles, 6, 1);

    % Cut out the trainingAngles and save for later
    trainingAngles = combinedAngles(1:nTrialsTraining,:);
    combinedAngles(1:nTrialsTraining,:) = [];

    %% Generate foil rotations for each original
    mainFoils = zeros(size(combinedAngles,1), 1);

    for i = 1:size(combinedAngles,1)
        rot = combinedAngles(i,1);

        % Randomly pick an offset
        offset = randi([10, 15]);

        % Random direction
        if rand < 0.5
            offset = -offset;
        end

        % Store with circular wrap-around
        mainFoils(i) = mod(rot + offset - 1, 359) + 1;
    end

    % Divide into blocks
    blockedTargets = reshape(combinedAngles(:,1), nTrials/nBlock, nBlock);
    blockedDistractors = reshape(combinedAngles(:,2), nTrials/nBlock, nBlock);
    blockedFoils = reshape(mainFoils, nTrials/nBlock, nBlock);
    
    % Randomization key
    randomBlockOrder = randperm(nBlock);
    
    % Reorder blocks
    randomTargets = blockedTargets(:, randomBlockOrder);
    
    % Squeeze back to a column vector
    randomTargets = randomTargets(:);

    % Reorder blocks
    randomDistractors = blockedDistractors(:, randomBlockOrder);

    % Squeeze back to a column vector
    randomDistractors = randomDistractors(:);

    % Do the same for the foils
    randomFoils = blockedFoils(:, randomBlockOrder);
    randomFoils = randomFoils(:);

    % Store both in the matrix
    mainMatrix(:,6) = randomTargets;
    mainMatrix(:,7) = randomFoils;
    mainMatrix(:,8) = randomDistractors;

    %% Training Matrix:

    % trainingAngles created earlier contains the original and distractor rotations

    trainingFoils = zeros(size(trainingAngles, 1),1);

    % Assign foils
    for i = 1:size(trainingAngles,1)
        rot = trainingAngles(i,1);
        
        % Randomly pick an offset
        offset = randi([10, 15]);

        % Random direction
        if rand < 0.5
            offset = -offset;
        end

        % Circular wrap-around
        trainingFoils(i) = mod(rot + offset - 1, 359) + 1;
    end

    % Create a training matrix and fill it up
    trainingMatrix = NaN(nTrialsTraining, 9);

    trainingMatrix(:,6) = trainingAngles(:,1);
    trainingMatrix(:,7) = trainingFoils;
    trainingMatrix(:,8) = trainingAngles(:,2);

    % Fill other columns 
    % These values are manually set, so each training phase follows
    % the same event structure

    trainingMatrix(:,1) = (1:nTrialsTraining)'; 
    trainingMatrix(:,2) = repmat((1:6)', nTrialsTraining/6, 1);

    % Change to your liking
    trainingMatrix(:,3) = [0 NaN NaN NaN 1 NaN 0 NaN NaN NaN 1 NaN ...
        1 NaN NaN NaN 1 NaN];  

    % Pseduo-random encoding site assignment. Makes sure each half of the
    % screen is used at least once.
    
    trainingEncodingSites = [zeros(nTrialsTraining/2, 1); ones(nTrialsTraining/2, 1)];
    trainingEncodingSites = trainingEncodingSites(randperm(length(trainingEncodingSites)));

    trainingMatrix(:,4) = trainingEncodingSites;  

    % Totally random testing site assignment
    trainingMatrix(:,5) = randi([0 1],18,1);  

    % Assign cue relevance values for main and training phases
    % 0: Target is the left encoding image
    % 1: Target is the right encoding image

    idxCueRelevance = [zeros(nBlock/2,1); ones(nBlock/2,1)];
    idxCueRelevance = idxCueRelevance(randperm(nBlock));
    idxCueRelevance = repelem(idxCueRelevance(:), trialPerBlock);

    mainMatrix(:,9) = idxCueRelevance;

    idxCueRelevanceTraining = randi([0 1]);
    idxCueRelevanceTraining = repelem(idxCueRelevanceTraining, nTrialsTraining);

    trainingMatrix(:,9) = idxCueRelevanceTraining';
    
    %% Finally, combine the training and main phase matrices
    conditionMatrix = [mainMatrix; trainingMatrix];

    %% Save the output
    % Specify the folder where you want to save the file
    saveFolder = condDest;
    
    % Build the filename dynamically
    currentLabel = sprintf('imperil5cond%d.mat', condFile);
    
    % Build the full path
    fullPath = fullfile(saveFolder, currentLabel);
    
    % Save the matrix
    save(fullPath, 'conditionMatrix');
end

% Success message
fprintf('%d new condition files have been generated!\n', nFile);
