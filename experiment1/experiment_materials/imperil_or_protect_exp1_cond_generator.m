%Read Target and Task Repetition From Condition File
T = 'all_cond.csv';
M = readmatrix(T);
targetRepetitioncsv= readmatrix(T, Range="U2:U1441");
taskRepetitioncsv= readmatrix(T, Range="T2:T1441");



%Key Values
nTrial=1440;
critical_trial=(nTrial/6)*2;
nCondition = 4; % x 2 target rep; x 2 context rep (old; new)
critical_trial_pCondition = critical_trial/nCondition;


%Initiliaze Interference Type Matrix
interference_type = repmat ([1 2],[1,60]); % 1: interference; 2: no interference

%Initialize Context Change Matrix
context_change_type = [repmat(1,[1,60])  repmat(2,[1,60])]; % 1: within, 2: across 




% Create Shuffle Key
shuffle_index = Shuffle(1:critical_trial_pCondition);

% Shuffle Cond 1
context_change_type_shuffle_cond1 = context_change_type(shuffle_index);
interference_type_shuffle_cond1 = interference_type(shuffle_index);

% Shuffle Cond 2
context_change_type_shuffle_cond2 = context_change_type(shuffle_index);
interference_type_shuffle_cond2 = interference_type(shuffle_index);

% Shuffle Cond 3
context_change_type_shuffle_cond3 = context_change_type(shuffle_index);
interference_type_shuffle_cond3 = interference_type(shuffle_index);

% Shuffle Cond 4
context_change_type_shuffle_cond4 = context_change_type(shuffle_index);
interference_type_shuffle_cond4 = interference_type(shuffle_index);



%Initialize Context Type Matrix
context_change = nan(1,nTrial);

%Re-Initialize Interference Type Matrix
interference_type = nan(1, nTrial);




% Assign 1s and 2s

c_cond1 = 0;  c_cond2 = 0; c_cond3 = 0; c_cond4 = 0; 
for iTrial = 1:nTrial
    if targetRepetitioncsv(iTrial) == 1 && taskRepetitioncsv(iTrial) == 1
        c_cond1 = c_cond1 + 1;
        context_change(iTrial) = context_change_type_shuffle_cond1(c_cond1);
        interference_type(iTrial) = interference_type_shuffle_cond1(c_cond1);
    elseif targetRepetitioncsv(iTrial) == 1 && taskRepetitioncsv(iTrial) > 1 
        c_cond2 = c_cond2 + 1;
        interference_type(iTrial) = interference_type_shuffle_cond2(c_cond2);
    elseif targetRepetitioncsv(iTrial) == 5 && taskRepetitioncsv(iTrial) ==1
        c_cond3 = c_cond3 + 1;
        context_change(iTrial) = context_change_type_shuffle_cond3(c_cond3);
        interference_type(iTrial) = interference_type_shuffle_cond3(c_cond3);
    elseif targetRepetitioncsv(iTrial) == 5 && taskRepetitioncsv(iTrial) > 1
        c_cond4 = c_cond4 + 1;
        interference_type(iTrial) = interference_type_shuffle_cond4(c_cond4);
    end
end


%Resultant Condition Configuration

final_condition= [context_change;interference_type];










%%%%% SAFETY CHECK SET 1 %%%%%

count_1_context5 = 0;
count_2_context5 = 0;
count_1_int5 = 0;
count_2_int5 = 0;
count_1_context1 = 0;
count_2_context1 = 0;
count_1_int1 = 0;
count_2_int1 = 0;

% Loop for Context 5 and Interference 5 counts
for a = 1:nTrial
    if mod(a, 6) == 5
        if context_change(a) == 1 && count_1_context5 < 60
            count_1_context5 = count_1_context5 + 1;
        elseif context_change(a) == 2 && count_2_context5 < 60
            count_2_context5 = count_2_context5 + 1;
        end
        
        if interference_type(a) == 1 && count_1_int5 < 60
            count_1_int5 = count_1_int5 + 1;
        elseif interference_type(a) == 2 && count_2_int5 < 60
            count_2_int5 = count_2_int5 + 1;
        end
    end
end

% Loop for Context 5 and Interference 5 counts

for a = 1:nTrial
    if mod(a, 6) == 1
        if context_change(a) == 1 && count_1_context1 < 60
            count_1_context1 = count_1_context1 + 1;
        elseif context_change(a) == 2 && count_2_context1 < 60
            count_2_context1 = count_2_context1 + 1;
        end
        
        if interference_type(a) == 1 && count_1_int1 < 60
            count_1_int1 = count_1_int1 + 1;
        elseif interference_type(a) == 2 && count_2_int1 < 60
            count_2_int1 = count_2_int1 + 1;
        end
    end
end


% Display the counts
disp(['Count 1 - Context 1: ' num2str(count_1_context1)]);
disp(['Count 2 - Context 1: ' num2str(count_2_context1)]);
disp(['Count 1 - Interference 1: ' num2str(count_1_int1)]);
disp(['Count 2 - Interference 1: ' num2str(count_2_int1)]);
disp(['Count 1 - Context 5: ' num2str(count_1_context5)]);
disp(['Count 2 - Context 5: ' num2str(count_2_context5)]);
disp(['Count 1 - Interference 5: ' num2str(count_1_int5)]);
disp(['Count 2 - Interference 5: ' num2str(count_2_int5)]);

intcon1 = 0;
intcon2 = 0;
concon1 = 0;
concon2 = 0;

for b = 1:nTrial
    if interference_type(b) == 1
        intcon1 = intcon1 + 1;
    end
    if interference_type(b) == 2
        intcon2 = intcon2 + 1;
    end
end

for c = 1:nTrial
    if context_change(c) == 1
        concon1 = concon1 + 1;
    end
    if context_change(c) == 2
        concon2 = concon2 + 1;
    end
end

controltri = 0;
inttri = 0;
controltri2 = 0;
inttri2 = 0;

for d = 1:nTrial
    if mod(d, 6) == 5
        if context_change(d) == 1 || context_change(d) == 2   %%%% ALL CONTEXT IN 5TH TRIAL
            controltri = controltri + 1;
        end
    end
end

for e = 1:nTrial
    if mod(e, 6) == 5
        if interference_type(e) == 1 || interference_type(e) == 2   %%% INT IN 5TH TRIAL
            inttri = inttri + 1;
        end
    end
end

for f = 1:nTrial
    if mod(f, 6) == 1
        if context_change(f) == 1 || context_change(f) == 2   %%%% CONTEXT IN 1ST
            controltri2 = controltri2 + 1;
        end
    end
end

for g = 1:nTrial
    if mod(g, 6) == 5
        if interference_type(g) == 1 || interference_type(g) == 2   %%% INT IN 1TH TRIAL
            inttri2 = inttri2 + 1;
        end
    end
end

disp(['interference 1 - trial 1-5: ' num2str(intcon1)]);
disp(['interference 2 - trial 1-5: ' num2str(intcon2)]);
disp(['context 1 - trial 1-5: ' num2str(concon1)]);
disp(['context 2 - trial 1-5: ' num2str(concon2)]);

%%%%% SAFETY CHECK SET 1 %%%%%

%%%%% SAFETY CHECK SET 2 %%%%%


% sum(targetRepetitioncsv==1 & taskRepetitioncsv==1 & context_change'==1)
% sum(targetRepetitioncsv==1 & taskRepetitioncsv==1 & context_change'==2)
% 
% 
% sum(targetRepetitioncsv==1 & taskRepetitioncsv==1 & interference_type'==1)
% sum(targetRepetitioncsv==1 & taskRepetitioncsv==1 & interference_type'==2)
% % % 
% 
% sum(targetRepetitioncsv==1 & taskRepetitioncsv==1 & interference_type'==1 & context_change'==1)
% sum(targetRepetitioncsv==1 & taskRepetitioncsv==1 & interference_type'==2 & context_change'==1)
% 
% 
% sum(targetRepetitioncsv==1 & taskRepetitioncsv==1 & interference_type'==1 & context_change'==2)
% sum(targetRepetitioncsv==1 & taskRepetitioncsv==1 & interference_type'==2 & context_change'==2)

% 
% %%% shift to fifth trial
% 
% sum(targetRepetitioncsv==5 & taskRepetitioncsv==1 & interference_type'==1 & context_change'==1)
% sum(targetRepetitioncsv==5 & taskRepetitioncsv==1 & interference_type'==2 & context_change'==1)
% 
% % 
% sum(targetRepetitioncsv==5 & taskRepetitioncsv==1 & interference_type'==1 & context_change'==2)
% sum(targetRepetitioncsv==5 & taskRepetitioncsv==1 & interference_type'==2 & context_change'==2)

% 
% %%% task repeat
% 
% sum(targetRepetitioncsv==5 & taskRepetitioncsv>1 & interference_type'==2) 
% sum(targetRepetitioncsv==5 & taskRepetitioncsv>1 & interference_type'==1)
% % % 
% % % 
% sum(targetRepetitioncsv==1 & taskRepetitioncsv>1 & interference_type'==1)
% sum(targetRepetitioncsv==1 & taskRepetitioncsv>1 & interference_type'==2)


%%%%% SAFETY CHECK SET 2 %%%%%