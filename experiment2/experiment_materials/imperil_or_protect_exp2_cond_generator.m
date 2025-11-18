% Create a 720x3 cell array filled with empty strings
matrix = repmat({''}, 720, 3);

% Define the sequence of labels to cycle through
labels = {'1', '2', '3', '4', '5', '6'};

% Loop through the rows and assign the corresponding label to the first column
for i = 1:720
    matrix{i, 1} = labels{mod(i-1, 6) + 1}; % Cycle through labels
end

% Initialize 6 cell arrays (one for each list of 20 items)
itemList1 = cell(20, 2); % "Yes Change" - "No Interference"
itemList2 = cell(20, 2); % "Yes Change" - "Right Interference"
itemList3 = cell(20, 2); % "Yes Change" - "Left Interference"
itemList4 = cell(20, 2); % "No Change" - "No Interference"
itemList5 = cell(20, 2); % "No Change" - "Right Interference"
itemList6 = cell(20, 2); % "No Change" - "Left Interference"

% Fill each list with the appropriate string pairs
for i = 1:20
    % List 1: "Yes Change" - "No Interference"
    itemList1{i, 1} = 'Yes Change';
    itemList1{i, 2} = 'No Interference';

    % List 2: "Yes Change" - "Right Interference"
    itemList2{i, 1} = 'Yes Change';
    itemList2{i, 2} = 'Right Interference';

    % List 3: "Yes Change" - "Left Interference"
    itemList3{i, 1} = 'Yes Change';
    itemList3{i, 2} = 'Left Interference';

    % List 4: "No Change" - "No Interference"
    itemList4{i, 1} = 'No Change';
    itemList4{i, 2} = 'No Interference';

    % List 5: "No Change" - "Right Interference"
    itemList5{i, 1} = 'No Change';
    itemList5{i, 2} = 'Right Interference';

    % List 6: "No Change" - "Left Interference"
    itemList6{i, 1} = 'No Change';
    itemList6{i, 2} = 'Left Interference';
end

% Pool all item lists together vertically
allItemLists = [itemList1; itemList2; itemList3; itemList4; itemList5; itemList6];

% Step 1: Pick 5 random numbers from 1 to 60 and perform initial appending
randomIndices = randperm(60, 5);  % Randomly choose 5 numbers from 1 to 60
selectedRows = allItemLists(randomIndices, :);  % Get the rows from allItemLists
matrixRows = [121, 241, 361, 481, 601];  % Rows in matrix to update

% Step 2: Append the values to the condition matrix at specified rows
for i = 1:5
    firstValue = selectedRows{i, 1};
    secondValue = selectedRows{i, 2};
    matrix{matrixRows(i), 2} = firstValue;  % Append the first value to the second column
    matrix{matrixRows(i), 3} = secondValue; % Append the second value to the third column
end

% Remove the selected rows from allItemLists
allItemLists(randomIndices, :) = [];  % Remove the rows at the selected indices

% Step 3: Now iterate through the first column of the matrix
for i = 1:720
    % Skip lines 121, 241, 361, 481, and 601 as they are already filled
    if ismember(i, matrixRows)
        continue;
    end
    
    % Check if the first column of the current row is 'First'
    if strcmp(matrix{i, 1}, '1')
        % Step 4: Pick a random row from allItemLists
        if ~isempty(allItemLists)  % Make sure there are rows remaining in allItemLists
            randomRowIndex = randi(size(allItemLists, 1));  % Pick a random row from remaining rows
            firstValue = allItemLists{randomRowIndex, 1};
            secondValue = allItemLists{randomRowIndex, 2};
            
            % Step 5: Append values to the second and third columns of the current row in matrix
            matrix{i, 2} = firstValue;  % Append the first value to the second column
            matrix{i, 3} = secondValue; % Append the second value to the third column
            
            % Step 6: Remove the chosen row from allItemLists
            allItemLists(randomRowIndex, :) = [];  % Remove the chosen row from allItemLists
        end
    end
end

% ---- Repool item lists after filling "First" rows ----
% Recreate item lists 1, 2, 3, 4, 5, 6
itemList1 = cell(20, 2); % "Yes Change" - "No Interference"
itemList2 = cell(20, 2); % "Yes Change" - "Right Interference"
itemList3 = cell(20, 2); % "Yes Change" - "Left Interference"
itemList4 = cell(20, 2); % "No Change" - "No Interference"
itemList5 = cell(20, 2); % "No Change" - "Right Interference"
itemList6 = cell(20, 2); % "No Change" - "Left Interference"

% Fill each list again after the first rows are filled
for i = 1:20
    % List 1: "Yes Change" - "No Interference"
    itemList1{i, 1} = 'Yes Change';
    itemList1{i, 2} = 'No Interference';

    % List 2: "Yes Change" - "Right Interference"
    itemList2{i, 1} = 'Yes Change';
    itemList2{i, 2} = 'Right Interference';

    % List 3: "Yes Change" - "Left Interference"
    itemList3{i, 1} = 'Yes Change';
    itemList3{i, 2} = 'Left Interference';

    % List 4: "No Change" - "No Interference"
    itemList4{i, 1} = 'No Change';
    itemList4{i, 2} = 'No Interference';

    % List 5: "No Change" - "Right Interference"
    itemList5{i, 1} = 'No Change';
    itemList5{i, 2} = 'Right Interference';

    % List 6: "No Change" - "Left Interference"
    itemList6{i, 1} = 'No Change';
    itemList6{i, 2} = 'Left Interference';
end

% Pool the item lists together again after filling the "First" rows
allItemLists = [itemList1; itemList2; itemList3; itemList4; itemList5; itemList6];

% Now, repeat the process for rows where the word is 'Fifth'
for i = 1:720
    % Skip lines 121, 241, 361, 481, and 601 as they are already filled
    if ismember(i, matrixRows)
        continue;
    end
    
    % Check if the first column of the current row is 'Fifth'
    if strcmp(matrix{i, 1}, '5')
        % Step 4: Pick a random row from allItemLists
        if ~isempty(allItemLists)  % Make sure there are rows remaining in allItemLists
            randomRowIndex = randi(size(allItemLists, 1));  % Pick a random row from remaining rows
            firstValue = allItemLists{randomRowIndex, 1};
            secondValue = allItemLists{randomRowIndex, 2};
            
            % Step 5: Append values to the second and third columns of the current row in matrix
            matrix{i, 2} = firstValue;  % Append the first value to the second column
            matrix{i, 3} = secondValue; % Append the second value to the third column
            
            % Step 6: Remove the chosen row from allItemLists
            allItemLists(randomRowIndex, :) = [];  % Remove the chosen row from allItemLists
        end
    end
end


% Initialize counters for First and Fifth occurrences
count_First_Yes_Change_No_Interference = 0;
count_First_Yes_Change_Right_Interference = 0;
count_First_Yes_Change_Left_Interference = 0;
count_First_No_Change_No_Interference = 0;
count_First_No_Change_Right_Interference = 0;
count_First_No_Change_Left_Interference = 0;

count_Fifth_Yes_Change_No_Interference = 0;
count_Fifth_Yes_Change_Right_Interference = 0;
count_Fifth_Yes_Change_Left_Interference = 0;
count_Fifth_No_Change_No_Interference = 0;
count_Fifth_No_Change_Right_Interference = 0;
count_Fifth_No_Change_Left_Interference = 0;

% Loop through the rows of the matrix
for i = 1:720
    % Check for "First" rows
    if strcmp(matrix{i, 1}, '1')
        % Check the combination in the second and third columns
        if strcmp(matrix{i, 2}, 'Yes Change') && strcmp(matrix{i, 3}, 'No Interference')
            count_First_Yes_Change_No_Interference = count_First_Yes_Change_No_Interference + 1;
        elseif strcmp(matrix{i, 2}, 'Yes Change') && strcmp(matrix{i, 3}, 'Right Interference')
            count_First_Yes_Change_Right_Interference = count_First_Yes_Change_Right_Interference + 1;
        elseif strcmp(matrix{i, 2}, 'Yes Change') && strcmp(matrix{i, 3}, 'Left Interference')
            count_First_Yes_Change_Left_Interference = count_First_Yes_Change_Left_Interference + 1;
        elseif strcmp(matrix{i, 2}, 'No Change') && strcmp(matrix{i, 3}, 'No Interference')
            count_First_No_Change_No_Interference = count_First_No_Change_No_Interference + 1;
        elseif strcmp(matrix{i, 2}, 'No Change') && strcmp(matrix{i, 3}, 'Right Interference')
            count_First_No_Change_Right_Interference = count_First_No_Change_Right_Interference + 1;
        elseif strcmp(matrix{i, 2}, 'No Change') && strcmp(matrix{i, 3}, 'Left Interference')
            count_First_No_Change_Left_Interference = count_First_No_Change_Left_Interference + 1;
        end
    end

    % Check for "Fifth" rows
    if strcmp(matrix{i, 1}, '5')
        % Check the combination in the second and third columns
        if strcmp(matrix{i, 2}, 'Yes Change') && strcmp(matrix{i, 3}, 'No Interference')
            count_Fifth_Yes_Change_No_Interference = count_Fifth_Yes_Change_No_Interference + 1;
        elseif strcmp(matrix{i, 2}, 'Yes Change') && strcmp(matrix{i, 3}, 'Right Interference')
            count_Fifth_Yes_Change_Right_Interference = count_Fifth_Yes_Change_Right_Interference + 1;
        elseif strcmp(matrix{i, 2}, 'Yes Change') && strcmp(matrix{i, 3}, 'Left Interference')
            count_Fifth_Yes_Change_Left_Interference = count_Fifth_Yes_Change_Left_Interference + 1;
        elseif strcmp(matrix{i, 2}, 'No Change') && strcmp(matrix{i, 3}, 'No Interference')
            count_Fifth_No_Change_No_Interference = count_Fifth_No_Change_No_Interference + 1;
        elseif strcmp(matrix{i, 2}, 'No Change') && strcmp(matrix{i, 3}, 'Right Interference')
            count_Fifth_No_Change_Right_Interference = count_Fifth_No_Change_Right_Interference + 1;
        elseif strcmp(matrix{i, 2}, 'No Change') && strcmp(matrix{i, 3}, 'Left Interference')
            count_Fifth_No_Change_Left_Interference = count_Fifth_No_Change_Left_Interference + 1;
        end
    end
end

% Display the counts
fprintf('First "Yes Change" - "No Interference": %d\n', count_First_Yes_Change_No_Interference);
fprintf('First "Yes Change" - "Right Interference": %d\n', count_First_Yes_Change_Right_Interference);
fprintf('First "Yes Change" - "Left Interference": %d\n', count_First_Yes_Change_Left_Interference);
fprintf('First "No Change" - "No Interference": %d\n', count_First_No_Change_No_Interference);
fprintf('First "No Change" - "Right Interference": %d\n', count_First_No_Change_Right_Interference);
fprintf('First "No Change" - "Left Interference": %d\n', count_First_No_Change_Left_Interference);

fprintf('Fifth "Yes Change" - "No Interference": %d\n', count_Fifth_Yes_Change_No_Interference);
fprintf('Fifth "Yes Change" - "Right Interference": %d\n', count_Fifth_Yes_Change_Right_Interference);
fprintf('Fifth "Yes Change" - "Left Interference": %d\n', count_Fifth_Yes_Change_Left_Interference);
fprintf('Fifth "No Change" - "No Interference": %d\n', count_Fifth_No_Change_No_Interference);
fprintf('Fifth "No Change" - "Right Interference": %d\n', count_Fifth_No_Change_Right_Interference);
fprintf('Fifth "No Change" - "Left Interference": %d\n', count_Fifth_No_Change_Left_Interference);


% Create lists to store rows corresponding to "First" and "Fifth" (excluding 121, 241, 361, 481, 601)
firstRows = {}; % To hold the "First" rows
fifthRows = {}; % To hold the "Fifth" rows
firstIndices = []; % To store indices of "First" rows
fifthIndices = []; % To store indices of "Fifth" rows

% Collect the "First" rows, excluding 121, 241, 361, 481, 601
for i = 1:720
    if strcmp(matrix{i, 1}, '1') && ~ismember(i, [121, 241, 361, 481, 601])
        firstRows{end+1} = matrix(i, :); % Store the entire row
        firstIndices = [firstIndices, i]; % Store the index of this row
    end
end

% Collect the "Fifth" rows, excluding 121, 241, 361, 481, 601
for i = 1:720
    if strcmp(matrix{i, 1}, '5') && ~ismember(i, [121, 241, 361, 481, 601])
        fifthRows{end+1} = matrix(i, :); % Store the entire row
        fifthIndices = [fifthIndices, i]; % Store the index of this row
    end
end

% Randomize the "First" rows and "Fifth" rows
shuffledFirstRows = firstRows(randperm(length(firstRows)));
shuffledFifthRows = fifthRows(randperm(length(fifthRows)));

% Place the randomized rows back into the matrix
% Replace "First" rows with randomized ones, skipping 121, 241, 361, 481, 601
firstRowCount = length(firstRows);
for i = 1:firstRowCount
    matrix{firstIndices(i), 2} = shuffledFirstRows{i}{1, 2};
    matrix{firstIndices(i), 3} = shuffledFirstRows{i}{1, 3};
end

% Replace "Fifth" rows with randomized ones, skipping 121, 241, 361, 481, 601
fifthRowCount = length(fifthRows);
for i = 1:fifthRowCount
    matrix{fifthIndices(i), 2} = shuffledFifthRows{i}{1, 2};
    matrix{fifthIndices(i), 3} = shuffledFifthRows{i}{1, 3};
end

% Output to verify the results
fprintf('First and Fifth rows have been randomized, excluding 121, 241, 361, 481, and 601.\n');


% Initialize counters for the combinations in each range
counts = struct();

% Define the possible combinations
combinations = {
    'Yes Change', 'No Interference';
    'Yes Change', 'Right Interference';
    'Yes Change', 'Left Interference';
    'No Change', 'No Interference';
    'No Change', 'Right Interference';
    'No Change', 'Left Interference';
};

% Define the trial ranges
trialRanges = {
    1:120,       % Trials 1 to 120
    122:240,     % Trials 122 to 240
    241:360,     % Trials 241 to 360
    361:480,     % Trials 361 to 480
    481:600,     % Trials 481 to 600
    601:720      % Trials 601 to 720
};

% Loop through each range and count the occurrences of each combination
for r = 1:length(trialRanges)
    range = trialRanges{r};  % Get the current trial range
    countStruct = containers.Map(); % Use a map to store the counts

    % Initialize the count for each combination in the current range
    for c = 1:size(combinations, 1)
        combinationKey = [combinations{c, 1}, ' - ', combinations{c, 2}];  % Create a unique key for each combination
        countStruct(combinationKey) = 0; % Initialize counts to 0
    end

    % Loop through the trials in the current range
    for i = range
        % Check if the second and third columns match any combination
        for c = 1:size(combinations, 1)
            if strcmp(matrix{i, 2}, combinations{c, 1}) && strcmp(matrix{i, 3}, combinations{c, 2})
                combinationKey = [combinations{c, 1}, ' - ', combinations{c, 2}];  % Create a key for this combination
                countStruct(combinationKey) = countStruct(combinationKey) + 1; % Increment the count
            end
        end
    end

    % Store the counts for the current range
    counts.(['Range_' num2str(range(1)) '_' num2str(range(end))]) = countStruct;
end

% Display the counts for each range
for r = 1:length(trialRanges)
    range = trialRanges{r};  % Get the current trial range
    fprintf('\nTrial Range %d-%d:\n', range(1), range(end));
    countStruct = counts.(['Range_' num2str(range(1)) '_' num2str(range(end))]);

    % Display the counts for each combination
    keys = countStruct.keys;  % Get the keys for the combinations
    for k = 1:length(keys)
        key = keys{k};
        fprintf('%s: %d\n', key, countStruct(key));
    end
end


% Save the matrix to a .mat file
save('conditionMatrix.mat', 'matrix');

% Convert the cell array to a string array
stringMatrix = cellfun(@char, matrix, 'UniformOutput', false);

% Save the string matrix to a CSV file
writecell(stringMatrix, 'conditionMatrix.csv');