

%%%%%%%%Participant Number Input%%%%%%%%

% % Load the last participant number (if the file exists)
if exist('lastParticipantNumber.mat', 'file')
    load('lastParticipantNumber.mat');
else
    lastParticipantNumber = 1;  % Set a default starting number if the file doesn't exist
end

% Get or use the participant number
participantNumber = input(['Enter participant number (last used: ' num2str(lastParticipantNumber) '): ']);

% Save the current participant number for the next session
lastParticipantNumber = participantNumber;
save('lastParticipantNumber.mat', 'lastParticipantNumber');

%%%%%%%%Participant Number Input%%%%%%%%




%%%%%%%%Engage Next Condition File%%%%%%%%

% Load the last processed condition file
try
    load('lastProcessedCondition.mat');
catch
    % If the file doesn't exist, initialize the structure
    currentCondition = struct('currentConditionNumber', 1);
end

% Extract the numeric value
currentConditionNumber = currentCondition.currentConditionNumber;

% Increment the condition number and reset to 1 if it exceeds the total number of conditions
currentConditionNumber = mod(currentConditionNumber, 15) + 1;

% Update the structure with the new condition number
currentCondition.currentConditionNumber = currentConditionNumber;

% Save the updated structure
save('lastProcessedCondition.mat', 'currentCondition');

% Define the directory where the .mat files are stored
dataDir = 'C:\Users\eeglab1\Desktop\Ali Yılmaztekin\condition_files_experiment3_updated_mat'; % Change this to your actual directory

% Generate the filename for the current condition
useCondition = fullfile(dataDir, ['conditionMatrix' num2str(currentConditionNumber) '.mat']);

% Display the filename
disp(useCondition);

% Load the file and display the field names
commandValues = load(useCondition);

% Access the conditionMatrix from the structure
conditionMatrix = commandValues.matrix;

% Extract the second and third columns for context and interference
contextCommands = conditionMatrix(:, 2);  % Second column
interferenceCommands = conditionMatrix(:, 3);  % Third column







%%%%%%%%Engage Next Condition File%%%%%%%%





%%%%%%%%Initiliaze Screen and Relevant Vriables%%%%%%%%%

Screen('Preference', 'SkipSyncTests', 1)
% Options:
monitor = max(Screen('Screens'));

% Define the size and position of the window (e.g., a 600x400 window at position (100, 100))


% Which images to use (randomly ordered):
listOfTargets = Shuffle(dir('TestObjectsTransparent/*.png'));
imageNamesCell = {listOfTargets.name};


% % Load the image   
interferenceSquareFilename = 'colored_square.png'; % Load the white square image
[interferenceSquareLoad, map, alphaInterference] = imread(interferenceSquareFilename);

% % % Define a smaller screen rectangle (e.g., [x1 y1 x2 y2])
% windowWidth = 800;  % Width of the window
% windowHeight = 600; % Height of the window
% screenXOffset = 100; % Distance from the left side of the screen
% screenYOffset = 100; % Distance from the top of the screen
% 
% % Define the window rectangle
% rect = [screenXOffset, screenYOffset, screenXOffset + windowWidth, screenYOffset + windowHeight];


% Open the window with the specified dimensions
[win, winRect] = Screen('OpenWindow', monitor, [128 128 128]); 
% Open the small window
% [win, winRect] = Screen('OpenWindow', monitor);
Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
ifi = Screen('GetFlipInterval', win); %measure refresh rate

HideCursor(win);

centerX = round(winRect(3)/2);
centerY = round(winRect(4)/2);
colorWheel.radius = 225;
colorWheel.rect = CenterRect([0 0 colorWheel.radius*2 colorWheel.radius*2], winRect);
stim.size = 256;
intStimSize = 150;
stimRect = CenterRect([0 0 stim.size stim.size], winRect);
% % Parameters for the grid and square size
gridSize = 3; % Number of squares per row/column
squareSize = 100; % Size of each square
padding = 20; % Space between squares
% gridWidth = gridSize * squareSize + (gridSize - 1) * padding; % Total width of the grid
% gridHeight = gridSize * squareSize + (gridSize - 1) * padding; % Total height of the grid
alphaInterference = 255; % Transparency


%Parameters
screenHeight=winRect(4);
screenWidth=winRect(3);
yAxis = 1:screenHeight - stim.size;
xAxis = 1:screenWidth - stim.size;

% Define the offset distance from the center (e.g., half of the screen width divided by 2)
xOffset = round(winRect(3) / 4); % Quarter of the screen width

% Left and right rectangles for the stimuli
stimRectLeft = CenterRectOnPointd([0 0 stim.size stim.size], centerX - xOffset, centerY);
stimRectRight = CenterRectOnPointd([0 0 stim.size stim.size], centerX + xOffset, centerY);

frameMargin = 10; % Increase frame size by 10 pixels on all sides

% Expand the rectangle coordinates
frameRectLeft = [stimRectLeft(1) - frameMargin, ...
                      stimRectLeft(2) - frameMargin, ...
                      stimRectLeft(3) + frameMargin, ...
                      stimRectLeft(4) + frameMargin];

frameRectRight = [stimRectRight(1) - frameMargin, ...
                       stimRectRight(2) - frameMargin, ...
                       stimRectRight(3) + frameMargin, ...
                       stimRectRight(4) + frameMargin];

%%%%%%%%Initiliaze Screen and Relevant Vriables%%%%%%%%%




%%%%%%%%%Practice Begins%%%%%%%%%%%




%%%%%%%%Initiliaze Practice Variables%%%%%%%%%

% Reset the random number generator using the current time
rng('shuffle');

previousColourDegree = 0;
miniBlockEnd = 0;   
usedTargets = {};
randomBackgroundIndexAcross = {};
randomBackgroundAcross = {};
otherBackgroundIndex = {};
usedSurpriseDistractors = {};
usedAngels = cell(2,0);
usedSurpriseTargets = {};
errorRateList = [];
errorRate=0;
breakout=false;
selectedSide= 0;

participantNumber1 = zeros(1440, 1);
trialNumber = zeros(1440, 1);
contextChange = zeros(1440, 1);
interferencePresence = zeros(1440, 1);
angularDisparity = zeros(1440, 1);
targetPresented = strings(1440, 1);
conditionUsed = strings(1440, 1); 

currentPracticePair = {};
currentPracticeColors = {};

practiceCurrentBackground = [135 174 116];

textSize = 30;
Screen('TextSize', win, textSize);

blockCountdown = 120;
% Get the screen resolution
[screenXpixels, screenYpixels] = Screen('WindowSize', win);

%%%%%%%%Initiliaze Practice Variables%%%%%%%%%


% Define keys
qKey = KbName('q');
sevenKey = KbName('7');



% %%%%%%%%Pre-Test Practice Begins%%%%%%%%%%%%
% 
practice = 1;

currentIteration =1;
while currentIteration <= 18

            if practice == 1
                    practiceInstructions= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\experimentinstricutionsENG.png');
                    practiceInstructionsTexture = Screen('MakeTexture', win, practiceInstructions);
                    Screen('DrawTexture', win, practiceInstructionsTexture);


                    % Flip the screen to show the text
                    Screen('Flip', win);

                    % Wait for a key press to continue
                    KbWait;
            end

            if practice == 8
                    backgroundInstructions= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\backgroundinstructionsENG.png');
                    backgroundInstructionsTexture = Screen('MakeTexture', win, backgroundInstructions);
                    Screen('DrawTexture', win, backgroundInstructionsTexture);

                    % Flip the screen to show the text
                    Screen('Flip', win);

                    % Wait for a key press to continue
                    KbWait;
            end


            if practice == 1 || practice == 7 || practice == 13
                % Choose a target among the targets
                practiceTargetIndex = randi(length(imageNamesCell));
                practiceTargetFilename = imageNamesCell{practiceTargetIndex};

                % Choose a target among the targets
                practiceDistractorIndex = randi(length(imageNamesCell));
                practiceDistractorFilename = imageNamesCell{practiceDistractorIndex};


                % Ensure target and distractor are different
                while strcmp(practiceTargetFilename, practiceDistractorFilename)
                    % Choose a target among the targets
                    practiceTargetIndex = randi(length(imageNamesCell));
                    practiceTargetFilename = imageNamesCell{practiceTargetIndex};

                    % Choose a target among the targets
                    practiceDistractorIndex = randi(length(imageNamesCell));
                    practiceDistractorFilename = imageNamesCell{practiceDistractorIndex};
                end

                currentPracticePair = {};
                currentPracticePair = {practiceTargetFilename, practiceDistractorFilename};

                imageNamesCell(practiceTargetIndex) = [];
                imageNamesCell(practiceDistractorIndex) = [];

                % Load the random target
                [practiceTargetLoad, map, alpha] = imread((fullfile('TestObjectsTransparent', practiceTargetFilename)));
                [practiceDistractorLoad, mapDistractor, alphaDistractor] = imread((fullfile('TestObjectsTransparent', practiceDistractorFilename)));


                % Choose the degree of colour to be assigned to the target
                minColourDegreePractice = 1;
                maxColourDegreePractice = 360;
                practiceColourDegree = randi([minColourDegreePractice, maxColourDegreePractice]);
                practiceDistractorDegree = randi([minColourDegreePractice, maxColourDegreePractice]);


                if (abs(practiceColourDegree - practiceDistractorDegree)) < 60
                    practiceDistractorDegree = practiceDistractorDegree + 60;
                end

                currentPracticeColors = {};
                currentPracticeColors = {practiceColourDegree, practiceDistractorDegree};

                % Convert the image to LAB only once to speed up color rotations:
                savedLab = colorspace('rgb->lab', practiceTargetLoad);
                % Convert the image to LAB only once to speed up color rotations:
                savedLabDistractor = colorspace('rgb->lab', practiceDistractorLoad);

                % Fetch the colour 
                newRgb = RotateImage(savedLab, practiceColourDegree);

                newRgbDistractor = RotateImage(savedLabDistractor, practiceDistractorDegree);

                newRgb(:,:,4)=alpha;
                newRgbDistractor(:,:,4)=alphaDistractor;

                % Project the colour onto the target     
                practiceTargetTexture = Screen('MakeTexture', win, newRgb);
                practiceDistractorTexture = Screen('MakeTexture', win, newRgbDistractor);

                practiceTargetDistractorPair = {};
                practiceTargetDistractorPair = {practiceTargetTexture, practiceDistractorTexture};
                practiceTargetDistractorPair{2, 1} = practiceColourDegree;
                practiceTargetDistractorPair{2, 2} = practiceDistractorDegree;

                % Randomly pick one index (1 or 2)
                leftHalfIndex = randi([1, 2]);
                rightHalfIndex = 3 - leftHalfIndex;

                % Get the randomly selected texture
                leftHalfTexture = practiceTargetDistractorPair{1, leftHalfIndex};
                rightHalfTexture = practiceTargetDistractorPair{1, rightHalfIndex};

                if any(practice == 13:18)
                    Screen('FillRect' , win, [255 255 255], [0 0 screenWidth screenHeight]);
                    Screen('Flip', win);
                    WaitSecs(0.4);
                end

                Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                Screen('DrawTexture', win, leftHalfTexture, [], stimRectLeft);
                Screen('DrawTexture', win, rightHalfTexture, [], stimRectRight);

                % frameThick = 5;
                % 
                % Screen('FrameRect', win, [0 255 0], frameRectLeft, frameThick);
                % Screen('FrameRect', win, [0 255 0], frameRectRight, frameThick);
                % 
                Screen('Flip', win);

                if practice == 1
                    WaitSecs(7);
                    Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                    Screen('Flip', win);
                    WaitSecs(1);
                elseif practice == 7
                    WaitSecs(3);
                    Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                    Screen('Flip', win);
                    WaitSecs(1);
                elseif practice == 13
                    WaitSecs(0.5);
                    Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                    Screen('Flip', win);
                    WaitSecs(0.6);
                end
            else
                if practice == 5
                    interferenceWarning= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\interferencewarningENG.png');
                    interferenceWarningTexture = Screen('MakeTexture', win, interferenceWarning);
                    Screen('DrawTexture', win, interferenceWarningTexture);


                    % Flip the screen to show the text
                    Screen('Flip', win);

                    % Wait for a key press to continue
                    KbWait;
                end

                if any(practice == 13:18)
                    Screen('FillRect' , win, [255 255 255], [0 0 screenWidth screenHeight])
                    Screen('Flip', win);
                    WaitSecs(0.4);
                end

                if practice < 8 || practice >= 13
                    Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                    Screen('DrawTexture', win, leftHalfTexture, [], stimRectLeft);
                    Screen('DrawTexture', win, rightHalfTexture, [], stimRectRight);

                    % Screen('FrameRect', win, [0 255 0], frameRectLeft, frameThick);
                    % Screen('FrameRect', win, [0 255 0], frameRectRight, frameThick);
                elseif practice >= 8 && practice < 13
                    practiceCurrentBackground = [165 127 151];
                    Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                    Screen('DrawTexture', win, leftHalfTexture, [], stimRectLeft);
                    Screen('DrawTexture', win, rightHalfTexture, [], stimRectRight);

                    % Screen('FrameRect', win, [255 0 0], frameRectLeft, frameThick);
                    % Screen('FrameRect', win, [255 0 0], frameRectRight, frameThick);
                end

                if practice <=12
                    Screen('Flip', win);
                    WaitSecs(3);
                    Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                    Screen('Flip', win);
                    WaitSecs(1);
                elseif practice >=13
                    Screen('Flip', win);
                    WaitSecs(0.5);
                    Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                    Screen('Flip', win);
                    WaitSecs(0.6);
                end
            end

            if practice == 5 || practice == 11 || practice == 17

                        Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);

                        % % Generate 9 numbers according to the described logic
                        % 
                        % Start by randomly picking a number between 1 and 360
                        first_number = randi([1, 360]);

                        % Initialize the array to store the numbers
                        numbers = zeros(1, 9);
                        numbers(1) = first_number;

                        % Generate the sequence
                        for i = 2:9
                            next_number = numbers(i-1) + 40; % Changed difference to 40      
                            % If the number exceeds 360, subtract 360
                            if next_number > 360
                                next_number = next_number - 360; 
                            end
                            numbers(i) = next_number;
                        end

                        % Randomize the order of selected numbers
                        % Divide numbers into three groups
                        numbers_group1 = numbers(numbers >= 1 & numbers <= 120);
                        numbers_group2 = numbers(numbers >= 121 & numbers <= 240);
                        numbers_group3 = numbers(numbers >= 241 & numbers <= 360);

                        % Recreate numbers by selecting randomly from groups and randomizing group order
                        numbers = [];
                        num_groups = {numbers_group1, numbers_group2, numbers_group3};
                        random_group_order = randperm(3);
                        while any(cellfun(@(x) ~isempty(x), num_groups))
                            for i = random_group_order
                                if ~isempty(num_groups{i})
                                    % Select a random number from the current group
                                    idx = randi(length(num_groups{i}));
                                    numbers = [numbers, num_groups{i}(idx)];
                                    % Remove the selected number from the group
                                    num_groups{i}(idx) = [];
                                end
                            end
                            % Re-randomize the group order
                            random_group_order = randperm(3);
                        end


                        numbersWithRepeat = [];
                        numbersWithRepeat = numbers;

                        % Randomly select an index to remove
                        removeIndex = randi(length(numbersWithRepeat));

                        % Store the number at the removed index
                        removedNumber = numbersWithRepeat(removeIndex);

                        % Remove the number from the list
                        numbersWithRepeat(removeIndex) = [];

                        % Randomly select an index from the remaining list to copy
                        copyIndex = randi(length(numbersWithRepeat));

                        % Insert the copied number into the position of the removed number
                        numbersWithRepeat = [numbersWithRepeat(1:removeIndex-1), numbersWithRepeat(copyIndex), numbersWithRepeat(removeIndex:end)];


                        % Combine them into one matrix, each as a separate row
                        interferenceNumbersMatrix = [numbers; numbersWithRepeat]; 

                        randomInterferenceRowIndex = randi([1, 2]);  

                        currentInterferenceRow = interferenceNumbersMatrix(randomInterferenceRowIndex, :);

                        % Assume selected_numbers is a vector of 9 unique numbers
                        numColors = length(currentInterferenceRow);  % Number of unique colors to apply

                        % Initialize counter for color index
                        colorIndex = 1;

                        % Calculate the total width and height of the grid (including padding)
                        gridWidth = gridSize * squareSize + (gridSize - 1) * padding;  % Total width of the grid
                        gridHeight = gridSize * squareSize + (gridSize - 1) * padding; % Total height of the grid

                        % Calculate the position to center the grid on the screen
                        gridPosX = centerX - gridWidth / 2;
                        gridPosY = centerY - gridHeight / 2;

                        % % Define the size of the black square (a little larger than the grid)
                        % blackSquareSize = (gridSize * (squareSize + padding)) + padding;  % Adding padding for a slightly larger square
                        % 
                        % % Calculate the position of the black square (centered behind the grid)
                        % blackSquareX = centerX - blackSquareSize / 2;
                        % blackSquareY = centerY - blackSquareSize / 2;
                        % blackSquareRect = [blackSquareX, blackSquareY, blackSquareX + blackSquareSize, blackSquareY + blackSquareSize];

                        % Draw the black square behind the grid
                        % Screen('FillRect', win, [0, 0, 0], blackSquareRect);  % Draw black square

                        % Draw the grid of squares
                        for row = 0:gridSize-1
                            for col = 0:gridSize-1
                                % Calculate position for each square
                                posX = gridPosX + col * (squareSize + padding);  
                                posY = gridPosY + row * (squareSize + padding);
                                destRect = [posX, posY, posX + squareSize, posY + squareSize];

                                % Get the current interference color degree from the list
                                interferenceColourDegree = currentInterferenceRow(colorIndex);


                                % Convert the image to LAB only once to speed up color rotations
                                savedLab = colorspace('rgb->lab', interferenceSquareLoad);

                                % Fetch the color
                                newRgb = RotateImage(savedLab, interferenceColourDegree);

                                % Apply alpha transparency
                                newRgb(:,:,4) = alphaInterference;

                                % Project the color onto the target     
                                interferenceTexture = Screen('MakeTexture', win, newRgb); 

                                % Draw the texture
                                Screen('DrawTexture', win, interferenceTexture, [], destRect);

                                % Increment the color index and loop back to 1 if we exceed the color list
                                colorIndex = mod(colorIndex, numColors) + 1;
                            end
                        end

                        Screen('DrawText', win, '"A" -> same      "D" -> different', centerX-200, centerY-300, [0 0 0]);

                        % % Flip the screen to display the grid
                        Screen('Flip', win);

                       % Wait for user input with a time limit
                        keyPressed = false; % Initialize keyPressed as false
                        selectedSide = NaN;   % Default value if space is not pressed
                        timeLimit = 5;      % Set the time limit (in seconds)
                        startTime = GetSecs; % Record the start time

                        while ~keyPressed
                            % Check if the time limit has been exceeded
                            if GetSecs - startTime > timeLimit
                                keyPressed = true; % Exit the loop
                                selectedSide = NaN; % Assign NaN to indicate no response
                                break;
                            end

                            % Check for key presses
                            [keyIsDown, ~, keyCode] = KbCheck;
                            if keyIsDown
                                if keyCode(KbName('a')) % If 'A' is pressed
                                    keyPressed = true;
                                    selectedSide = 2;
                                elseif keyCode(KbName('d')) % If 'D' is pressed
                                    keyPressed = true;
                                    selectedSide = 1;
                                else
                                    % Wait for key release if it's not A or D
                                    KbReleaseWait;
                                end
                            end

                            WaitSecs(0.01); % Prevents CPU overload
                        end

                        % Check if a response was made before proceeding with correctness evaluation
                        if isnan(selectedSide)
                            % Display "Time Up!" message
                            Screen('FillRect', win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                            DrawFormattedText(win, 'Please respond quicker!', 'center', 'center', [255, 0, 0]);
                        else
                            if selectedSide == randomInterferenceRowIndex
                                Screen('FillRect', win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                                DrawFormattedText(win, 'Correct Answer!', 'center', 'center', [0, 255, 0]);
                            else
                                Screen('FillRect', win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                                DrawFormattedText(win, 'Wrong Answer!', 'center', 'center', [255, 0, 0]);                          
                            end
                        end

                        % Flip the screen to display the message
                        Screen('Flip', win);
                        WaitSecs(0.2);  
            end

                Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);

          if practice ==1
                    colouReportInstructions= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\colourreportinstructionsENG.png');
                    colouReportInstructionsTexture = Screen('MakeTexture', win, colouReportInstructions);
                    Screen('DrawTexture', win, colouReportInstructionsTexture);


                    % Flip the screen to show the text
                    Screen('Flip', win);

                    % Wait for a key press to continue
                    KbWait;

                    Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
          end


                tempPractice=Shuffle(0:45:315);
                randomAdditionPractice=tempPractice(1);

                startTime = GetSecs;

                %First, randomly decide which of the presented objects will be
                %tested.

                randomTestObjectIndex = randi([1, 2]);
                randomTestObjectUnprocessed = {};
                toBeTestedColorDegree = 0;

                randomTestObjectUnprocessed = currentPracticePair{randomTestObjectIndex};
                toBeTestedColorDegree = currentPracticeColors{randomTestObjectIndex};



                % Show in grayscale:
                [originalImgPractice, map, alpha] = imread(fullfile('TestObjectsTransparent',randomTestObjectUnprocessed)); 
                % originalImg = imresize(originalImg, [stim.size stim.size]); 
                imgGrayPractice = repmat(mean(originalImgPractice,3), [1 1 3]);
                imgGrayPractice(:,:,4)=alpha;

                curTexturePractice = Screen('MakeTexture', win, imgGrayPractice);
                Screen('DrawTexture', win, curTexturePractice, [], stimRect);

                % Show color report circle:

                Screen('FrameOval', win, [0,0,0], colorWheel.rect);
                Screen('Flip', win);

                % Center mouse
                SetMouse(centerX,centerY,win);

                % Convert the image to LAB only once to speed up color rotations:
                savedLab = colorspace('rgb->lab', originalImgPractice);

                % Wait until the mouse moves:
                [curX,curY] = GetMouse(win);
                while (curX == centerX && curY == centerY)
                  [curX,curY] = GetMouse(win);
                end

                % Show object in correct color for current angle and wait for click:
                buttons = [];
                while ~any(buttons)  

                  [curX,curY, buttons] = GetMouse(win);
                  curAnglePractice = GetPolarCoordinates(curX,curY,centerX,centerY);
                  [dotX1, dotY1] = polar2xy(curAnglePractice,colorWheel.radius-5,centerX,centerY);
                  [dotX2, dotY2] = polar2xy(curAnglePractice,colorWheel.radius+20,centerX,centerY);

                  if (curAnglePractice ~= practiceColourDegree) && round(curAnglePractice) ~= 0 

                    newRgb = RotateImage(savedLab, round(curAnglePractice)+randomAdditionPractice);
                    newRgb(:,:,4)=alpha;
                    Screen('Close', curTexturePractice);
                    curTexturePractice = Screen('MakeTexture', win, newRgb);
                  end

                  % Show stimulus:

                  Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);

                  % Draw frame and dot
                  Screen('FrameOval', win, [0 0 0], colorWheel.rect);
                  Screen('DrawLine', win, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);

                  Screen('DrawTexture', win, curTexturePractice, [], stimRect);


                  Screen('Flip', win);

                  % Allow user to quit on each frame:

                    [keyIsDown, ~, keyCode] = KbCheck;
                    if keyIsDown && keyCode(qKey) && keyCode(sevenKey) 
                        sca; error('User quit');
                    end

                end


                Screen('Close', curTexturePractice);

                % Allow user to quit on each frame:


                % Wait for release of mouse button
                while any(buttons), [~,~,buttons] = GetMouse(win); end
                responseTime = GetSecs;

                randomTestObjectColorDegree = 0;



                %Correct for circular space degrees
                angular_disparityPractice=(toBeTestedColorDegree-(curAnglePractice+randomAdditionPractice));
                if angular_disparityPractice>180
                    angular_disparityPractice=angular_disparityPractice-360;
                elseif angular_disparityPractice<-180
                    angular_disparityPractice=angular_disparityPractice+360;
                end

                angularDisparity(practice)=angular_disparityPractice;
                if any(practice == 13:18)
                    errorRateList(end+1) = abs(angular_disparityPractice);
                end

                errorRate=mean(errorRateList);



                % Format the reaction time for display
                formattedReactionTime = sprintf('%.3f seconds', responseTime);

                % Display the formatted reaction time


                Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
                Screen('DrawText', win, ['Angular Disparity Rate: ' num2str(round(abs(angular_disparityPractice)))], centerX-125, centerY-525, [250 0 0]); 
                if abs(angular_disparityPractice) <= 5
                    Screen('DrawText', win, 'Excellent!', centerX-30, centerY-475, [250 0 0]); 
                elseif abs(angular_disparityPractice) > 5 && abs(angular_disparityPractice) <= 15
                    Screen('DrawText', win, 'Great!', centerX-45, centerY-475, [250 0 0]); 
                elseif abs(angular_disparityPractice) > 15 && abs(angular_disparityPractice) <= 25
                    Screen('DrawText', win, 'Nice!', centerX-30, centerY-475, [250 0 0]);
                elseif abs(angular_disparityPractice) > 25 && abs(angular_disparityPractice) <= 35
                    Screen('DrawText', win, 'Not Bad', centerX-45, centerY-475, [250 0 0]);
                elseif abs(angular_disparityPractice) > 35
                    Screen('DrawText', win, 'Could be better', centerX-80, centerY-475, [250 0 0]);
                end

                Screen('Flip', win);
                WaitSecs(0.75); 

             if practice == 12
                %%%%the end of instructions -- proceed to practice%%%%
                transitionToPractice= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\transitiontopracticeENG.png');
                transitionToPracticeTexture = Screen('MakeTexture', win, transitionToPractice);
                Screen('DrawTexture', win, transitionToPracticeTexture);


                % Flip the screen to show the text
                Screen('Flip', win);

                % Wait for a key press to continue
                KbWait;

                Screen('FillRect' , win, practiceCurrentBackground, [0 0 screenWidth screenHeight]);
              end


            if currentIteration == 18
            % Check the value and reset the loop index if needed
                if errorRate > 30
                    errorRateAlarm= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\errorratealarmENG.png');
                    errorRateAlarmTexture = Screen('MakeTexture', win, errorRateAlarm);
                    Screen('DrawTexture', win, errorRateAlarmTexture);


                    % Flip the screen to show the text
                    Screen('Flip', win);

                    % Wait for a key press to continue
                    KbWait;

                    practice = 13;
                    currentIteration = 13;
                    errorRateList = [];
                    errorRate=0;
                    continue;  % Continue to the next iteration
                else
                    breakout=true;
                end
            end

        if breakout
            break;
        end
        practice = practice + 1;
        currentIteration = currentIteration + 1;
        % 
        % if practice == 14
        %     break
        % end

end


%%%%%%%Pre-Test Practice Ends%%%%%%%%%%%%


endOfPractice= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\endofpracticeinstructionsENG.png');
endOfPracticeTexture = Screen('MakeTexture', win, endOfPractice);
Screen('DrawTexture', win, endOfPracticeTexture);


% Flip the screen to show the text
Screen('Flip', win);

% Wait for a key press to continue
KbWait;


%%%%Resetting variables after practice%%%%%


% Calculate the total width and height of the grid (including padding)
gridWidth = gridSize * squareSize + (gridSize - 1) * padding;  % Total width of the grid
gridHeight = gridSize * squareSize + (gridSize - 1) * padding; % Total height of the grid



% Calculate the position to center the grid on the screen
gridPosX = centerX - gridWidth / 2;
gridPosY = centerY - gridHeight / 2;

previousColourDegree = 0;
previousDistractorDegree = 0;

miniBlockEnd = 0;   
usedTargets = strings(120, 1);
usedDistractors = strings(120, 1);
randomBackgroundIndexAcross = strings(720, 1); 
randomBackgroundAcross = strings(720, 1); 
otherBackgroundIndex = strings(720, 1); 
usedSurpriseDistractors = strings(720, 1); 
usedAngels = cell(2,0);
usedDistAngels = cell(2,0);
usedSurpriseTargets = strings(720, 1); 

participantNumber1 = zeros(720, 1);
trialNumber = zeros(720, 1);
contextChange = strings(720, 1);
interferencePresence = zeros(720, 1);
angularDisparity = zeros(720, 1);
targetPresented = strings(720, 1);
distractorTestPresented = strings(720, 1);
targetTestPresented = strings(720, 1);
testedImage = strings(720,1);
conditionUsed = strings(720, 1); 

participantNumber2 = zeros(240, 1);
trialNumber2 = zeros(240, 1);
trueOrFalse = zeros(240, 1);  %1==true, 2==false
angularDisparity2 = zeros(240, 1);
targetPresented2 = strings(240, 1);
distractorPresented = strings(720,1);
distractor2Presented = strings(240, 1);
repRange = 1:6;
repeatedArray = repmat(repRange, 1, ceil(720 / length(repRange)));
resultArray = repeatedArray(1:720);
resultColumnVector = resultArray(:);
onsetTime= zeros(720, 1);
moveTime = zeros(720, 1);
RTActual = zeros(720, 1);
interferenceRT = zeros(720, 1);
onsetTimeSurprise = zeros(240, 1);
moveTimeSurprise = zeros(240, 1);
RTActualSurprise = zeros(240, 1);
disparityRates = [];
blockEndTrials = [];
breakTime = zeros(720, 1);
% remainingBlocks = max(blocks);

firstContext=strings(720, 1);
firstInterference=strings(720, 1);
fifthContext=strings(720, 1);
fifthInterference=strings(720, 1);
blocks = zeros(720,1);
interferenceActual = strings (720,1);
interferenceSelection = strings (720,1);
interferenceRGBs = strings (720,1);
targetColorRGB = strings (720,1);
distractorColorRGB = strings (720,1);

currentTargetColorRGB = '';
currentDistractorColorRGB = '';

randomContextIndex = 0;
currentContextIndex = 0;
greenBackground = [135 174 116];
redBackground = [165 127 151];
backgrounds = {greenBackground, redBackground};
currentPair = {};
currentPairColors = {};
currentBackground = {};
currentBackground = backgrounds{randi(2)};

imageNamesCell = {listOfTargets.name};

%Event Durations

itiDuration = 0.300;
encodingDuration = 0.600;
retentionDuration = 0.900;
preInterferenceInterval = 0.200;
postInterferenceInterval = 0.200;
interferenceFeedbackDuration = 0.400;



%%%%Resetting variables after practice%%%%%








%%%%%%%%%Actual Experiment Begins%%%%%%%%%%%








%%%%%%%%%%%%%%%%%Target Phase%%%%%%%%%%%%%%%%%%%%%

for trial = 1:720 
    rounderS=GetSecs;
    participantNumber1(trial) = participantNumber;
    trialNumber(trial) = trial;
    conditionUsed(trial) = useCondition;

    if trial <=120
        currentBlock = 0;
    elseif trial >=121 && trial <=240
        currentBlock = 1;
    elseif trial >=241 && trial <=360
        currentBlock = 2;
    elseif trial >=361 && trial <=480
        currentBlock = 3;
    elseif trial >=481 && trial <=600
        currentBlock = 4;
    elseif trial >=601 && trial <=720
        currentBlock = 5;
    end

    blocks(trial)=(currentBlock)+1;

    if trial>=2
        if trial == 121 || trial == 241 || trial == 361 || trial == 481 || trial == 601
            remainingBlocks = 6 - currentBlock;
            blockEndTrials(end+1)=(trial-1);
            blockendImage= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\blockendENG.png');
            blockendImageTexture = Screen('MakeTexture', win, blockendImage);
            averageBlockError1= num2str(round(abs(sum(disparityRates)/(blockEndTrials(end)))));
            averageBlockError= num2str(round(abs(sum(disparityRates)/((trial-(blockEndTrials(end))+1)))));
            
            % Set the duration of the countdown in seconds
            countdownDuration = 300; % 2 minutes
            
            KbName('UnifyKeyNames');
            
            % Get the starting time
            startTime = GetSecs;
            
            % Main loop
            while GetSecs - startTime < countdownDuration
                % Check for any key press
                [~, ~, keyCode] = KbCheck;
                if any(keyCode)
                    % Exit the loop if any key is pressed
                    break;
                end
                
                % Calculate time remaining
                timeRemaining = countdownDuration - (GetSecs - startTime);
                
                % Convert time remaining to minutes and seconds
                minutesRemaining = floor(timeRemaining / 60);
                secondsRemaining = mod(floor(timeRemaining), 60);

                 % Draw the image
                Screen('DrawTexture', win, blockendImageTexture);
                         
                % Display the time remaining on the screen
                DrawFormattedText(win, sprintf('%02d:%02d', minutesRemaining, secondsRemaining), centerX, centerY-375, [255 0 0]);
                Screen('DrawText', win, ['Remaining blocks: ' num2str(remainingBlocks)], centerX-125, centerY-525, [250 0 0])
                Screen('Flip', win);
            end
           
            
            % Flip the screen to show the text
            
            breakTime(trial)=120-timeRemaining;
            disparityRates = [];
            averageBlockError1= 0;
            averageBlockError= 0;

            % Specify the file name
            fileName = ['output_data', num2str(participantNumber), '.xlsx'];
            
            % Write the matrix to a CSV file
            writematrix(dataMatrix, fileName);
        
            fileName2 = ['output_data', num2str(participantNumber), '.mat'];
            % Save the matrix in a .mat file
            save(fileName2, 'dataMatrix');

            % Wait for a key press to continue
            KbWait;
            
            WaitSecs(2)
        end
    end
    
    %%%ITI display%%%
    Screen('FillRect' , win, [255 255 255], [0 0 screenWidth screenHeight])
    [~, iti_onset] = Screen('Flip', win);

    
    if miniBlockEnd == 0
        
        stim_onset_time = iti_onset + itiDuration - ifi / 2; % Correct for refresh lag

        while true  % Infinite loop, will break when condition is met
            % Choose a target among the targets
            currentTargetIndex = randi(length(imageNamesCell));
            currentTargetFilename = imageNamesCell{currentTargetIndex};
        
            % Choose a distractor
            currentDistractorIndex = randi(length(imageNamesCell));
            currentDistractorFilename = imageNamesCell{currentDistractorIndex};
        
            % Now check the condition after both have been updated
            if ~strcmp(currentTargetFilename, currentDistractorFilename)
                break;  % Exit only after a complete iteration
            end
        end

        currentPair = {};
        currentPair = {currentTargetFilename, currentDistractorFilename};

        imageNamesCell = setdiff(imageNamesCell, currentPair, 'stable');

        % Load the random target
        [currentTargetLoad, mapTarget, alphaTarget] = imread((fullfile('TestObjectsTransparent', currentTargetFilename)));
        [currentDistractorLoad, mapDistractor, alphaDistractor] = imread((fullfile('TestObjectsTransparent', currentDistractorFilename)));
       
        minColourDegree = 1;
        maxColourDegree = 360;
        
        % Pick the target color degree once:
        currentColourDegree = randi([minColourDegree, maxColourDegree]);
        
        minSeparation = 60;
        valid = false;
        
        while ~valid
            % Only pick distractor inside the loop:
            currentDistractorDegree = randi([minColourDegree, maxColourDegree]);
        
            % Normalize 360 to 0 for clarity:
            c = currentColourDegree;
            d = currentDistractorDegree;
            if c == 360, c = 0; end
            if d == 360, d = 0; end
        
            separation = min(mod(abs(c - d), 360), 360 - mod(abs(c - d), 360));
        
            if separation >= minSeparation
                valid = true;
            end
        end

        currentPairColors = {};
        currentPairColors = {currentColourDegree, currentDistractorDegree};

        currentTargetColorRGB = '';
        currentDistractorColorRGB = '';
        currentTargetColorRGB = string(currentPairColors{1});
        currentDistractorColorRGB = string(currentPairColors{2});

        targetColorRGB(trial) = currentTargetColorRGB;
        distractorColorRGB(trial) = currentDistractorColorRGB;

        % Convert the image to LAB only once to speed up color rotations:
        savedLab = colorspace('rgb->lab', currentTargetLoad);

        % Convert the image to LAB only once to speed up color rotations:
        savedLabDistractor = colorspace('rgb->lab', currentDistractorLoad);

        % Fetch the colour 
        newRgbTarget = RotateImage(savedLab, currentColourDegree);

        newRgbTarget(:,:,4)=alphaTarget;

        % Fetch the colour 
        newRgbDistractor = RotateImage(savedLabDistractor, currentDistractorDegree);

        newRgbDistractor(:,:,4)=alphaDistractor;

        % Project the colour onto the target     
        currentTargetTexture = Screen('MakeTexture', win, newRgbTarget);

        % Project the colour onto the target     
        currentDistractorTexture = Screen('MakeTexture', win, newRgbDistractor);

        if strcmp(contextCommands{trial}, 'Yes Change')
            % Use randi to pick either green or red
            currentBackground = backgrounds{randi(2)};
            contextChange(trial) = "Yes Change";
        else
            contextChange(trial) = "No Change";
        end
   
        Screen('FillRect' , win, currentBackground, [0 0 screenWidth screenHeight]);
        Screen('DrawTexture', win, currentTargetTexture, [], stimRectRight);
        Screen('DrawTexture', win, currentDistractorTexture, [], stimRectLeft);
        
        % Present the stimuli for encoding (exactly at time 300 ms, right
        % after ITI is finished
        [~, stim_onset] = Screen('Flip', win, stim_onset_time); 

        preInterferenceRetentionOnset_time = stim_onset + encodingDuration - ifi / 2; 

        targetTestPresented(trial) = currentTargetFilename;
        distractorTestPresented(trial) = currentDistractorFilename;

    elseif miniBlockEnd == 6
        miniBlockEnd = 0;

        stim_onset_time = iti_onset + itiDuration - ifi / 2; % Correct for refresh lag

        while true  % Infinite loop, will break when condition is met
            % Choose a target among the targets
            currentTargetIndex = randi(length(imageNamesCell));
            currentTargetFilename = imageNamesCell{currentTargetIndex};
        
            % Choose a distractor
            currentDistractorIndex = randi(length(imageNamesCell));
            currentDistractorFilename = imageNamesCell{currentDistractorIndex};
        
            % Now check the condition after both have been updated
            if ~strcmp(currentTargetFilename, currentDistractorFilename)
                break;  % Exit only after a complete iteration
            end
        end

        currentPair = {};
        currentPair = {currentTargetFilename, currentDistractorFilename};

        imageNamesCell = setdiff(imageNamesCell, currentPair, 'stable');

        % Load the random target
        [currentTargetLoad, mapTarget, alphaTarget] = imread((fullfile('TestObjectsTransparent', currentTargetFilename)));
        [currentDistractorLoad, mapDistractor, alphaDistractor] = imread((fullfile('TestObjectsTransparent', currentDistractorFilename)));
       
        minColourDegree = 1;
        maxColourDegree = 360;
        
        % Pick the target color degree once:
        currentColourDegree = randi([minColourDegree, maxColourDegree]);
        
        minSeparation = 60;
        valid = false;
        
        while ~valid
            % Only pick distractor inside the loop:
            currentDistractorDegree = randi([minColourDegree, maxColourDegree]);
        
            % Normalize 360 to 0 for clarity:
            c = currentColourDegree;
            d = currentDistractorDegree;
            if c == 360, c = 0; end
            if d == 360, d = 0; end
        
            separation = min(mod(abs(c - d), 360), 360 - mod(abs(c - d), 360));
        
            if separation >= minSeparation
                valid = true;
            end
        end
        
        currentPairColors = {};
        currentPairColors = {currentColourDegree, currentDistractorDegree};

        currentTargetColorRGB = '';
        currentDistractorColorRGB = '';
        currentTargetColorRGB = string(currentPairColors{1});
        currentDistractorColorRGB = string(currentPairColors{2});

        targetColorRGB(trial) = currentTargetColorRGB;
        distractorColorRGB(trial) = currentDistractorColorRGB;

        % Convert the image to LAB only once to speed up color rotations:
        savedLab = colorspace('rgb->lab', currentTargetLoad);

        % Convert the image to LAB only once to speed up color rotations:
        savedLabDistractor = colorspace('rgb->lab', currentDistractorLoad);

        % Fetch the colour 
        newRgbTarget = RotateImage(savedLab, currentColourDegree);

        newRgbTarget(:,:,4)=alphaTarget;

        % Fetch the colour 
        newRgbDistractor = RotateImage(savedLabDistractor, currentDistractorDegree);

        newRgbDistractor(:,:,4)=alphaDistractor;

        % Project the colour onto the target     
        currentTargetTexture = Screen('MakeTexture', win, newRgbTarget);

        % Project the colour onto the target     
        currentDistractorTexture = Screen('MakeTexture', win, newRgbDistractor);
    
        if strcmp(contextCommands{trial}, 'Yes Change')
            if currentBackground == greenBackground
                currentBackground = redBackground;
                contextChange(trial) = "Yes Change";
            elseif currentBackground == redBackground
                currentBackground = greenBackground;
                contextChange(trial) = "Yes Change";
            end
        else
            contextChange(trial) = "No Change";
        end
        
        Screen('FillRect' , win, currentBackground, [0 0 screenWidth screenHeight]);
        Screen('DrawTexture', win, currentTargetTexture, [], stimRectRight);
        Screen('DrawTexture', win, currentDistractorTexture, [], stimRectLeft);
   
        % Present the stimuli for encoding (exactly at time 300 ms, right
        % after ITI is finished
        [~, stim_onset] = Screen('Flip', win, stim_onset_time); 

        preInterferenceRetentionOnset_time = stim_onset + encodingDuration - ifi / 2;

        targetTestPresented(trial) = currentTargetFilename;
        distractorTestPresented(trial) = currentDistractorFilename;      

    else
        % Depending on the command value, make a within or across change

        stim_onset_time = iti_onset + itiDuration - ifi / 2; % Correct for refresh lag

        if strcmp(contextCommands{trial}, 'Yes Change')
            if currentBackground == greenBackground
                currentBackground = redBackground;
                contextChange(trial) = "Yes Change";
            elseif currentBackground == redBackground
                currentBackground = greenBackground;
                contextChange(trial) = "Yes Change";
            end
        else
            contextChange(trial) = "No Change";
        end
     
        Screen('FillRect' , win, currentBackground, [0 0 screenWidth screenHeight]);
        Screen('DrawTexture', win, currentTargetTexture, [], stimRectRight);
        Screen('DrawTexture', win, currentDistractorTexture, [], stimRectLeft);

        [~, stim_onset] = Screen('Flip', win, stim_onset_time);
        
        preInterferenceRetentionOnset_time = stim_onset + encodingDuration - ifi / 2;

        currentTargetColorRGB = '';
        currentDistractorColorRGB = '';
        currentTargetColorRGB = string(currentPairColors{1});
        currentDistractorColorRGB = string(currentPairColors{2});

        targetColorRGB(trial) = currentTargetColorRGB;
        distractorColorRGB(trial) = currentDistractorColorRGB;

        targetTestPresented(trial) = currentTargetFilename;
        distractorTestPresented(trial) = currentDistractorFilename;
  
    end
    
    
    
  %%%%%%%%%%%%%%%%%Target Phase%%%%%%%%%%%%%%%%%%%%%
          
 
  
  %%%%%%%%%%%%%Retention Phase%%%%%%%%%%%%%%%%%%

  Screen('FillRect', win, currentBackground, [0 0 screenWidth screenHeight]);
  [~, preInterferenceRetentionOnset] = Screen('Flip', win, preInterferenceRetentionOnset_time);


  if strcmp(interferenceCommands{trial}, 'Left Interference')
                    
                    interference_onset_time = preInterferenceRetentionOnset + preInterferenceInterval - ifi / 2;
                    
                    interferenceActual(trial) = "Unique Interference";

                    % % Generate 9 numbers according to the described logic
                    
                    % Start by randomly picking a number between 1 and 360
                    first_number = randi([1, 360]);

                    % Initialize the array to store the numbers
                    numbers = zeros(1, 9);
                    numbers(1) = first_number;

                    % Generate the sequence
                    for i = 2:9
                        next_number = numbers(i-1) + 40; % Changed difference to 40      
                        % If the number exceeds 360, subtract 360
                        if next_number > 360
                            next_number = next_number - 360; 
                        end
                        numbers(i) = next_number;
                    end

                    % Randomize the order of selected numbers
                    % Divide numbers into three groups
                    numbers_group1 = numbers(numbers >= 1 & numbers <= 120);
                    numbers_group2 = numbers(numbers >= 121 & numbers <= 240);
                    numbers_group3 = numbers(numbers >= 241 & numbers <= 360);

                    % Recreate numbers by selecting randomly from groups and randomizing group order
                    numbers = [];
                    num_groups = {numbers_group1, numbers_group2, numbers_group3};
                    random_group_order = randperm(3);
                    while any(cellfun(@(x) ~isempty(x), num_groups))
                        for i = random_group_order
                            if ~isempty(num_groups{i})
                                % Select a random number from the current group
                                idx = randi(length(num_groups{i}));
                                numbers = [numbers, num_groups{i}(idx)];
                                % Remove the selected number from the group
                                num_groups{i}(idx) = [];
                            end
                        end
                        % Re-randomize the group order
                        random_group_order = randperm(3);
                    end

                    numbersWithRepeat = [];
                    numbersWithRepeat = numbers;

                    % Randomly select an index to remove
                    removeIndex = randi(length(numbersWithRepeat));

                    % Store the number at the removed index
                    removedNumber = numbersWithRepeat(removeIndex);

                    % Remove the number from the list
                    numbersWithRepeat(removeIndex) = [];

                    % Randomly select an index from the remaining list to copy
                    copyIndex = randi(length(numbersWithRepeat));

                    % Insert the copied number into the position of the removed number
                    numbersWithRepeat = [numbersWithRepeat(1:removeIndex-1), numbersWithRepeat(copyIndex), numbersWithRepeat(removeIndex:end)];
   
                    % Combine them into one matrix, each as a separate row
                    interferenceNumbersMatrix = [numbers; numbersWithRepeat]; 

                    randomInterferenceRowIndex = 1;

                    num_str = strjoin(string(numbers), ', ');

                    interferenceRGBs(trial) = num_str;
  
                    currentInterferenceRow = interferenceNumbersMatrix(randomInterferenceRowIndex, :);

                    % Assume selected_numbers is a vector of 9 unique numbers
                    numColors = length(currentInterferenceRow);  % Number of unique colors to apply

                    % Initialize counter for color index
                    colorIndex = 1;
                   
                    % Draw the grid of squares
                    for row = 0:gridSize-1
                        for col = 0:gridSize-1
                            % Calculate position for each square
                            posX = gridPosX + col * (squareSize + padding);  
                            posY = gridPosY + row * (squareSize + padding);
                            destRect = [posX, posY, posX + squareSize, posY + squareSize];
                    
                            % Get the current interference color degree from the list
                            interferenceColourDegree = currentInterferenceRow(colorIndex);
                    
                            % Convert the image to LAB only once to speed up color rotations
                            savedLab = colorspace('rgb->lab', interferenceSquareLoad);
                    
                            % Fetch the color
                            newRgb = RotateImage(savedLab, interferenceColourDegree);
                    
                            % Apply alpha transparency
                            newRgb(:,:,4) = alphaInterference;
                    
                            % Project the color onto the target     
                            interferenceTexture = Screen('MakeTexture', win, newRgb); 
                    
                            % Draw the texture
                            Screen('DrawTexture', win, interferenceTexture, [], destRect);
                    
                            % Increment the color index and loop back to 1 if we exceed the color list
                            colorIndex = mod(colorIndex, numColors) + 1;
                        end
                    end

                    Screen('DrawText', win, '"A" -> same      "D" -> different', centerX-200, centerY-300, [0 0 0]);

                    % % Flip the screen to display the grid
                    [~, interferenceOnset] = Screen('Flip', win, interference_onset_time);

                    % Wait for user input with a time limit
                    keyPressed = false; % Initialize keyPressed as false
                    selectedSide = NaN;   % Default value if space is not pressed
                    timeLimit = 5;      % Set the time limit (in seconds)
                    startTime = GetSecs; % Record the start time
                    
                    while ~keyPressed
                        % Check if the time limit has been exceeded
                        if GetSecs - startTime > timeLimit
                            keyPressed = true; % Exit the loop
                            selectedSide = NaN; % Assign NaN to indicate no response
                            break;
                        end
                    
                        % Check for key presses
                        [keyIsDown, ~, keyCode] = KbCheck;
                        if keyIsDown
                            if keyCode(KbName('a')) % If 'A' is pressed
                                keyPressed = true;
                                selectedSide = 2;
                            elseif keyCode(KbName('d')) % If 'D' is pressed
                                keyPressed = true;
                                selectedSide = 1;
                            else
                                % Wait for key release if it's not A or D
                                KbReleaseWait;
                            end
                        end

                        WaitSecs(0.01);
                    end

                    currentInterferenceDecision = GetSecs; 

                    currentInterferenceRT = currentInterferenceDecision - interferenceOnset;

                    interferenceRT(trial) = currentInterferenceRT;

                    
                    % Check if a response was made before proceeding with correctness evaluation
                    if isnan(selectedSide)
                        % Display "Time Up!" message
                        Screen('FillRect', win, currentBackground, [0 0 screenWidth screenHeight]);
                        DrawFormattedText(win, 'Please respond quicker!', 'center', 'center', [255, 0, 0]);
                        interferenceSelection(trial) = "No Response";
                    else
                        if selectedSide == randomInterferenceRowIndex
                            Screen('FillRect', win, currentBackground, [0 0 screenWidth screenHeight]);
                            DrawFormattedText(win, 'Correct Answer!', 'center', 'center', [0, 255, 0]);
                            interferenceSelection(trial) = "Correct";
                        else
                            Screen('FillRect', win, currentBackground, [0 0 screenWidth screenHeight]);
                            DrawFormattedText(win, 'Wrong Answer!', 'center', 'center', [255, 0, 0]);
                            interferenceSelection(trial) = "Wrong";
                        end
                    end

                    interferenceFeedbackOnset_time = interferenceOnset + interferenceFeedbackDuration - ifi / 2;

                    [~, interferenceFeedbackOnset] = Screen('Flip', win, interferenceFeedbackOnset_time);
                    
                    testing_onset_time = interferenceFeedbackOnset + postInterferenceInterval - ifi / 2;

  elseif strcmp(interferenceCommands{trial}, 'Right Interference')


                    interference_onset_time = preInterferenceRetentionOnset + preInterferenceInterval - ifi / 2;
                
                    
                    interferenceActual(trial) = "Different Interference";
      
                    % % Generate 9 numbers according to the described logic
                    % 
                    % Start by randomly picking a number between 1 and 360
                    first_number = randi([1, 360]);

                    % Initialize the array to store the numbers
                    numbers = zeros(1, 9);
                    numbers(1) = first_number;

                    % Generate the sequence
                    for i = 2:9
                        next_number = numbers(i-1) + 40; % Changed difference to 40      
                        % If the number exceeds 360, subtract 360
                        if next_number > 360
                            next_number = next_number - 360; 
                        end
                        numbers(i) = next_number;
                    end

                    % Randomize the order of selected numbers
                    % Divide numbers into three groups
                    numbers_group1 = numbers(numbers >= 1 & numbers <= 120);
                    numbers_group2 = numbers(numbers >= 121 & numbers <= 240);
                    numbers_group3 = numbers(numbers >= 241 & numbers <= 360);

                    % Recreate numbers by selecting randomly from groups and randomizing group order
                    numbers = [];
                    num_groups = {numbers_group1, numbers_group2, numbers_group3};
                    random_group_order = randperm(3);
                    while any(cellfun(@(x) ~isempty(x), num_groups))
                        for i = random_group_order
                            if ~isempty(num_groups{i})
                                % Select a random number from the current group
                                idx = randi(length(num_groups{i}));
                                numbers = [numbers, num_groups{i}(idx)];
                                % Remove the selected number from the group
                                num_groups{i}(idx) = [];
                            end
                        end
                        % Re-randomize the group order
                        random_group_order = randperm(3);
                    end


                    numbersWithRepeat = [];
                    numbersWithRepeat = numbers;

                    % Randomly select an index to remove
                    removeIndex = randi(length(numbersWithRepeat));

                    % Store the number at the removed index
                    removedNumber = numbersWithRepeat(removeIndex);

                    % Remove the number from the list
                    numbersWithRepeat(removeIndex) = [];

                    % Randomly select an index from the remaining list to copy
                    copyIndex = randi(length(numbersWithRepeat));

                    % Insert the copied number into the position of the removed number
                    numbersWithRepeat = [numbersWithRepeat(1:removeIndex-1), numbersWithRepeat(copyIndex), numbersWithRepeat(removeIndex:end)];
   

                    % Combine them into one matrix, each as a separate row
                    interferenceNumbersMatrix = [numbers; numbersWithRepeat]; 

                    randomInterferenceRowIndex = 2;  

                    num_str = strjoin(string(numbers), ', ');

                    interferenceRGBs(trial) = num_str;
           
                    currentInterferenceRow = interferenceNumbersMatrix(randomInterferenceRowIndex, :);

                    % Assume selected_numbers is a vector of 9 unique numbers
                    numColors = length(currentInterferenceRow);  % Number of unique colors to apply

                    % Initialize counter for color index
                    colorIndex = 1;
                    
                    % Draw the grid of squares
                    for row = 0:gridSize-1
                        for col = 0:gridSize-1
                            % Calculate position for each square
                            posX = gridPosX + col * (squareSize + padding);  
                            posY = gridPosY + row * (squareSize + padding);
                            destRect = [posX, posY, posX + squareSize, posY + squareSize];
                    
                            % Get the current interference color degree from the list
                            interferenceColourDegree = currentInterferenceRow(colorIndex);
                    
                            % Convert the image to LAB only once to speed up color rotations
                            savedLab = colorspace('rgb->lab', interferenceSquareLoad);
                    
                            % Fetch the color
                            newRgb = RotateImage(savedLab, interferenceColourDegree);
                    
                            % Apply alpha transparency
                            newRgb(:,:,4) = alphaInterference;
                    
                            % Project the color onto the target     
                            interferenceTexture = Screen('MakeTexture', win, newRgb); 
                    
                            % Draw the texture
                            Screen('DrawTexture', win, interferenceTexture, [], destRect);
                    
                            % Increment the color index and loop back to 1 if we exceed the color list
                            colorIndex = mod(colorIndex, numColors) + 1;
                        end
                    end

                    Screen('DrawText', win, '"A" -> same      "D" -> different', centerX-200, centerY-300, [0 0 0]);
                    
                    % % Flip the screen to display the grid
                    [~, interferenceOnset] = Screen('Flip', win, interference_onset_time);
                    
                    % Wait for user input with a time limit
                    keyPressed = false; % Initialize keyPressed as false
                    selectedSide = NaN;   % Default value if space is not pressed
                    timeLimit = 5;      % Set the time limit (in seconds)
                    startTime = GetSecs; % Record the start time
                    
                    while ~keyPressed
                        % Check if the time limit has been exceeded
                        if GetSecs - startTime > timeLimit
                            keyPressed = true; % Exit the loop
                            selectedSide = NaN; % Assign NaN to indicate no response
                            break;
                        end
                    
                        % Check for key presses
                        [keyIsDown, ~, keyCode] = KbCheck;
                        if keyIsDown
                            if keyCode(KbName('a')) % If 'A' is pressed
                                keyPressed = true;
                                selectedSide = 2;
                            elseif keyCode(KbName('d')) % If 'D' is pressed
                                keyPressed = true;
                                selectedSide = 1;
                            else
                                % Wait for key release if it's not A or D
                                KbReleaseWait;
                            end
                        end

                        WaitSecs(0.01);
                    end

                    currentInterferenceDecision = GetSecs; 

                    currentInterferenceRT = interferenceOnset - currentInterferenceDecision;

                    interferenceRT(trial) = currentInterferenceRT;
                

                    % Check if a response was made before proceeding with correctness evaluation
                    if isnan(selectedSide)
                        % Display "Time Up!" message
                        Screen('FillRect', win, currentBackground, [0 0 screenWidth screenHeight]);
                        DrawFormattedText(win, 'Please respond quicker!', 'center', 'center', [255, 0, 0]);
                        interferenceSelection(trial) = "No Response";
                    else
                        if selectedSide == randomInterferenceRowIndex
                            Screen('FillRect', win, currentBackground, [0 0 screenWidth screenHeight]);
                            DrawFormattedText(win, 'Correct Answer!', 'center', 'center', [0, 255, 0]);
                            interferenceSelection(trial) = "Correct";
                        else
                            Screen('FillRect', win, currentBackground, [0 0 screenWidth screenHeight]);
                            DrawFormattedText(win, 'Wrong Answer!', 'center', 'center', [255, 0, 0]);
                            interferenceSelection(trial) = "Wrong";
                        end
                    end
                    
                    interferenceFeedbackOnset_time = interferenceOnset + interferenceFeedbackDuration - ifi / 2;

                    [~, interferenceFeedbackOnset] = Screen('Flip', win, interferenceFeedbackOnset_time);
                    
                    testing_onset_time = interferenceFeedbackOnset + postInterferenceInterval - ifi / 2;
        
  elseif strcmp(interferenceCommands{trial}, 'No Interference')

        testing_onset_time = preInterferenceRetentionOnset + retentionDuration - ifi / 2;

        interferenceActual(trial) = "No Interference Presented";
        interferenceSelection(trial) = "No Interference Selected";
  
  elseif isempty(interferenceCommands{trial}) 

        testing_onset_time = preInterferenceRetentionOnset + retentionDuration - ifi / 2;
    
  end


%%%%%%%%%%%%%Interference Phase%%%%%%%%%%%%%
    
rounderE=GetSecs;
    
    
%%%%%%%%%%%%%Test Phase%%%%%%%%%%%%%%%%%%%
   
   
    Screen('FillRect' , win, currentBackground, [0 0 screenWidth screenHeight]);
    
    timee=rounderE-rounderS;
    disp(timee);
    disp(miniBlockEnd);
    


    temp=Shuffle(0:45:315);
    randomAddition=temp(1);
    
    startTimeOnset = GetSecs;
    startTimeMove = GetSecs;


    %First, randomly decide which of the presented objects will be
            %tested.

    randomTestObjectIndex = randi([1, 2]);
    randomTestObjectUnprocessed = {};
    toBeTestedColorDegree = 0;

    randomTestObjectUnprocessed = currentPair{randomTestObjectIndex};
    toBeTestedColorDegree = currentPairColors{randomTestObjectIndex};

    testedImage(trial) = randomTestObjectUnprocessed;


    % Show in grayscale:
    [originalImg, map, alpha] = imread(fullfile('TestObjectsTransparent',randomTestObjectUnprocessed)); 
    % originalImg = imresize(originalImg, [stim.size stim.size]); 
    imgGray = repmat(mean(originalImg,3), [1 1 3]);
    imgGray(:,:,4)=alpha;

    curTexture = Screen('MakeTexture', win, imgGray);

  
    
    Screen('DrawTexture', win, curTexture, [], stimRect);
    
    % Show color report circle:
    
    Screen('FrameOval', win, [0 0 0], colorWheel.rect);
    
    
    [~, testingOnset] = Screen('Flip', win, testing_onset_time);
    

    % Center mouse
    SetMouse(centerX,centerY,win);
      
    % Convert the image to LAB only once to speed up color rotations:
    savedLab = colorspace('rgb->lab', originalImg);
    
    % Wait until the mouse moves:
    [curX,curY] = GetMouse(win);
    while (curX == centerX && curY == centerY)
      [curX,curY] = GetMouse(win);
    end

    
    endTimeMove = GetSecs;
      
    % Show object in correct color for current angle and wait for click:
    buttons = [];

   
    

    while ~any(buttons)  
      
      
      [curX,curY, buttons] = GetMouse(win);
      curAngle = GetPolarCoordinates(curX,curY,centerX,centerY);
      [dotX1, dotY1] = polar2xy(curAngle,colorWheel.radius-5,centerX,centerY);
      [dotX2, dotY2] = polar2xy(curAngle,colorWheel.radius+20,centerX,centerY);
      
   
               
      if (curAngle ~= toBeTestedColorDegree) && round(curAngle) ~= 0 
        newRgb = RotateImage(savedLab, round(curAngle)+randomAddition);
        newRgb(:,:,4)=alpha;
        Screen('Close', curTexture);
        curTexture = Screen('MakeTexture', win, newRgb);
      end
      
      % Show stimulus:
      
      Screen('FillRect' , win, currentBackground, [0 0 screenWidth screenHeight]);
      
      % Draw frame and dot
      Screen('FrameOval', win, [0,0,0], colorWheel.rect);
      Screen('DrawLine', win, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);

          % Draw the rectangle using the hardcoded size
      % Screen('FillRect', win, [128, 128, 128], hardcodedRect);
      Screen('DrawTexture', win, curTexture, [], stimRect);
      
      
      Screen('Flip', win);

      
      
      % Allow user to quit on each frame:
      [~,~,keys]=KbCheck;
      if keys(KbName('q')) && keys(KbName('7'))
        sca; error('User quit');
      end
    
    
    end
    
    
    Screen('Close', curTexture);
    
    
    % Wait for release of mouse button
    while any(buttons), [~,~,buttons] = GetMouse(win); end

    
    endTimeOnset = GetSecs;
    
    timeElapsedOnset = abs(endTimeOnset - startTimeOnset);
    timeElapsedMove = abs(endTimeMove - startTimeMove);

    onsetTime(trial) = timeElapsedOnset;
    moveTime(trial) = timeElapsedMove;
    RTActual(trial) = (onsetTime(trial)-moveTime(trial));
    
    
    %Correct for circular space degrees
    angular_disparity=(toBeTestedColorDegree-(curAngle+randomAddition));
    if angular_disparity>180
        angular_disparity=angular_disparity-360;
    elseif angular_disparity<-180
        angular_disparity=angular_disparity+360;
    end
    
    angularDisparity(trial)=angular_disparity;
    disparityRates = [disparityRates, abs(angular_disparity)];

    % Screen('FillRect' , win, [128 128 128], [0 0 screenWidth screenHeight]);
    Screen('DrawText', win, ['Angular Disparity Rate: ' num2str(round(abs(angular_disparity)))], centerX-125, centerY-525, [250 0 0]); 
    if abs(angular_disparity) <= 5
        Screen('DrawText', win, 'Excellent!', centerX-30, centerY-475, [250 0 0]); 
    elseif abs(angular_disparity) > 5 && abs(angular_disparity) <= 15
        Screen('DrawText', win, 'Great!', centerX-45, centerY-475, [250 0 0]); 
    elseif abs(angular_disparity) > 15 && abs(angular_disparity) <= 25
        Screen('DrawText', win, 'Nice!', centerX-30, centerY-475, [250 0 0]);
    elseif abs(angular_disparity) > 25 && abs(angular_disparity) <= 35
        Screen('DrawText', win, 'Not Bad', centerX-45, centerY-475, [250 0 0]);
    elseif abs(angular_disparity) > 35
        Screen('DrawText', win, 'Could be better', centerX-80, centerY-475, [250 0 0]);
    end
    
    Screen('Flip', win);
    WaitSecs(0.25);
    
    % Append to `usedAngles`
    usedAngels(:, end + 1) = {currentTargetFilename; currentColourDegree};
    usedDistAngels(:, end + 1) = {currentDistractorFilename; currentDistractorDegree};
    previousColourDegree=currentColourDegree;
    previousDistractorDegree=currentDistractorDegree;
    
    if trial>=1
        miniBlockEnd=miniBlockEnd+1;
    end
    
    disp(trial);

    dataMatrix = [participantNumber1, trialNumber, resultColumnVector, conditionUsed, blocks, targetTestPresented, targetColorRGB, distractorTestPresented, distractorColorRGB, testedImage, contextChange, interferenceActual, interferenceSelection, angularDisparity, onsetTime, moveTime, RTActual, interferenceRT, interferenceRGBs, breakTime];
    

end  


%%%%%%%%%%%%%Test Phase%%%%%%%%%%%%%%%%


%%%%%%%%%%Actual Experiment Ends%%%%%%%%%

 % Specify the file name
fileName = ['output_data', num2str(participantNumber), '.xlsx'];

% Write the matrix to a CSV file
writematrix(dataMatrix, fileName);

fileName2 = ['output_data', num2str(participantNumber), '.mat'];
% Save the matrix in a .mat file
save(fileName2, 'dataMatrix');


disp('Data saved successfully.');



Screen('Close');  % closes all textures created so far




%%%%%%%%SURPRISE MEMORY TASK BEGINS%%%%%%%%%%

leadInImage= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\leadintosurpriseENG.png');
leadInImageTexture = Screen('MakeTexture', win, leadInImage);
Screen('DrawTexture', win, leadInImageTexture);


% Flip the screen to show the text
Screen('Flip', win);

% Wait for a key press to continue
KbWait;

WaitSecs(2)


% Flip the screen to show the text
Screen('Flip', win);

instructionsImage= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\instructionsSurpriseENG.png');
instructionsImageTexture = Screen('MakeTexture', win, instructionsImage);
Screen('DrawTexture', win, instructionsImageTexture);


% Flip the screen to show the text
Screen('Flip', win);

% Wait for a key press to continue
KbWait;

WaitSecs(2)

Screen('Flip', win);

usedTargets = unique(targetTestPresented, 'stable');
usedDistractors = unique(distractorTestPresented, 'stable');


merged_list = horzcat(usedTargets, usedDistractors);

num_rows = 0;
num_rows = size(merged_list, 1);
randomSurpriseSelections = randi([1, 2], num_rows, 1);

surpriseTargetSelections = strings(120,1);


for surpriseSelection = 1:num_rows
    surpriseTargetSelections(surpriseSelection) = merged_list(surpriseSelection, randomSurpriseSelections(surpriseSelection)); 
end


uniqueTargets = unique(surpriseTargetSelections, 'stable');
non_empty_idx = ~strcmp(uniqueTargets, "");
filteredUniqueTargets = uniqueTargets(non_empty_idx);

allTargetsCell = {listOfTargets.name};
allTargetsString = string(allTargetsCell');
availableTargets = setdiff(allTargetsString, [usedTargets; usedDistractors]);

filteredUniqueTargets = string(filteredUniqueTargets);

for surpriseTrial = 1:(numel(filteredUniqueTargets))
    
    participantNumber2(surpriseTrial) = participantNumber;
    trialNumber2(surpriseTrial) = surpriseTrial;
    

    randomSurpriseIndex = randi(numel(filteredUniqueTargets));
    randomSurpriseTargetFilename = filteredUniqueTargets{randomSurpriseIndex};
    remove_UsedTarget = string(randomSurpriseTargetFilename);
    targetPresented2(surpriseTrial) = randomSurpriseTargetFilename;
    
    filteredUniqueTargets = setdiff(filteredUniqueTargets, remove_UsedTarget, 'stable');
    
    
    randomSurpriseDistractorIndex = randi(length(availableTargets));
    randomSurpriseDistractorFilename = availableTargets(randomSurpriseDistractorIndex); 
    distractor2Presented(surpriseTrial) = randomSurpriseDistractorFilename;

    availableTargets = setdiff(availableTargets, randomSurpriseDistractorFilename, 'stable');
    
    
    
    [image1, map, alphaSurpriseTarget] = imread(randomSurpriseTargetFilename);
    image1Gray = repmat(mean(image1,3), [1 1 3]);
    image1Gray(:,:,4)=alphaSurpriseTarget;
    
    [image2, map, alphaSurpriseDist] = imread(randomSurpriseDistractorFilename);
    image2Gray = repmat(mean(image2,3), [1 1 3]);
    image2Gray(:,:,4)=alphaSurpriseDist;
  

    
    texture1 = Screen('MakeTexture', win, image1Gray);
    texture2 = Screen('MakeTexture', win, image2Gray);
    
    
    imageSize = size(image1);
    stimRect1 = [0, 0, imageSize(2), imageSize(1)];
    
    imagePosition1=[centerX-640, centerY]; 
    imagePosition2=[centerX+640, centerY];
    
    textureList={texture1,texture2};
    shuffledIndices = randperm(2);
    shuffledTextureList = textureList(shuffledIndices);
    
    Screen('FillRect', win, [255,255,255]);
    Screen('DrawTexture', win, shuffledTextureList{1}, [], CenterRectOnPoint(stimRect1, imagePosition1(1), imagePosition1(2))); %%left image
    Screen('DrawTexture', win, shuffledTextureList{2}, [], CenterRectOnPoint(stimRect1, imagePosition2(1), imagePosition2(2))); %%right image

    
    textureList={};

    if surpriseTrial ~= 1
        Screen('Flip', win);
    end
    
    
    KbName('UnifyKeyNames');
    leftArrowKey = KbName('LeftArrow');
    rightArrowKey = KbName('RightArrow');
    

    if surpriseTrial == 1
        if texture1 == shuffledTextureList{1} 
            Screen('DrawText', win, ['Since the image you have seen before is on the left, you need to press the left arrow key.'], centerX-650, centerY-400, [250 0 0]);
            Screen('DrawText', win, ['Please indicate the image colour after keypress.'], centerX-300, centerY-300, [250 0 0]);
            Screen('Flip', win);
        end
        
        if texture1 == shuffledTextureList{2}
            Screen('DrawText', win, ['Since the image you have seen before is on the right, you need to press the right arrow key.'] , centerX-650, centerY-400, [250 0 0]); 
            Screen('DrawText', win, ['Please indicate the image colour after keypress.'], centerX-300, centerY-300, [250 0 0]);
            Screen('Flip', win);
        end
    end

    targetIsLeft = false;
    targetIsRight = false;

    true;
    
    while true
        [keyIsDown, ~, keyCode] = KbCheck;
            
       if keyIsDown
        if ~keyCode(leftArrowKey) && ~keyCode(rightArrowKey)
            % If neither right nor left is keyed in, do nothing
            KbReleaseWait;
        elseif keyCode(leftArrowKey) && texture1 == shuffledTextureList{1}
            % If left is keyed and target is on the left, correct choice
            trueOrFalse(surpriseTrial) = 1;
            targetIsLeft = true;
            targetIsRight = false;
            break;
        elseif keyCode(rightArrowKey) && texture1 == shuffledTextureList{2}
            % If right is keyed and target is on the right, correct choice
            trueOrFalse(surpriseTrial) = 1;
            targetIsRight = true;
            targetIsLeft = false;
            break;
        else
            if texture1 == shuffledTextureList{1}
                targetIsLeft = true;
                targetIsRight = false;
            elseif texture1 == shuffledTextureList{2}
                targetIsRight = true;
                targetIsLeft = false;
            end         
            % Incorrect choice
            trueOrFalse(surpriseTrial) = 2;
            warningImage = imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\yanlisgorselENG.png');
            warningImageTexture = Screen('MakeTexture', win, warningImage);
            Screen('DrawTexture', win, warningImageTexture);
            Screen('Flip', win);
            WaitSecs(2);
            break;
        end
       end
    end
        
    
    
    temp=Shuffle(0:45:315);
    randomAddition=temp(1);

    startTimeOnsetSurprise = GetSecs;
    startTimeMoveSurprise = GetSecs;
    
    indexDF = find(strcmp(randomSurpriseTargetFilename, usedAngels(1, :)));

    if ~isempty(indexDF)
        currentColourDegree = usedAngels{2, indexDF};
    else
        indexDF = find(strcmp(randomSurpriseTargetFilename, usedDistAngels(1, :)));
        if ~isempty(indexDF)
            currentColourDegree = usedDistAngels{2, indexDF};
        end
    end



    if targetIsRight
        Screen('FillRect', win, [255,255,255]);
        Screen('DrawTexture', win, shuffledTextureList{2}, [], stimRect);
        savedLab = colorspace('rgb->lab', image1);
    elseif targetIsLeft
        Screen('FillRect', win, [255,255,255]);
        Screen('DrawTexture', win, shuffledTextureList{1}, [], stimRect);
        savedLab = colorspace('rgb->lab', image1);
    end
    
    % Show color report circle:
    
    Screen('FrameOval', win, [0,0,0], colorWheel.rect);
    Screen('Flip', win);
      
    

    % Center mouse
    SetMouse(centerX,centerY,win);
      
    % Convert the image to LAB only once to speed up color rotations:
    
    
   
      
  


    

    
    % Wait until the mouse moves:
    [curX,curY] = GetMouse(win);
    while (curX == centerX && curY == centerY)
      [curX,curY] = GetMouse(win);
    end


    endTimeMoveSurprise = GetSecs;
      
    % Show object in correct color for current angle and wait for click:
    buttons = [];
    while ~any(buttons)  

      % Show stimulus:
      Screen('FillRect', win, [255,255,255]);
        
      [curX,curY, buttons] = GetMouse(win);
      curAngle = GetPolarCoordinates(curX,curY,centerX,centerY);
      [dotX1, dotY1] = polar2xy(curAngle,colorWheel.radius-5,centerX,centerY);
      [dotX2, dotY2] = polar2xy(curAngle,colorWheel.radius+20,centerX,centerY);
      
      % Draw frame and dot
      Screen('FrameOval', win, [0,0,0], colorWheel.rect);
      Screen('DrawLine', win, [0 0 0], dotX1, dotY1, dotX2, dotY2, 4);

                   
      if (curAngle ~= currentColourDegree) && round(curAngle) ~= 0 
        
        if targetIsRight
            newRgb = RotateImage(savedLab, round(curAngle)+randomAddition);
            newRgb(:,:,4)=alphaSurpriseTarget;
            Screen('Close', shuffledTextureList{2});
            shuffledTextureList{2} = Screen('MakeTexture', win, newRgb);
        elseif targetIsLeft
            newRgb = RotateImage(savedLab, round(curAngle)+randomAddition);
            newRgb(:,:,4)=alphaSurpriseTarget;
            Screen('Close', shuffledTextureList{1});
            shuffledTextureList{1} = Screen('MakeTexture', win, newRgb);
        end
      end
      
     

      if targetIsRight
        Screen('DrawTexture', win, shuffledTextureList{2}, [], stimRect);
      elseif targetIsLeft
        Screen('DrawTexture', win, shuffledTextureList{1}, [], stimRect);
      end
        Screen('Flip', win);
      
      % Allow user to quit on each frame:
      [~,~,keys]=KbCheck;
      if keys(KbName('q')) && keys(KbName('7'))
        sca; error('User quit');
      end
    end
    % Screen('Close', image1GrayTexture);
    
    % Wait for release of mouse button
    while any(buttons), [~,~,buttons] = GetMouse(win); end


    endTimeOnsetSurprise = GetSecs;
    
    timeElapsedOnsetSurprise = abs(endTimeOnsetSurprise - startTimeOnsetSurprise);
    timeElapsedMoveSurprise = abs(endTimeMoveSurprise - startTimeMoveSurprise);

    onsetTimeSurprise(surpriseTrial) = timeElapsedOnsetSurprise;
    moveTimeSurprise(surpriseTrial) = timeElapsedMoveSurprise;
    RTActualSurprise(surpriseTrial) = (onsetTimeSurprise(surpriseTrial)-moveTimeSurprise(surpriseTrial));
    
    
    %Correct for circular space degrees
    angular_disparity=(currentColourDegree-(curAngle+randomAddition));
    disp(currentColourDegree);
    if angular_disparity>180
        angular_disparity=angular_disparity-360;
    elseif angular_disparity<-180
        angular_disparity=angular_disparity+360;
    end
    
    
    angularDisparity2(surpriseTrial)=angular_disparity;

    Screen('FillRect', win, [255,255,255]);
    Screen('DrawText', win, ['Angular Disparity Rate: ' num2str(round(abs(angular_disparity)))], centerX-125, centerY-525, [250 0 0]); 
    if abs(angular_disparity) <= 5
        Screen('DrawText', win, 'Excellent!', centerX-30, centerY-475, [250 0 0]); 
    elseif abs(angular_disparity) > 5 && abs(angular_disparity) <= 15
        Screen('DrawText', win, 'Great!', centerX-45, centerY-475, [250 0 0]); 
    elseif abs(angular_disparity) > 15 && abs(angular_disparity) <= 25
        Screen('DrawText', win, 'Nice!', centerX-30, centerY-475, [250 0 0]);
    elseif abs(angular_disparity) > 25 && abs(angular_disparity) <= 35
        Screen('DrawText', win, 'Not Bad', centerX-45, centerY-475, [250 0 0]);
    elseif abs(angular_disparity) > 35
        Screen('DrawText', win, 'Could be better', centerX-80, centerY-475, [250 0 0]);
    end

    Screen('Flip', win);
    WaitSecs(0.25); 

    


    if surpriseTrial==1
        endOfSurprisePractice= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\endofsurprisepracticeENG.png');
        endOfSurprisePracticeTexture = Screen('MakeTexture', win, endOfSurprisePractice);
        Screen('DrawTexture', win, endOfSurprisePracticeTexture);


        % Flip the screen to show the text
        Screen('Flip', win);

        % Wait for a key press to continue
        KbWait;

        WaitSecs(2)
    end
    
    dataMatrix2 = [participantNumber2, trialNumber2, trueOrFalse, angularDisparity2, targetPresented2, distractor2Presented, onsetTimeSurprise, moveTimeSurprise, RTActualSurprise];
    
    
    
end
    

    % Specify the file name
    fileName3 = ['output_dataSurprise', num2str(participantNumber), '.xlsx'];
    
    % Write the matrix to a CSV file
    writematrix(dataMatrix2, fileName3);

    fileName4 = ['output_dataSurprise', num2str(participantNumber), '.mat'];

    % Save the matrix in a .mat file
    save(fileName4, 'dataMatrix2');


%%%%%%%%SURPRISE MEMORY TASK ENDS%%%%%%%%%%%

disp('Surprise data saved successfully.');


endOfExperimentImage= imread('C:\Users\eeglab1\Desktop\Ali Yılmaztekin\instruction images experiment 3\endofexperimentENG.png');
endOfExperimentImageTexture = Screen('MakeTexture', win, endOfExperimentImage);
Screen('DrawTexture', win, endOfExperimentImageTexture);


% Flip the screen to show the text
Screen('Flip', win);

% Wait for a key press to continue
KbWait;


% Clean up
  Screen('CloseAll');




  
  
  
  
  
%%%%%%%%%%%%FUNTIONS USED%%%%%%%%%%%%%%



% ----------------------------------------------------------
function newRgb = RotateImage(lab, r)
    x = lab(:,:,2);
    y = lab(:,:,3);
    v = [x(:)'; y(:)'];
    vo = [cosd(r) -sind(r); sind(r) cosd(r)] * v;
    lab(:,:,2) = reshape(vo(1,:), size(lab,1), size(lab,2));
    lab(:,:,3) = reshape(vo(2,:), size(lab,1), size(lab,2));
    newRgb = (colorspace('lab->rgb', lab) .* 255);
end
% ----------------------------------------------------------
function [angle, radius] = GetPolarCoordinates(h,v,centerH,centerV)
  % get polar coordinates
  hdist   = h-centerH;
  vdist   = v-centerV;
  radius     = sqrt(hdist.*hdist + vdist.*vdist)+eps;
  
  % determine angle using cosine (hyp will never be zero)
  angle = acos(hdist./radius)./pi*180;
  
  % correct angle depending on quadrant
  angle(hdist == 0 & vdist > 0) = 90;
  angle(hdist == 0 & vdist < 0) = 270;
  angle(vdist == 0 & hdist > 0) = 0;
  angle(vdist == 0 & hdist < 0) = 180;
  angle(hdist < 0 & vdist < 0)=360-angle(hdist < 0 & vdist < 0);
  angle(hdist > 0 & vdist < 0)=360-angle(hdist > 0 & vdist < 0);
end

% ----------------------------------------------------------
function [x, y] = polar2xy(angle,radius,centerH,centerV)  
  x = round(centerH + radius.*cosd(angle));
  y = round(centerV + radius.*sind(angle));
end

%%%%%%%%%%%%FUNTIONS USED%%%%%%%%%%%%%%
