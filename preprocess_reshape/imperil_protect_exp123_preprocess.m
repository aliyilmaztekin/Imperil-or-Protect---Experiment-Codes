experiment_handle = 3; % Which experiment do you wanna pull data from?

analyze_main = false;
analyze_surprise = true;
analyze_sixlets = false;

% All analysis names are: 
% Main analyses (ACC, RT, MRT) DONE
% Surprise main analyses (ACC, RT, MRT) DONE
% Surprise recognition (exp 1, 2 and 3) DONE
% Main analysis interference accuracy (exp 2 and 3) DONE
% Sixlets (exp 1, 2 and 3, for ACC, RT and MRT) DONE
% Factor subtype analyses (exp 1 - Context Change levels, exp 2 and 3 -
% Interference subtypes). DONE

if analyze_main == true
    if experiment_handle == 1
    
            % Experiment 1 data location
            experiment1_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment1/';
            
            all_data_experiment1_main_anova = [];
    
            % Define latest participant number for experiment 1
            sample_size = 28;
        
            % Start iterating from participant 3 as the first two are faulty
            for current_subject = 3:sample_size
                %% Generate plug for data
                csv_plug = ['output_data' num2str(current_subject) '.csv'];
               
                current_data_dir = fullfile(experiment1_data_dir, csv_plug);
            
                % Check if both files exist
                if exist(current_data_dir, 'file') ~= 2
                    fprintf('Skipping participant %d: one or both files are missing.\n', current_subject);
                    continue;
                end
               
                current_csv_table = readtable(current_data_dir);
            
                %%Create number vectors to store data/ Empty the contents for the next participant
                id_number = [];
                trial_number = [];
                repetition = [];
                context_change_command = [];
                context_change_subtype = [];
                interference_command = [];
                accuracy_rates = [];
                RTs = [];
                waitRT = [];
                decision_time = [];
               
    
                %Define trial count for experiment 1
                trial_count = 1440;
                
                % Iterate over each line in the current data
                for current_trial = 1:trial_count
                    % Store data for the 1st trials only
                    if mod(current_trial,6) == 1
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        repetition(end+1, 1) = 1;
                        
                        if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                            context_change_command(end+1,1) = 0;
                            context_change_subtype(end+1,1) = 0;
                            interference_command(end+1,1) = 0;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_csv_table{current_trial, "Var4"} == 1 && current_csv_table{current_trial, "Var5"} == 2
                            context_change_command(end+1,1) = 1;
                            context_change_subtype(end+1,1) = 1;
                            interference_command(end+1,1) = 0;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 2
                            context_change_command(end+1,1) = 1;
                            context_change_subtype(end+1,1) = 2;
                            interference_command(end+1,1) = 0;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 1
                            context_change_command(end+1,1) = 0;
                            context_change_subtype(end+1,1) = 0;
                            interference_command(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};  
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_csv_table{current_trial, "Var4"} == 1 && current_csv_table{current_trial, "Var5"} == 1
                            context_change_command(end+1,1) = 1;
                            context_change_subtype(end+1,1) = 1;
                            interference_command(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 1
                            context_change_command(end+1,1) = 1;
                            context_change_subtype(end+1,1) = 2;
                            interference_command(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        end

                    elseif mod(current_trial,6) == 5
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        repetition(end + 1,1) = 5;
                        
                        if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                            context_change_command(end+1,1) = 0;
                            context_change_subtype(end+1,1) = 0;
                            interference_command(end+1,1) = 0;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_csv_table{current_trial, "Var4"} == 1 && current_csv_table{current_trial, "Var5"} == 2
                            context_change_command(end+1,1) = 1;
                            context_change_subtype(end+1,1) = 1;
                            interference_command(end+1,1) = 0;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 2
                            context_change_command(end+1,1) = 1;
                            context_change_subtype(end+1,1) = 2;
                            interference_command(end+1,1) = 0;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 1
                            context_change_command(end+1,1) = 0;
                            context_change_subtype(end+1,1) = 0;
                            interference_command(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};   
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_csv_table{current_trial, "Var4"} == 1 && current_csv_table{current_trial, "Var5"} == 1
                            context_change_command(end+1,1) = 1;
                            context_change_subtype(end+1,1) = 1;
                            interference_command(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 1
                            context_change_command(end+1,1) = 1;
                            context_change_subtype(end+1,1) = 2;
                            interference_command(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        end          
                    end            
                end
        
            
                %Combine all the number vectors to construct the participant's dataset
                data_per_participant = [id_number, trial_number, repetition, context_change_command, ...
                           interference_command, accuracy_rates, RTs, waitRT, decision_time, context_change_subtype];
            
                % Append the current dataset to the final matrix
                all_data_experiment1_main_anova = [all_data_experiment1_main_anova; data_per_participant];
               
                % Repeat the whole process for each participant
            end
        
        % When done with extracting data for experiment 1, save it as a mat file
        % for analysis

        save('/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment1_main_anova.mat', 'all_data_experiment1_main_anova');
    elseif experiment_handle == 2
    
                % Experiment 2 data location
                experiment2_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment2/';
            
                all_data_experiment2_main_anova = [];
    
                % Define latest participant number for experiment 2
                sample_size = 54;
                
                % Start iterating from participant 1
                for current_subject = 1:sample_size
                    
                    % Generate plug for data
                    csv_plug = ['output_data' num2str(current_subject) '.csv'];
    
                    current_data_dir = fullfile(experiment2_data_dir, csv_plug);
                
                    % Check if both files exist
                    if exist(current_data_dir, 'file') ~= 2
                        fprintf('Skipping participant %d: one or both files are missing.\n', current_subject);
                        continue;
                    end
                   
                    current_csv_table = readtable(current_data_dir);
        
                    %%Create number vectors to store data/ Empty the contents for the next participant
                    id_number = [];
                    trial_number = [];
                    repetition = [];
                    context_change_command = [];
                    interference_command = [];
                    interference_subtype = [];
                    accuracy_rates = [];
                    RTs = [];
                    waitRT = [];
                    decision_time = [];
                    interference_accuracy = [];
                    current_interference_accuracy = "";
                    % 
                    % Define how many trials experiment 2 had
                    trial_count = 720;
            
                    % Start looking through each trial
                    for current_trial = 1:trial_count
                        if mod(current_trial,6) == 1
                            
                            id_number(end+1,1) = current_subject;
                            trial_number(end+1,1) = current_trial;
                            repetition(end+1,1) = 1;
                            
                            if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                                context_change_command(end+1,1) = 0;
                                interference_command(end+1,1) = 0;
                                interference_subtype(end+1,1) = 0;
                                accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                                RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                                waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                                decision_time(end+1,1) = RTs(end) - waitRT(end); 
    
                                interference_accuracy(end+1,1) = NaN;
    
                            elseif current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 1
                                context_change_command(end+1,1) = 0;
                                interference_command(end+1,1) = 1;
                                
                                if (current_csv_table{current_trial, "Var13"} == "Left Interference" || current_csv_table{current_trial, "Var15"} == "Left Interference") 
                                    interference_subtype(end+1,1) = 1;
                                elseif (current_csv_table{current_trial, "Var13"} == "Right Interference" || current_csv_table{current_trial, "Var15"} == "Right Interference") 
                                    interference_subtype(end+1,1) = 2;
                                end
                               
                                accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                                RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                                waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                                decision_time(end+1,1) = RTs(end) - waitRT(end); 
    
                                current_interference_accuracy = current_csv_table{current_trial, "Var11"};

                                if current_interference_accuracy == "Left Selection" && (current_csv_table{current_trial, "Var13"} == "Left Interference" || current_csv_table{current_trial, "Var15"} == "Left Interference") 
                                    interference_accuracy(end+1,1) = 1;
                                elseif current_interference_accuracy == "Right Selection" && (current_csv_table{current_trial, "Var13"} == "Right Interference" || current_csv_table{current_trial, "Var15"} == "Right Interference") 
                                    interference_accuracy(end+1,1) = 1;
                                elseif current_csv_table{current_trial, "Var13"} == "No Interference" || current_csv_table{current_trial, "Var15"} == "No Interference"
                                    interference_accuracy(end+1,1) = NaN;
                                else
                                    interference_accuracy(end+1,1) = 0;
                                end

                            elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 2
                                context_change_command(end+1,1) = 1;
                                interference_command(end+1,1) = 0;
                                interference_subtype(end+1,1) = 0;
                                accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                                RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                                waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
    
                                decision_time(end+1,1) = RTs(end) - waitRT(end); 
                                interference_accuracy(end+1,1) = NaN;
    
                            elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 1
                                context_change_command(end+1,1) = 1;
                                interference_command(end+1,1) = 1;
    
                                if (current_csv_table{current_trial, "Var13"} == "Left Interference" || current_csv_table{current_trial, "Var15"} == "Left Interference") 
                                    interference_subtype(end+1,1) = 1;
                                elseif (current_csv_table{current_trial, "Var13"} == "Right Interference" || current_csv_table{current_trial, "Var15"} == "Right Interference") 
                                    interference_subtype(end+1,1) = 2;
                                end
    
                                accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                                RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                                waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};   
                                decision_time(end+1,1) = RTs(end) - waitRT(end); 
    
                                current_interference_accuracy = current_csv_table{current_trial, "Var11"};

                                if current_interference_accuracy == "Left Selection" && (current_csv_table{current_trial, "Var13"} == "Left Interference" || current_csv_table{current_trial, "Var15"} == "Left Interference") 
                                    interference_accuracy(end+1,1) = 1;
                                elseif current_interference_accuracy == "Right Selection" && (current_csv_table{current_trial, "Var13"} == "Right Interference" || current_csv_table{current_trial, "Var15"} == "Right Interference") 
                                    interference_accuracy(end+1,1) = 1;
                                elseif current_csv_table{current_trial, "Var13"} == "No Interference" || current_csv_table{current_trial, "Var15"} == "No Interference"
                                    interference_accuracy(end+1,1) = NaN;
                                else
                                    interference_accuracy(end+1,1) = 0;
                                end
                                
                            end
                        
                        elseif mod(current_trial,6) == 5
                            
                            id_number(end+1,1) = current_subject;
                            trial_number(end+1,1) = current_trial;
                            repetition(end+1,1) = 5;
                            
                            if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                                context_change_command(end+1,1) = 0;
                                interference_command(end+1,1) = 0;
                                interference_subtype(end+1,1) = 0;
                                accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                                RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                                waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                                decision_time(end+1,1) = RTs(end) - waitRT(end); 
    
                                interference_accuracy(end+1,1) = NaN;

                            elseif current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 1
                                context_change_command(end+1,1) = 0;
                                interference_command(end+1,1) = 1;
    
                                if (current_csv_table{current_trial, "Var13"} == "Left Interference" || current_csv_table{current_trial, "Var15"} == "Left Interference") 
                                    interference_subtype(end+1,1) = 1;
                                elseif (current_csv_table{current_trial, "Var13"} == "Right Interference" || current_csv_table{current_trial, "Var15"} == "Right Interference") 
                                    interference_subtype(end+1,1) = 2;
                                end
    
                                accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                                RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                                waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                                decision_time(end+1,1) = RTs(end) - waitRT(end); 
    
                                current_interference_accuracy = current_csv_table{current_trial, "Var11"};

                                if current_interference_accuracy == "Left Selection" && (current_csv_table{current_trial, "Var13"} == "Left Interference" || current_csv_table{current_trial, "Var15"} == "Left Interference") 
                                    interference_accuracy(end+1,1) = 1;
                                elseif current_interference_accuracy == "Right Selection" && (current_csv_table{current_trial, "Var13"} == "Right Interference" || current_csv_table{current_trial, "Var15"} == "Right Interference") 
                                    interference_accuracy(end+1,1) = 1;
                                elseif current_csv_table{current_trial, "Var13"} == "No Interference" || current_csv_table{current_trial, "Var15"} == "No Interference"
                                    interference_accuracy(end+1,1) = NaN;
                                else
                                    interference_accuracy(end+1,1) = 0;
                                end
    
                            elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 2
                                context_change_command(end+1,1) = 1;
                                interference_command(end+1,1) = 0;
                                interference_subtype(end+1,1) = 0;
                                accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                                RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                                waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};

                                decision_time(end+1,1) = RTs(end) - waitRT(end); 
                                interference_accuracy(end+1,1) = NaN;
    
                            elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 1
                                context_change_command(end+1,1) = 1;
                                interference_command(end+1,1) = 1;
    
                                if (current_csv_table{current_trial, "Var13"} == "Left Interference" || current_csv_table{current_trial, "Var15"} == "Left Interference") 
                                    interference_subtype(end+1,1) = 1;
                                elseif (current_csv_table{current_trial, "Var13"} == "Right Interference" || current_csv_table{current_trial, "Var15"} == "Right Interference") 
                                    interference_subtype(end+1,1) = 2;
                                end
    
                                accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                                RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                                waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};    
                                decision_time(end+1,1) = RTs(end) - waitRT(end); 
    
                                current_interference_accuracy = current_csv_table{current_trial, "Var11"};

                                if current_interference_accuracy == "Left Selection" && (current_csv_table{current_trial, "Var13"} == "Left Interference" || current_csv_table{current_trial, "Var15"} == "Left Interference") 
                                    interference_accuracy(end+1,1) = 1;
                                elseif current_interference_accuracy == "Right Selection" && (current_csv_table{current_trial, "Var13"} == "Right Interference" || current_csv_table{current_trial, "Var15"} == "Right Interference") 
                                    interference_accuracy(end+1,1) = 1;
                                elseif current_csv_table{current_trial, "Var13"} == "No Interference" || current_csv_table{current_trial, "Var15"} == "No Interference"
                                    interference_accuracy(end+1,1) = NaN;
                                else
                                    interference_accuracy(end+1,1) = 0;
                                end
                            end
                        end
                    end
    
                %Combine all the number vectors to construct the participant's dataset
                data_per_participant = [id_number, trial_number, repetition, context_change_command, ...
                           interference_command, interference_accuracy, accuracy_rates, RTs, waitRT, decision_time, interference_subtype];
            
                % Append the current dataset to the final matrix
                all_data_experiment2_main_anova = [all_data_experiment2_main_anova; data_per_participant];
        
                % Repeat the whole process for each participant
                end
        
        % When done with extracting data for experiment 2, save it as a mat file
        % for analysis
                save('/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment2_main_anova.mat', 'all_data_experiment2_main_anova');

                % Assume all_data_experiment2_main_anova columns are:
% 1:id_number, 2:trial_number, 3:repetition, 4:context_change_command, 
% 5:interference_command, 6:interference_accuracy, 7:accuracy_rates, 8:RTs, 9:waitRT, 10:decision_time, 11:interference_subtype

participants = unique(all_data_experiment2_main_anova(:,1));
nParticipants = length(participants);

% Preallocate wide dataset: 1 column for id, 24 for combinations * 3 DVs
wideData = nan(nParticipants, 1 + 24);

% Optional: create column names
DVs = {'accuracy','RT','waitRT'};
reps = [1 5];
contexts = [0 1];
interfs = [0 1];

colNames = cell(1, 25);
colNames{1} = 'id_number';
colIdx = 2;
for dv = 1:length(DVs)
    for r = 1:length(reps)
        for c = 1:length(contexts)
            for i = 1:length(interfs)
                colNames{colIdx} = sprintf('mean_%s_%d_%d_%d', DVs{dv}, reps(r), contexts(c), interfs(i));
                colIdx = colIdx + 1;
            end
        end
    end
end

% Loop over participants and fill in wide data
for p = 1:nParticipants
    pid = participants(p);
    wideData(p,1) = pid;

    % Subset long data for this participant
    subData = all_data_experiment2_main_anova(all_data_experiment2_main_anova(:,1) == pid, :);

    colIdx = 2;
    for dv = 1:length(DVs)
        switch DVs{dv}
            case 'accuracy'
                dvCol = 7;
            case 'RT'
                dvCol = 8;
            case 'waitRT'
                dvCol = 9;
        end

        for r = 1:length(reps)
            for c = 1:length(contexts)
                for i = 1:length(interfs)
                    % Average over all matching trials
                    matchIdx = subData(:,3)==reps(r) & subData(:,4)==contexts(c) & subData(:,5)==interfs(i);
                    wideData(p,colIdx) = mean(subData(matchIdx,dvCol), 'omitnan');
                    colIdx = colIdx + 1;
                end
            end
        end
    end
end

% Convert to table for easy export or further analysis
wideTable = array2table(wideData, 'VariableNames', colNames);

% desktopPath = fullfile(getenv('USERPROFILE'),'Desktop'); % For Windows
desktopPath = fullfile(getenv('HOME'),'Desktop'); % For macOS/Linux

filename = fullfile(desktopPath, 'wideData.csv');
writetable(wideTable, filename);


    
    elseif experiment_handle == 3
    
        % Experiment 3 data location
        experiment3_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment3_mat/';
    
        all_data_experiment3_main_anova = [];
    
        % Define latest participant number for experiment 3
        sample_size = 53;
        
        % Start iterating from participant 1
        for current_subject = 1:sample_size
    
            if current_subject == 8
                continue;
            end
    
            % Generate plug for data
            mat_plug = ['output_data' num2str(current_subject) '.mat'];
    
            current_data_dir = fullfile(experiment3_data_dir, mat_plug);
        
            % Check if both files exist
            if exist(current_data_dir, 'file') ~= 2
                fprintf('Skipping participant %d: one or both files are missing.\n', current_subject);
                continue;
            end
           
            current_mat_table = load(current_data_dir);
    
            
            %%Create number vectors to store data/ Empty the contents for the next participant
            id_number = [];
            trial_number = [];
            repetition = [];
            context_change_command = [];
            interference_command = [];
            interference_subtype = [];
            accuracy_rates = [];
            RTs = [];
            waitRT = [];
            decision_time = [];
            interference_accuracy = [];
            current_interference_accuracy = "";
    
    
            % Define how many trials experiment 3 had
            trial_count = 720;
    
            % Start looking through each trial
            for current_trial = 1:trial_count
                 if mod(current_trial,6) == 1
                        
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        repetition(end +1, 1) = 1;
        
                        if current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "No Interference Presented"
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 0;
                            interference_subtype(end+1,1) = 0;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);

                            interference_accuracy(end+1,1) = NaN;
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "Unique Interference"
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);

                            current_interference_accuracy = current_mat_table.dataMatrix(current_trial, 13);
                  
                            if current_interference_accuracy == "Correct"
                                interference_accuracy(end+1,1) = 1;
                            elseif current_interference_accuracy == "Wrong"
                                interference_accuracy(end+1,1) = 0;
                            elseif current_interference_accuracy == "" || current_interference_accuracy == "No Response"
                                interference_accuracy(end+1,1) = 0; % or 0, depending on how you want to treat it 
                            end 

                        elseif current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "Different Interference"
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 2;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);

                            current_interference_accuracy = current_mat_table.dataMatrix(current_trial, 13);
                  
                            if current_interference_accuracy == "Correct"
                                interference_accuracy(end+1,1) = 1;
                            elseif current_interference_accuracy == "Wrong"
                                interference_accuracy(end+1,1) = 0;
                            elseif current_interference_accuracy == "" || current_interference_accuracy == "No Response"
                                interference_accuracy(end+1,1) = 0; % or 0, depending on how you want to treat it
                           
                            end
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) == "No Interference Presented"
                            context_change_command(end+1,1) = 1;
                            interference_command(end+1,1) = 0;
                            interference_subtype(end+1,1) = 0;
                          
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);

                            interference_accuracy(end+1,1) = NaN;
                         
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) == "Unique Interference"
                            context_change_command(end+1,1) = 1;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 1;
                        
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
    
                            current_interference_accuracy = current_mat_table.dataMatrix(current_trial, 13);
                  
                            if current_interference_accuracy == "Correct"
                                interference_accuracy(end+1,1) = 1;
                            elseif current_interference_accuracy == "Wrong"
                                interference_accuracy(end+1,1) = 0;
                            elseif current_interference_accuracy == "" || current_interference_accuracy == "No Response"
                                interference_accuracy(end+1,1) = 0; % or 0, depending on how you want to treat it
                           
                            end
    
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) == "Different Interference"
                            context_change_command(end+1,1) = 1;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 2;
        
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
    
                            current_interference_accuracy = current_mat_table.dataMatrix(current_trial, 13);
                  
                            if current_interference_accuracy == "Correct"
                                interference_accuracy(end+1,1) = 1;
                            elseif current_interference_accuracy == "Wrong"
                                interference_accuracy(end+1,1) = 0;
                            elseif current_interference_accuracy == "" || current_interference_accuracy == "No Response"
                                interference_accuracy(end+1,1) = 0; % or 0, depending on how you want to treat it
                           
                            end
    
                        end
                    
                 elseif mod(current_trial,6) == 5
                        
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        repetition(end + 1,1) = 5;
                        
                        if current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "No Interference Presented"
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 0;
                            interference_subtype(end+1,1) = 0;
               
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                            
                            interference_accuracy(end+1,1) = NaN;

                        elseif current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "Unique Interference"
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                            
                            current_interference_accuracy = current_mat_table.dataMatrix(current_trial, 13);
                  
                            if current_interference_accuracy == "Correct"
                                interference_accuracy(end+1,1) = 1;
                            elseif current_interference_accuracy == "Wrong"
                                interference_accuracy(end+1,1) = 0;
                            elseif current_interference_accuracy == "" || current_interference_accuracy == "No Response"
                                interference_accuracy(end+1,1) = 0; % or 0, depending on how you want to treat it
                           
                            end

                        elseif current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "Different Interference"
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 2;
                            
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);

                            current_interference_accuracy = current_mat_table.dataMatrix(current_trial, 13);
                  
                            if current_interference_accuracy == "Correct"
                                interference_accuracy(end+1,1) = 1;
                            elseif current_interference_accuracy == "Wrong"
                                interference_accuracy(end+1,1) = 0;
                            elseif current_interference_accuracy == "" || current_interference_accuracy == "No Response"
                                interference_accuracy(end+1,1) = 0; % or 0, depending on how you want to treat it
                           
                            end

                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) == "No Interference Presented"
                            context_change_command(end+1,1) = 1;
                            interference_command(end+1,1) = 0;
                            interference_subtype(end+1,1) = 0;
                    
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                            
                            interference_accuracy(end+1,1) = NaN;

                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) == "Unique Interference"
                            context_change_command(end+1,1) = 1;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 1;
                     
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        
                            current_interference_accuracy = current_mat_table.dataMatrix(current_trial, 13);
                  
                            if current_interference_accuracy == "Correct"
                                interference_accuracy(end+1,1) = 1;
                            elseif current_interference_accuracy == "Wrong"
                                interference_accuracy(end+1,1) = 0;
                            elseif current_interference_accuracy == "" || current_interference_accuracy == "No Response"
                                interference_accuracy(end+1,1) = 0; % or 0, depending on how you want to treat it
                           
                            end
    
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) == "Different Interference"
                            context_change_command(end+1,1) = 1;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 2;
                  
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
    
                            current_interference_accuracy = current_mat_table.dataMatrix(current_trial, 13);
                  
                            if current_interference_accuracy == "Correct"
                                interference_accuracy(end+1,1) = 1;
                            elseif current_interference_accuracy == "Wrong"
                                interference_accuracy(end+1,1) = 0;
                            elseif current_interference_accuracy == "" || current_interference_accuracy == "No Response"
                                interference_accuracy(end+1,1) = 0; % or 0, depending on how you want to treat it
                           
                            end
    
                        end
                 end
            end
        
        
            %Combine all the number vectors to construct the participant's dataset
            data_per_participant = [id_number, trial_number, repetition, context_change_command, ...
                       interference_command, interference_accuracy, accuracy_rates, RTs, waitRT, decision_time, interference_subtype];
                       
        
            % Append the current dataset to the final matrix
            all_data_experiment3_main_anova = [all_data_experiment3_main_anova; data_per_participant];
    
            % Repeat the process for each participant
        end
    
        % When done with extracting data for experiment 3, save it as a mat file
        % for analysis
                save('/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment3_main_anova.mat', 'all_data_experiment3_main_anova');
    end
end







if analyze_surprise == true
    if experiment_handle == 1
    
            % Array to store all the values
            all_data_experiment1_surprise_anova = [];
    
            % Root file address for experiment 1 data 
            experiment1_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment1/';
            
            % Total subject number
            sample_size = 28;
    
            % Start iterating over each participant data
            for current_surprise_participant = 3:sample_size
                % Generate plugs for data
                csv_plug = ['output_data' num2str(current_surprise_participant) '.csv'];
                csv_plug_surprise = ['output_dataSurprise' num2str(current_surprise_participant) '.csv'];
    
                % Full file paths
                current_data_dir_surprise = fullfile(experiment1_data_dir, csv_plug_surprise);
                current_data_dir = fullfile(experiment1_data_dir, csv_plug);
            
                % Check if both files exist
                if exist(current_data_dir_surprise, 'file') ~= 2 || exist(current_data_dir, 'file') ~= 2
                    fprintf('Skipping participant %d: one or both files are missing.\n', current_surprise_participant);
                    continue;
                end
               
                current_csv_table_surprise = readtable(current_data_dir_surprise);
                current_csv_table = readtable(current_data_dir);
    
        
                %%Create number vectors to store data/ Empty the contents for the next participant
                id_number = [];
               
                trial_number = [];
                repetition = [];
                phase = [];
                history = [];
                context_change_command = [];
                context_change_subtype = [];
                interference_command = [];
                accuracy_rates = [];
               
                RTs = [];
        
                waitRT = [];

                decision_time = [];
           
                surprise_recognition_accuracy = [];
                
                current_surprise_recognition_accuracy = 0;
                current_interference_command = 0;
                current_context_change_command = 0;
                current_context_change_subtype = 0;
            
            
                % Experiment 1 presented 240 study images, 120 of which were
                % randomly chosen and used in surprise. First, fetch those
                % chosen images.  
                surprise_images = current_csv_table_surprise(:,"Var5");
            
            
                % Each surprise image has associated performance measures from both the main and the surprise task 
                for current_surprise_image = 1:size(surprise_images, 1)
                    % Choose one surprise image to work with
                    current_image_name = surprise_images{current_surprise_image, "Var5"};
                    % Find where the chosen image is located in the main task dataset 
                    matchIdx = find(strcmp(current_csv_table{:, "Var8"}, current_image_name));
        
                    

                    if (strcmp(current_csv_table{matchIdx(1), "Var11"}, 'Across') || strcmp(current_csv_table{matchIdx(1), "Var11"}, 'Within')) && strcmp(current_csv_table{matchIdx(1), "Var12"}, 'Yes Interference') 
                        history(end+1,1) = 3;
                    elseif strcmp(current_csv_table{matchIdx(1), "Var11"}, 'Across') || strcmp(current_csv_table{matchIdx(1), "Var11"}, 'Within')
                        history(end+1,1) = 1;
                    elseif strcmp(current_csv_table{matchIdx(1), "Var12"}, 'Yes Interference') 
                        history(end+1,1) = 2;
                    else 
                        history(end+1,1) = 0;
                    end

                    if history(end) ~= 0
                        continue;
                    end

                    % When location is found, first save the following simple
                    % values
                    id_number(end+1,1) = current_surprise_participant;
                    trial_number(end+1, 1) = current_surprise_image;
                    repetition(end+1,1) = current_csv_table{matchIdx(5), "Var3"};
                    phase(end+1,1) = 1;
                    
                    current_context_change_command = current_csv_table{matchIdx(5), "Var4"};
    
                    if current_context_change_command == 1
                        context_change_command(end+1,1) = 1;
                        context_change_subtype(end+1,1) = 1;
                    elseif current_context_change_command == 2
                        context_change_command(end+1,1) = 1;
                        context_change_subtype(end+1,1) = 2;
                    elseif current_context_change_command == 0
                        context_change_command(end+1,1) = 0;
                        context_change_subtype(end+1,1) = NaN;
                    end
            
                    current_interference_command = current_csv_table{matchIdx(5), "Var5"};
    
                    if current_interference_command == 1
                        interference_command(end+1, 1) = 1;
                    elseif current_interference_command == 2
                        interference_command(end+1, 1) = 0;
                    end
                    
                    % Then, save performance measures of the image in the main task 
                    accuracy_rates(end+1,1) = abs(current_csv_table{matchIdx(5), "Var6"});
                    RTs(end+1,1) = current_csv_table{matchIdx(5), "Var9"};
                    waitRT(end+1,1) = current_csv_table{matchIdx(5), "Var10"};
                    decision_time(end+1,1) = RTs(end) - waitRT(end);
            
                    current_surprise_recognition_accuracy = current_csv_table_surprise{current_surprise_image, "Var3"}; 
    
                    if current_surprise_recognition_accuracy == 2
                        surprise_recognition_accuracy(end+1,1) = 0;
                    elseif current_surprise_recognition_accuracy == 1
                        surprise_recognition_accuracy(end+1,1) = 1;
                    end
                    
                    % Now, duplicate the last elements of each relevant vector
                    % Except for phase and outcome measures
    
                    id_number(end+1,1) = id_number(end);
                    trial_number(end+1,1) = trial_number(end);
                 
                    repetition(end+1,1) = repetition(end);
                    
                    context_change_command(end+1,1) = context_change_command(end);
                    context_change_subtype(end+1,1) = context_change_subtype(end);
                    interference_command(end+1,1) = interference_command(end);
                    surprise_recognition_accuracy(end+1,1) = surprise_recognition_accuracy(end);
    
    
                    % Also, save those measures' counterparts in the surprise
                    % task
    
                    phase(end+1,1) = 2;
                    accuracy_rates(end+1,1) = abs(current_csv_table_surprise{current_surprise_image, "Var4"});
                    RTs(end+1,1) = current_csv_table_surprise{current_surprise_image, "Var7"};
                    waitRT(end+1,1) = current_csv_table_surprise{current_surprise_image, "Var8"}; 
                    decision_time(end+1,1) = RTs(end) - waitRT(end);
                   
    
                end
               
                
                % Combine all the data taken from the current participant
                data_per_participant_surprise = [id_number, trial_number, repetition, phase, context_change_command, ...
                interference_command, accuracy_rates, RTs, waitRT, decision_time, surprise_recognition_accuracy, context_change_subtype];
                 
                % Add the individual's data to the general dataset
                all_data_experiment1_surprise_anova = [all_data_experiment1_surprise_anova; data_per_participant_surprise];
    
                % Repeat for each participant
            end
    
             % When done with extracting data for experiment 1, save it as a mat file
        % for analysis
                save('/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment1_surprise_anova.mat', 'all_data_experiment1_surprise_anova');

    elseif experiment_handle == 2
        % Array to store all the values
        all_data_experiment2_surprise_anova = [];

        % Root file address for experiment 2 data 
        experiment2_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment2/';
        
        % Total subject number
        sample_size = 54;

        for current_surprise_participant = 1:sample_size
        
            % Generate plugs for data
            csv_plug = ['output_data' num2str(current_surprise_participant) '.csv'];
            csv_plug_surprise = ['output_dataSurprise' num2str(current_surprise_participant) '.csv'];

            % Full file paths
            current_data_dir_surprise = fullfile(experiment2_data_dir, csv_plug_surprise);
            current_data_dir = fullfile(experiment2_data_dir, csv_plug);
        
            % Check if both files exist
            if exist(current_data_dir_surprise, 'file') ~= 2 || exist(current_data_dir, 'file') ~= 2
                fprintf('Skipping participant %d: one or both files are missing.\n', current_surprise_participant);
                continue;
            end
           
            current_csv_table_surprise = readtable(current_data_dir_surprise);
            current_csv_table = readtable(current_data_dir);
    
            %%Create number vectors to store data/ Empty the contents for the next participant
            id_number = [];
            trial_number = []; 
            history = [];
            repetition = [];
            phase = [];
            context_change_command = [];
            interference_command = [];
            accuracy_rates = [];
            RTs = [];
            waitRT= [];
            decision_time = [];
            % interference_accuracy = [];
            surprise_recognition_accuracy = [];
            interference_subtype = [];

            % current_interference_accuracy = "";
            current_surprise_recognition_accuracy = 0;
            current_context_change_command = 0;
            current_interference_command = 0;
           
    
            % Make a list of the images used in surprise
            surprise_images = current_csv_table_surprise(1:120, "Var5");

        
            % Iterate over each surprise image
            for current_surprise_image = 1:size(surprise_images, 1)
                current_image_name = surprise_images{current_surprise_image, "Var5"};
                matchIdx = find(strcmp(current_csv_table{:, "Var8"}, current_image_name));
    
              
                % if (strcmp(current_csv_table{matchIdx(1), "Var12"}, 'Yes Change') && strcmp(current_csv_table{matchIdx(1), "Var13"}, 'Right Interference')) || (strcmp(current_csv_table{matchIdx(1), "Var12"}, 'Yes Change') && strcmp(current_csv_table{matchIdx(1), "Var13"}, 'Left Interference'))
                %     history(end+1,1) = 3;
                % elseif strcmp(current_csv_table{matchIdx(1), "Var12"}, 'Yes Change')
                %     history(end+1,1) = 1;
                % elseif strcmp(current_csv_table{matchIdx(1), "Var13"}, 'Right Interference') || strcmp(current_csv_table{matchIdx(1), "Var13"}, 'Left Interference')
                %     history(end+1,1) = 2;
                % else
                %     history(end+1,1) = 0;
                % end
                % 
                % if history(end) ~= 0
                %    continue;
                % end

                id_number(end+1,1) = current_surprise_participant;
                trial_number(end+1, 1) = current_surprise_image;

                repetition(end+1,1) = current_csv_table{matchIdx(5), "Var3"};
                % phase(end+1,1) = 1;
                
                current_context_change_command = current_csv_table{matchIdx(5), "Var4"};               
                
                if current_context_change_command == 2
                    context_change_command(end+1, 1) = 1;
                elseif current_context_change_command == 0
                    context_change_command(end+1, 1) = 0;
                end
                
                current_interference_command = current_csv_table{matchIdx(5), "Var5"};

                if current_interference_command == 2
                    interference_command(end+1, 1) = 0;
                    interference_subtype(end+1, 1) = NaN;
                elseif (current_interference_command == 1 && current_csv_table{matchIdx(5), "Var13"} == "Left Interference") || (current_interference_command == 1 && current_csv_table{matchIdx(5), "Var15"} == "Left Interference")
                    interference_command(end+1, 1) = 1;
                    interference_subtype(end+1, 1) = 2;
                elseif (current_interference_command == 1 && current_csv_table{matchIdx(5), "Var13"} == "Right Interference") || (current_interference_command == 1 && current_csv_table{matchIdx(5), "Var15"} == "Right Interference")
                    interference_command(end+1, 1) = 1;
                    interference_subtype(end+1, 1) = 1;
                end

                % accuracy_rates(end+1,1) = abs(current_csv_table{matchIdx(5), "Var6"});
                % RTs(end+1,1) = current_csv_table{matchIdx(5), "Var9"};
                % waitRT(end+1,1) = current_csv_table{matchIdx(5), "Var10"}; 
                % decision_time(end+1,1) = RTs(end) - waitRT(end);

                current_surprise_recognition_accuracy = current_csv_table_surprise{current_surprise_image, "Var3"}; 

                if current_surprise_recognition_accuracy == 2
                    surprise_recognition_accuracy(end+1,1) = 0;
                elseif current_surprise_recognition_accuracy == 1
                    surprise_recognition_accuracy(end+1,1) = 1;
                end

                % id_number(end+1,1) = id_number(end);
                % trial_number(end+1,1) = trial_number(end);
                % history(end+1,1) = history(end);
                % repetition(end+1,1) = repetition(end);
                
                % context_change_command(end+1,1) = context_change_command(end);
                % interference_command(end+1,1) = interference_command(end);
                % interference_subtype(end+1,1) = interference_subtype(end);
                % surprise_recognition_accuracy(end+1,1) = surprise_recognition_accuracy(end);



                % phase(end+1,1) = 2;
                    
                accuracy_rates(end+1,1) = abs(current_csv_table_surprise{current_surprise_image, "Var4"});
                RTs(end+1,1) = current_csv_table_surprise{current_surprise_image, "Var7"};
                waitRT(end+1,1) = current_csv_table_surprise{current_surprise_image, "Var8"};
                decision_time(end+1,1) = RTs(end) - waitRT(end);
    
                % current_interference_accuracy = current_csv_table{matchIdx(5), "Var11"};
                % 
                % if current_interference_accuracy == "Left Selection" && (current_csv_table{matchIdx(5), "Var13"} == "Left Interference" || current_csv_table{matchIdx(5), "Var15"} == "Left Interference") 
                %     interference_accuracy(end+1,1) = 1;
                % elseif current_interference_accuracy == "Right Selection" && (current_csv_table{matchIdx(5), "Var13"} == "Right Interference" || current_csv_table{matchIdx(5), "Var15"} == "Right Interference") 
                %     interference_accuracy(end+1,1) = 1;
                % elseif current_csv_table{matchIdx(5), "Var13"} == "No Interference" || current_csv_table{matchIdx(5), "Var15"} == "No Interference"
                %     interference_accuracy(end+1,1) = NaN;
                % else
                %     interference_accuracy(end+1,1) = 0;
                % end

            end
            
            % Combine all the data taken from the current participant
            data_per_participant_surprise = [id_number, trial_number, repetition, context_change_command, ...
            interference_command, accuracy_rates, RTs, waitRT, decision_time, surprise_recognition_accuracy];
            
            
            % Add the individual's data to the general dataset
            all_data_experiment2_surprise_anova = [all_data_experiment2_surprise_anova; data_per_participant_surprise];
      
            % Repeat for each participant
        end
    
    % When done with extracting data for experiment 1, save it as a mat file
    % for analysis
            save('/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment2_surprise_anova.mat', 'all_data_experiment2_surprise_anova');
    
    elseif experiment_handle == 3
        all_data_experiment3_surprise_anova = [];

        % Root file address for experiment 3 data 
        experiment3_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment3_mat/';
        
        % Total subject number
        sample_size = 53;

        % Count how many people are missing the surprise task
        skip_participant = 0;

        % Count how many incongruent trials there were
        incongruent_target = 0;

        for current_surprise_participant = 1:sample_size
            if current_surprise_participant == 8
                continue;
            end
            
            % Generate plugs for data
            mat_plug = ['output_data' num2str(current_surprise_participant) '.mat'];
            mat_plug_surprise = ['output_dataSurprise' num2str(current_surprise_participant) '.mat'];

            % Full file paths
            current_data_dir_surprise = fullfile(experiment3_data_dir, mat_plug_surprise);
            current_data_dir = fullfile(experiment3_data_dir, mat_plug);
        
            % Check if both files exist
            if exist(current_data_dir_surprise, 'file') ~= 2 || exist(current_data_dir, 'file') ~= 2
                fprintf('Skipping participant %d: one or both files are missing.\n', current_surprise_participant);
                skip_participant = skip_participant + 1;
                continue;
            end
        
            % Load files
            current_mat_table_surprise = load(current_data_dir_surprise);
            current_mat_table = load(current_data_dir);
                      
            %%Create number vectors to store data/ Empty the contents for the next participant
            current_change_value = ""; 
            current_interference_value = ""; 
            current_interference_accuracy = "";
            
            id_number= [];
            trial_number = []; 
            history = [];
            repetition = [];
            phase = [];
            context_change_command = [];
            interference_command = [];
            
            accuracy_rates = [];
            RTs = [];
            waitRT = [];
            decision_time = [];
            interference_accuracy = [];
            surprise_recognition_accuracy = [];
            interference_subtype = [];
            studied_before = [];

            current_surprise_recognition_accuracy = 0;           
            
            %% Since experiment 3 surprise task was a bit broken, this bit filters out...
            %% surprise images that were not presented in the main task, as well as targets... 
            %% images taken as foils 
    
            % Store images used as targets in surprise task    
            surprise_target_images = current_mat_table_surprise.dataMatrix2(:,5);
            % Remove empty strings from the image names
            surprise_target_images(surprise_target_images == "") = [];
        
            % Store images used as foils in surprise task
            surprise_foil_images = current_mat_table_surprise.dataMatrix2(:,6);
            % Remove empty strings from the image names
            surprise_foil_images(surprise_foil_images == "") = [];
              
            % Store image pairs tested in the main task
            main_left_image = current_mat_table.dataMatrix(:, 6);
            main_right_image = current_mat_table.dataMatrix(:, 8);
            
            % CHECK I:
            % This checks and removes if a foil image was mistook for one of
            % the study images in the main task
    
            for foil_check = 1:(length(surprise_foil_images)-1)
                % Choose a foil for comparison 
                current_foil_name = surprise_foil_images(foil_check);
                
                % Compare the foils to the image pairs in the main task
                if any(strcmp(current_foil_name, main_left_image)) || any(strcmp(current_foil_name, main_right_image))
                    
                    % If any of the foils is taken from the image pairs, remove
                    % it from the analysis altogether by marking the target
                    % image paired with it in the surprise task
                    surprise_target_images(foil_check) = "NA";                
                end
    
                % Repeat for all foils
            end      
        
            % Remove the flagged target images as they're invalid for the
            % analysis
            surprise_target_images(surprise_target_images == "NA") = [];
        
            % CHECK II:
            % This checks whether the image supposed to have been used as a
            % target in the surprise task was actually never studied in the
            % main task
            for target_check = 1:(numel(surprise_target_images) - 1)
    
                % Choose a target for comparison
                current_target_name = surprise_target_images(target_check);  
                
                % Check if the chosen target doesn't appear in either left or
                % right targets in the main task
                if ~any(strcmp(current_target_name, main_left_image)) && ~any(strcmp(current_target_name, main_right_image))
                    
                    % If the target was indeed never studied before, mark it up
                    % for removal
                    surprise_target_images(target_check) = "NA";              
                end
        
            end
        
            % Delete the flagged targets images as they shouldn't enter the
            % analysis
            surprise_target_images(surprise_target_images == "NA") = [];
    
            % Lastly, make sure the remaining targets are stored in a proper
            % format. The resulting list is images whose data should be
            % extracted and analyzed. 
            surprise_target_images = unique(surprise_target_images(surprise_target_images ~= ""));
 
    
            %% Surprise pre-processing ends...
            %% Now, with the list of valid surprise task items, start extracting relevant data for analysis 
    
            % Iterate over valid surprise task images
            for current_surprise_image = 1:size(surprise_target_images, 1)
                current_image_name = surprise_target_images(current_surprise_image, 1);
    
                % Find which row the current surprise image appears in the main
                % dataset
                matchIdx = find(strcmp(current_mat_table.dataMatrix(:, 8), current_image_name) | strcmp(current_mat_table.dataMatrix(:, 6), current_image_name));
                % 
                % if (strcmp(current_mat_table.dataMatrix(matchIdx(1), 11), "Yes Change") && strcmp(current_mat_table.dataMatrix(matchIdx(1), 12), "Unique Interference")) || (strcmp(current_mat_table.dataMatrix(matchIdx(1), 11), "Yes Change") && strcmp(current_mat_table.dataMatrix(matchIdx(1), 12), "Different Interference"))
                %     history(end+1,1) = 3;
                % elseif strcmp(current_mat_table.dataMatrix(matchIdx(1), 11), "Yes Change")
                %     history(end+1,1) = 1;
                % elseif strcmp(current_mat_table.dataMatrix(matchIdx(1), 12), "Unique Interference") || strcmp(current_mat_table.dataMatrix(matchIdx(1), 12), "Different Interference")
                %     history(end+1,1) = 2;
                % else
                %     history(end+1,1) = 0;
                % end

                % if history(end) ~= 0
                %    continue;
                % else
                
                %% This little check here is so important. This makes sure that the target image in the surprise phase 
                %% matches the probed image at Phase 1 testing. 
                
                if current_mat_table.dataMatrix(matchIdx(5), 10) ~= current_image_name
                    incongruent_target = incongruent_target + 1;
                    continue;
                end             
                % end

                % Store ID, Trial and Block info from the main dataset
                id_number(end+1,1) = current_surprise_participant;
                trial_number(end+1,1) = current_surprise_image;

                repetition(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 3));
                % phase(end+1,1) = 1;
    
                % Since change commands are saved as strings, convert to numeric
                % values
                current_change_value = current_mat_table.dataMatrix(matchIdx(5), 11);
                if current_change_value == "No Change"
                    context_change_command(end+1,1) = 0;
                elseif current_change_value == "Yes Change"
                    context_change_command(end+1,1) = 1;
                end
    
                % Since interference commands are saved as strings, convert to numeric
                % values
                current_interference_value = current_mat_table.dataMatrix(matchIdx(5), 12);
                if current_interference_value == "No Interference Presented"
                    interference_command(end+1,1) = 0;
                    interference_subtype(end+1, 1) = NaN;
                    % RTs(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 15)) - 0.9;
                    % waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 16)) - 0.9;
                    % decision_time(end+1,1) = RTs(end) - waitRT(end);
                elseif current_interference_value == "Unique Interference" % All RGBs are unique
                    interference_command(end+1,1) = 1;
                    interference_subtype(end+1, 1) = 1;
                    % RTs(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 15)) - 0.2;
                    % waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 16)) - 0.2;
                    % decision_time(end+1,1) = RTs(end) - waitRT(end);

                elseif current_interference_value == "Different Interference" % Two RGBs repeat
                    interference_command(end+1,1) = 1;
                    interference_subtype(end+1, 1) = 2;
                    % RTs(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 15)) - 0.2;
                    % waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 16)) - 0.2;
                    % decision_time(end+1,1) = RTs(end) - waitRT(end);
                end
    
                % % Fetch ACC and RTs from the main task
                % accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(matchIdx(5), 14)));
                
                current_surprise_recognition_accuracy = str2double(current_mat_table_surprise.dataMatrix2(current_surprise_image, 3)); 
                    
                if current_surprise_recognition_accuracy == 2
                    surprise_recognition_accuracy(end+1,1) = 0;
                elseif current_surprise_recognition_accuracy == 1
                    surprise_recognition_accuracy(end+1,1) = 1;
                end

                % id_number(end+1,1) = id_number(end);
                % trial_number(end+1,1) = trial_number(end);
                % history(end+1,1) = history(end);
                % repetition(end+1,1) = repetition(end);
                
                % context_change_command(end+1,1) = context_change_command(end);
                % interference_command(end+1,1) = interference_command(end);
                % interference_subtype(end+1,1) = interference_subtype(end);
                % surprise_recognition_accuracy(end+1,1) = surprise_recognition_accuracy(end);

                % phase(end+1,1) = 2;
        
                % Fetch ACC and RTs for the same image from the surprise task
                accuracy_rates(end+1,1) = abs(str2double(current_mat_table_surprise.dataMatrix2(current_surprise_image, 4)));
                RTs(end+1,1) = str2double(current_mat_table_surprise.dataMatrix2(current_surprise_image, 7));
                waitRT(end+1,1) = str2double(current_mat_table_surprise.dataMatrix2(current_surprise_image, 8)); 
                decision_time(end+1,1) = RTs(end) - waitRT(end);

                % % Find interference decisions and convert to numeric values
                % current_interference_accuracy = current_mat_table.dataMatrix(matchIdx(5), 13);
                % if current_interference_accuracy == "No Interference Selected"
                %     interference_accuracy(end+1,1) = NaN;
                % elseif current_interference_accuracy == "Correct"
                %     interference_accuracy(end+1,1) = 1;
                % elseif current_interference_accuracy == "Wrong"
                %     interference_accuracy(end+1,1) = 0;  
                % elseif current_interference_accuracy == "" || current_interference_accuracy == "No Response"
                %     interference_accuracy(end+1,1) = 0; % or 0, depending on how you want to treat it       
                % end

            end
  
            %Combine all the number vectors to construct the participant's dataset
            data_per_participant_surprise = [id_number, trial_number, repetition, context_change_command, ...
            interference_command, accuracy_rates, RTs, waitRT, decision_time, surprise_recognition_accuracy];
            
            % Add each participant's dataset to the existing one
            all_data_experiment3_surprise_anova = [all_data_experiment3_surprise_anova; data_per_participant_surprise];
        end

        % When done with extracting data for experiment 3, save it as a mat file
        % for analysis
        save('/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment3_surprise_anova.mat', 'all_data_experiment3_surprise_anova');
        
        disp(skip_participant);
        disp(incongruent_target);
    end
end

if analyze_sixlets == true
    if experiment_handle == 1
 
            % Experiment 1 data location
            experiment1_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment1/';
            
            all_data_experiment1_sixlets_anova = [];
    
            % Define latest participant number for experiment 1
            sample_size = 28;
        
            % Start iterating from participant 3 as the first two are faulty
            for current_subject = 3:sample_size
                %% Generate plug for data
                csv_plug = ['output_data' num2str(current_subject) '.csv'];
               
                current_data_dir = fullfile(experiment1_data_dir, csv_plug);
            
                % Check if both files exist
                if exist(current_data_dir, 'file') ~= 2
                    fprintf('Skipping participant %d: one or both files are missing.\n', current_subject);
                    continue;
                end
               
                current_csv_table = readtable(current_data_dir);
            
                %%Create number vectors to store data/ Empty the contents for the next participant
                id_number = [];
                trial_number = [];
                repetition = [];
                block = [];
                accuracy_rates = [];
                RTs = [];
                waitRT = [];
                decision_time = [];
                conditions = NaN(1440,1);
                context = NaN(1440,1);
                interference = NaN(1440,1);
               
                %Define trial count for experiment 1
                trial_count = 1440;
                
                % Iterate over each line in the current data
                for current_trial = 1:trial_count
                    % Store data for the 1st trials only
                    if mod(current_trial,6) == 1
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        repetition(end+1, 1) = 1;
                        block(end+1, 1) = current_csv_table{current_trial, "Var15"};
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                        decision_time(end+1,1) = RTs(end) - waitRT(end);

                        if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                            conditions(current_trial,1) = 1;
                            context(current_trial) = 0;
                            interference(current_trial) = 0;
                        elseif current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} ~= 2
                            conditions(current_trial,1) = 2;
                            context(current_trial) = 0;
                            interference(current_trial) = 1;
                        elseif (current_csv_table{current_trial, "Var4"} == 1 || current_csv_table{current_trial, "Var4"} == 2) && current_csv_table{current_trial, "Var5"} == 2
                            conditions(current_trial,1) = 3;
                            context(current_trial) = 1;
                            interference(current_trial) = 0;
                        elseif (current_csv_table{current_trial, "Var4"} == 1 || current_csv_table{current_trial, "Var4"} == 2) && current_csv_table{current_trial, "Var5"} ~= 2
                            conditions(current_trial,1) = 4;
                            context(current_trial) = 1;
                            interference(current_trial) = 1;
                        end
                      
                    elseif mod(current_trial,6) == 2
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        repetition(end+1, 1) = 2;
                        block(end+1, 1) = current_csv_table{current_trial, "Var15"};
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                        decision_time(end+1,1) = RTs(end) - waitRT(end);
                    elseif mod(current_trial,6) == 3
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        repetition(end+1, 1) = 3;
                        block(end+1, 1) = current_csv_table{current_trial, "Var15"};
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                        decision_time(end+1,1) = RTs(end) - waitRT(end);
                    elseif mod(current_trial,6) == 4
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        repetition(end+1, 1) = 4;
                        block(end+1, 1) = current_csv_table{current_trial, "Var15"};
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                        decision_time(end+1,1) = RTs(end) - waitRT(end);
                    elseif mod(current_trial,6) == 5
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        repetition(end + 1,1) = 5;
                        block(end+1, 1) = current_csv_table{current_trial, "Var15"};
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};      
                        decision_time(end+1,1) = RTs(end) - waitRT(end);

                        if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                            conditions(current_trial,1) = 5;
                            context(current_trial) = 0;
                            interference(current_trial) = 0;
                        elseif current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} ~= 2
                            conditions(current_trial,1) = 6;
                            context(current_trial) = 0;
                            interference(current_trial) = 1;
                        elseif (current_csv_table{current_trial, "Var4"} == 1 || current_csv_table{current_trial, "Var4"} == 2) && current_csv_table{current_trial, "Var5"} == 2
                            conditions(current_trial,1) = 7;
                            context(current_trial) = 1;
                            interference(current_trial) = 0;
                        elseif (current_csv_table{current_trial, "Var4"} == 1 || current_csv_table{current_trial, "Var4"} == 2) && current_csv_table{current_trial, "Var5"} ~= 2
                            conditions(current_trial,1) = 8;
                            context(current_trial) = 1;
                            interference(current_trial) = 1;
                        end

                    elseif mod(current_trial,6) == 0
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        repetition(end + 1,1) = 6;
                        block(end+1, 1) = current_csv_table{current_trial, "Var15"};
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};  
                        decision_time(end+1,1) = RTs(end) - waitRT(end);
                    end            
                end
        
            
                %Combine all the number vectors to construct the participant's dataset
                data_per_participant = [id_number, trial_number, repetition, block, accuracy_rates, RTs, waitRT, decision_time, conditions, context, interference];
                            
            
                % Append the current dataset to the final matrix
                all_data_experiment1_sixlets_anova = [all_data_experiment1_sixlets_anova; data_per_participant];
               
                % Repeat the whole process for each participant
            end
        
        % When done with extracting data for experiment 1, save it as a mat file
        % for analysis
                save('/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment1_sixlets_anova.mat', 'all_data_experiment1_sixlets_anova');

    elseif experiment_handle == 2
        % Experiment 2 data location
                experiment2_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment2/';
            
                all_data_experiment2_sixlets_anova = [];
    
                % Define latest participant number for experiment 2
                sample_size = 54;
                
                % Start iterating from participant 1
                for current_subject = 1:sample_size
                    
                    % Generate plug for data
                    csv_plug = ['output_data' num2str(current_subject) '.csv'];
    
                    current_data_dir = fullfile(experiment2_data_dir, csv_plug);
                
                    % Check if both files exist
                    if exist(current_data_dir, 'file') ~= 2
                        fprintf('Skipping participant %d: one or both files are missing.\n', current_subject);
                        continue;
                    end
                   
                    current_csv_table = readtable(current_data_dir);
        
                    %%Create number vectors to store data/ Empty the contents for the next participant
                    id_number = [];
                    trial_number = [];
                    repetition = [];
                    block = [];
                    accuracy_rates = [];
                    RTs = [];
                    waitRT = [];
                    decision_time = [];
                    conditions = NaN(720,1);
                    context = NaN(720,1);
                    interference = NaN(720,1);

                    % Define how many trials experiment 2 had
                    trial_count = 720;
            
                    % Start looking through each trial
                    for current_trial = 1:trial_count
                        if mod(current_trial,6) == 1
                            
                            id_number(end+1,1) = current_subject;
                            trial_number(end+1,1) = current_trial;
                            repetition(end+1,1) = 1;
                            block(end+1, 1) = current_csv_table{current_trial, "Var16"};
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);

                            if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                                conditions(current_trial,1) = 1;
                                context(current_trial) = 0;
                                interference(current_trial) = 0;
                            elseif current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} ~= 2
                                conditions(current_trial,1) = 2;
                                context(current_trial) = 0;
                                interference(current_trial) = 1;
                            elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 2
                                conditions(current_trial,1) = 3;
                                context(current_trial) = 1;
                                interference(current_trial) = 0;
                            elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} ~= 2
                                conditions(current_trial,1) = 4;
                                context(current_trial) = 1;
                                interference(current_trial) = 1;
                            end
    
                        elseif  mod(current_trial,6) == 2
                          
                            id_number(end+1,1) = current_subject;
                            trial_number(end+1,1) = current_trial;
                            repetition(end+1,1) = 2;         
                            block(end+1, 1) = current_csv_table{current_trial, "Var16"};
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                               
                               
                        elseif  mod(current_trial,6) == 3
                          
                            id_number(end+1,1) = current_subject;
                            trial_number(end+1,1) = current_trial;
                            repetition(end+1,1) = 3;      
                            block(end+1, 1) = current_csv_table{current_trial, "Var16"};
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        
                        elseif  mod(current_trial,6) == 4
                          
                            id_number(end+1,1) = current_subject;
                            trial_number(end+1,1) = current_trial;
                            repetition(end+1,1) = 4; 
                            block(end+1, 1) = current_csv_table{current_trial, "Var16"};
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        
                        elseif  mod(current_trial,6) == 5
                          
                            id_number(end+1,1) = current_subject;
                            trial_number(end+1,1) = current_trial;
                            repetition(end+1,1) = 5;
                            block(end+1, 1) = current_csv_table{current_trial, "Var16"};
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);

                            if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                                conditions(current_trial,1) = 5;
                                context(current_trial) = 0;
                                interference(current_trial) = 0;
                            elseif current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} ~= 2
                                conditions(current_trial,1) = 6;
                                context(current_trial) = 0;
                                interference(current_trial) = 1;
                            elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 2
                                conditions(current_trial,1) = 7;
                                context(current_trial) = 1;
                                interference(current_trial) = 0;
                            elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} ~= 2
                                conditions(current_trial,1) = 8;
                                context(current_trial) = 1;
                                interference(current_trial) = 1;
                            end
                            
                           
                        elseif  mod(current_trial,6) == 0
                          
                            id_number(end+1,1) = current_subject;
                            trial_number(end+1,1) = current_trial;
                            repetition(end+1,1) = 6;    
                            block(end+1, 1) = current_csv_table{current_trial, "Var16"};
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                           
                        end
                    end
    
                %Combine all the number vectors to construct the participant's dataset
                data_per_participant = [id_number, trial_number, repetition, block, accuracy_rates, RTs, waitRT, decision_time, conditions, context, interference];

                % Append the current dataset to the final matrix
                all_data_experiment2_sixlets_anova = [all_data_experiment2_sixlets_anova; data_per_participant];
        
                % Repeat the whole process for each participant
                end
        
        % When done with extracting data for experiment 2, save it as a mat file
        % for analysis
                save('/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment2_sixlets_anova.mat', 'all_data_experiment2_sixlets_anova');

    elseif experiment_handle == 3
        
        % Trial exclusion counter
        trimmed = zeros(37440,1);

        global_count = 0;

        % Participant exclusion counter
        skipped = 0;

        % Experiment 3 data location
        experiment3_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment3_mat/';
    
        all_data_experiment3_sixlets_anova = [];

        % Define latest participant number for experiment 3
        sample_size = 53;
        
        % Start iterating from participant 1
        for current_subject = 1:sample_size

            if current_subject == 8
                continue;
            end
    
            % Generate plug for data
            mat_plug = ['output_data' num2str(current_subject) '.mat'];

            current_data_dir = fullfile(experiment3_data_dir, mat_plug);
        
            % Check if both files exist
            if exist(current_data_dir, 'file') ~= 2
                fprintf('Skipping participant %d: one or both files are missing.\n', current_subject);
                skipped = skipped + 1;
                continue;
            end
           
            current_mat_table = load(current_data_dir);

            
            %%Create number vectors to store data/ Empty the contents for the next participant
            id_number = [];
            trial_number = [];
            repetition = [];
            block = [];
            accuracy_rates = [];
            RTs = [];
            waitRT = [];
            decision_time = [];
            conditions = NaN(720,1);
            context = NaN(720,1);
            interference = NaN(720,1);

            % Define how many trials experiment 3 had
            trial_count = 720;
    
            % Start looking through each trial
            for current_trial = 1:trial_count
                     if mod(current_trial,6) == 1

                        global_count = global_count + 1;
                            
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);  
                        repetition(end+1,1) = 1;
                        accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                        
                      
                        if current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "No Interference Presented"  
                            conditions(current_trial,1) = 1;
                            context(current_trial,1) = 0;
                            interference(current_trial,1) = 0;
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) ~= "No Interference Presented"   
                            conditions(current_trial,1) = 2;
                            context(current_trial,1) = 0;
                            interference(current_trial,1) = 1;
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) == "No Interference Presented"   
                            conditions(current_trial,1) = 3;
                            context(current_trial,1) = 1;
                            interference(current_trial,1) = 0;
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) ~= "No Interference Presented"   
                            conditions(current_trial,1) = 4;
                            context(current_trial,1) = 1;
                            interference(current_trial,1) = 1;
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        end
    
                     elseif mod(current_trial, 6) == 2
                        
                         global_count = global_count + 1;

                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);  
                        repetition(end+1,1) = 2;
                        accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                        RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15));
                        waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16));
                        decision_time(end+1,1) = RTs(end) - waitRT(end);
                            
                     elseif mod(current_trial, 6) == 3

                         global_count = global_count + 1;


                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);  
                        repetition(end+1,1) = 3;
                        accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                        RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15));
                        waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16));
                        decision_time(end+1,1) = RTs(end) - waitRT(end);
    
                     elseif mod(current_trial, 6) == 4

                        global_count = global_count + 1;

                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);  
                        repetition(end+1,1) = 4;
                        accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                        RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15));
                        waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16));
                        decision_time(end+1,1) = RTs(end) - waitRT(end);
    
                     elseif mod(current_trial, 6) == 5

                        global_count = global_count + 1;

                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);  
                        repetition(end+1,1) = 5;
                        accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
    
                        if current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "No Interference Presented"  
                            conditions(current_trial,1) = 3;
                            context(current_trial,1) = 0;
                            interference(current_trial,1) = 0;
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) ~= "No Interference Presented"   
                            conditions(current_trial,1) = 4;
                            context(current_trial,1) = 0;
                            interference(current_trial,1) = 1;
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) == "No Interference Presented"   
                            conditions(current_trial,1) = 3;
                            context(current_trial,1) = 1;
                            interference(current_trial,1) = 0;
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) ~= "No Interference Presented"   
                            conditions(current_trial,1) = 4;
                            context(current_trial,1) = 1;
                            interference(current_trial,1) = 1;
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                            decision_time(end+1,1) = RTs(end) - waitRT(end);
                        end
                     
                     elseif mod(current_trial, 6) == 0
                        
                        global_count = global_count + 1;


                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = current_trial;
                        block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);  
                        repetition(end+1,1) = 6;
                        accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                        RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15));
                        waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16));
                        decision_time(end+1,1) = RTs(end) - waitRT(end);
                     end
             
                    if abs(str2double(current_mat_table.dataMatrix(current_trial,7)) - str2double(current_mat_table.dataMatrix(current_trial,9))) < 30
                        trimmed(global_count,1) = 1;
                    end
                
            end
        
        
            %Combine all the number vectors to construct the participant's dataset
            data_per_participant = [id_number, trial_number, repetition, block, accuracy_rates, RTs, waitRT, decision_time, conditions, context, interference];
               
        
            % Append the current dataset to the final matrix
            all_data_experiment3_sixlets_anova = [all_data_experiment3_sixlets_anova; data_per_participant];
    
            % Repeat the process for each participant
        end
    end

    disp(size(all_data_experiment3_sixlets_anova));

    % Shave off the invalid trials from the final dataset
    all_data_experiment3_sixlets_anova(trimmed == 1, :) = [];

    disp(size(all_data_experiment3_sixlets_anova));



        % When done with extracting data for experiment 3, save it as a mat file
        % for analysis
        save('/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment3_sixlets_anova.mat', 'all_data_experiment3_sixlets_anova');
       
end