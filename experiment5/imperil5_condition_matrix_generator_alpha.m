%% Imperil or Protect - 5: Eye Tracking
%% Condition Matrix Generator
% First started: 16.11.2025 
% Coded by A.Y.

% First and foremost, I believe in the ultimate randomness of the universe
rng('shuffle');

nTrials = 720;
nConds = 4;

imperil5_cond_1 = NaN(nTrials, 6);

liveTrial = (1:nTrials)';
repetitionSequence = [1 2 3 4 5 6]';
imperil5_cond_1(:,1) = liveTrial;
imperil5_cond_1(:,2) = repmat(repetitionSequence, nTrials/6, 1);

contextID = [zeros((nTrials/6)/nConds, 1); ones((nTrials/6)/nConds, 1)];


encodingSite = [zeros((nTrials/6)/nConds, 1); ones((nTrials/6)/nConds, 1)];
testingSite = [zeros((nTrials/6)/nConds, 1); ones((nTrials/6)/nConds, 1)];


% Find how many trials will get the contextChange
idxRep = imperil5_cond_1(:,2) == 1 | imperil5_cond_1(:,2) == 5;
nAssign = sum(idxRep);   % total number of rows to assign

% Make balanced vector of 0s and 1s with same length
contextChange = [zeros(nAssign/2,1); ones(nAssign/2,1)];  

% Shuffle randomly
contextChange = contextChange(randperm(nAssign));

% Assign
imperil5_cond_1(idxRep, 3) = contextChange;












rotationAngle = randi([1 360], 1);

% Gaussian-ish offset distribution: mean 10, SD ~3, truncated to 5–15
foilOffset = round(normrnd(10,3));
foilOffset = max(5, min(15, foilOffset));  

% Randomly pick direction: CW or CCW
if rand < 0.5
    foilOffset = -foilOffset;
end

% Circular wrap-around
foilRotationAngle = mod(rotationAngle + foilOffset - 1, 360) + 1;

%% Parameters
numOriginals = 120;
forbiddenRadius = 40;    % ±40° around previous rotation
numFoilsPerOriginal = 6;
minOffset = 5;           % min foil distance from original
maxOffset = 15;          % max foil distance from original
meanOffset = 10;         % mean for truncated normal
sdOffset = 3;            % SD for truncated normal

%% Generate original rotations
originals = zeros(1, numOriginals);

% First rotation random
originals(1) = randi([1 360], 1);

for i = 2:numOriginals
    prev = originals(i-1);
    
    % Forbidden zone: ±forbiddenRadius
    forbidden = mod((prev - forbiddenRadius):(prev + forbiddenRadius), 360);
    forbidden(forbidden == 0) = 360;  % MATLAB mod quirks
    
    % Allowed values
    allowed = setdiff(1:360, forbidden);
    
    % Pick randomly among allowed
    originals(i) = allowed(randi(length(allowed)));
end

%% Generate foils for each original
foils = zeros(numOriginals, numFoilsPerOriginal);

for i = 1:numOriginals
    rot = originals(i);
    
    for j = 1:numFoilsPerOriginal
        % Sample offset from truncated normal
        offset = round(normrnd(meanOffset, sdOffset));
        offset = max(minOffset, min(maxOffset, offset));
        
        % Random direction
        if rand < 0.5
            offset = -offset;
        end
        
        % Circular wrap-around
        foils(i,j) = mod(rot + offset - 1, 360) + 1;
    end
end

foils_flat = reshape(foils', 1, []);  % row-wise flatten

imperil5_cond_1(:,5) = repelem(originals, 6)';  % repeated originals
imperil5_cond_1(:,6) = foils_flat';            % matching foils



