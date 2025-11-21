%% Which experiment are you working with?

experiment_handle = 3;

%% Do you want to extract data for the main experiment? 

extract_main = true;

%% Do you want to extract data for the surprise task? 

extract_surprise = true;


if extract_main == true
    if experiment_handle == 1

        % Experiment 1 data location
        experiment1_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment1/';
        
        all_data_experiment1 = [];

        % Define latest participant number for experiment 1
        sample_size = 28;
    
        % Start iterating from participant 3 as the first two are faulty
        for current_subject = 1:sample_size
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
            block = [];
            context_change_command = [];
            context_change_subtype = [];
            interference_command = [];
            accuracy_rates = [];
            RTs = [];
            waitRT = [];
           

            %Define trial count for experiment 1
            trial_count = 1440;
            
            % Iterate over each line in the current data
            for current_trial = 1:trial_count
                % Store data for the 1st trials only
                if mod(current_trial,6) == 1
                    id_number(end+1,1) = current_subject;
                    trial_number(end+1,1) = 1;
                    block(end+1,1) = current_csv_table{current_trial, "Var15"};
                    
                    if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                        context_change_command(end+1,1) = 0;
                        context_change_subtype(end+1,1) = NaN;
                        interference_command(end+1,1) = 0;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    elseif current_csv_table{current_trial, "Var4"} == 1 && current_csv_table{current_trial, "Var5"} == 2
                        context_change_command(end+1,1) = 1;
                        context_change_subtype(end+1,1) = 1;
                        interference_command(end+1,1) = 0;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 2
                        context_change_command(end+1,1) = 1;
                        context_change_subtype(end+1,1) = 2;
                        interference_command(end+1,1) = 0;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    elseif current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 1
                        context_change_command(end+1,1) = 0;
                        context_change_subtype(end+1,1) = NaN;
                        interference_command(end+1,1) = 1;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};     
                    elseif current_csv_table{current_trial, "Var4"} == 1 && current_csv_table{current_trial, "Var5"} == 1
                        context_change_command(end+1,1) = 1;
                        context_change_subtype(end+1,1) = 1;
                        interference_command(end+1,1) = 1;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 1
                        context_change_command(end+1,1) = 1;
                        context_change_subtype(end+1,1) = 2;
                        interference_command(end+1,1) = 1;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    end
                elseif mod(current_trial,6) == 2
                    id_number(end+1,1) = current_subject;
                    trial_number(end+1,1) = 2;
                    block(end+1,1) = current_csv_table{current_trial, "Var15"};
                    context_change_command(end+1,1) = NaN;
                    context_change_subtype(end+1,1) = NaN;
                    interference_command(end+1,1) = NaN;
                    accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                    RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                    waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                elseif mod(current_trial,6) == 3
                    id_number(end+1,1) = current_subject;
                    trial_number(end+1,1) = 3;
                    block(end+1,1) = current_csv_table{current_trial, "Var15"};
                    context_change_command(end+1,1) = NaN;
                    context_change_subtype(end+1,1) = NaN;
                    interference_command(end+1,1) = NaN;
                    accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                    RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                    waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                elseif mod(current_trial,6) == 4
                    id_number(end+1,1) = current_subject;
                    trial_number(end+1,1) = 4;
                    block(end+1,1) = current_csv_table{current_trial, "Var15"};
                    context_change_command(end+1,1) = NaN;
                    context_change_subtype(end+1,1) = NaN;
                    interference_command(end+1,1) = NaN;
                    accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                    RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                    waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                elseif mod(current_trial,6) == 5
                    id_number(end+1,1) = current_subject;
                    trial_number(end+1,1) = 5;
                    block(end+1,1) = current_csv_table{current_trial, "Var15"};
                    
                    if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                        context_change_command(end+1,1) = 0;
                        context_change_subtype(end+1,1) = NaN;
                        interference_command(end+1,1) = 0;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    elseif current_csv_table{current_trial, "Var4"} == 1 && current_csv_table{current_trial, "Var5"} == 2
                        context_change_command(end+1,1) = 1;
                        context_change_subtype(end+1,1) = 1;
                        interference_command(end+1,1) = 0;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 2
                        context_change_command(end+1,1) = 1;
                        context_change_subtype(end+1,1) = 2;
                        interference_command(end+1,1) = 0;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    elseif current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 1
                        context_change_command(end+1,1) = 0;
                        context_change_subtype(end+1,1) = NaN;
                        interference_command(end+1,1) = 1;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};     
                    elseif current_csv_table{current_trial, "Var4"} == 1 && current_csv_table{current_trial, "Var5"} == 1
                        context_change_command(end+1,1) = 1;
                        context_change_subtype(end+1,1) = 1;
                        interference_command(end+1,1) = 1;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    elseif current_csv_table{current_trial, "Var4"} == 2 && current_csv_table{current_trial, "Var5"} == 1
                        context_change_command(end+1,1) = 1;
                        context_change_subtype(end+1,1) = 2;
                        interference_command(end+1,1) = 1;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    end
                elseif mod(current_trial,6) == 0
                    id_number(end+1,1) = current_subject;
                    trial_number(end+1,1) = 6;
                    block(end+1,1) = current_csv_table{current_trial, "Var15"};
                    context_change_command(end+1,1) = NaN;
                    context_change_subtype(end+1,1) = NaN;
                    interference_command(end+1,1) = NaN;
                    accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                    RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                    waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};               
                end            
            end
    
        
            %Combine all the number vectors to construct the participant's dataset
            data_per_participant = [id_number, trial_number, block, context_change_command, ...
                       context_change_subtype, interference_command, accuracy_rates, RTs, waitRT];
        
            % Append the current dataset to the final matrix
            all_data_experiment1 = [all_data_experiment1; data_per_participant];
           
            % Repeat the whole process for each participant
        end
    
    % When done with extracting data for experiment 1, save it as a mat file
    % for analysis
    save('all_data_experiment1.mat', 'all_data_experiment1');
    
    elseif experiment_handle == 2

            % Experiment 2 data location
            experiment2_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment2/';
        
            all_data_experiment2 = [];

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
                block = [];
                context_change_command = [];
                interference_command = [];
                interference_subtype = [];
                accuracy_rates = [];
                RTs = [];
                waitRT = [];
                interference_accuracy = [];
                current_interference_accuracy = "";
                
                % Define how many trials experiment 2 had
                trial_count = 720;
        
                % Start looking through each trial
                for current_trial = 1:trial_count
                    if mod(current_trial,6) == 1
                        
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = 1;
                        block(end+1,1) = current_csv_table{current_trial, "Var16"};
                        
                        if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 0;
                            interference_subtype(end+1,1) = NaN;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};

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
                            interference_subtype(end+1,1) = NaN;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};

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
                        trial_number(end+1,1) = 5;
                        block(end+1,1) = current_csv_table{current_trial, "Var16"};
                        
                        if current_csv_table{current_trial, "Var4"} == 0 && current_csv_table{current_trial, "Var5"} == 2
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 0;
                            interference_subtype(end+1,1) = NaN;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};

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
                            interference_subtype(end+1,1) = NaN;
                            accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                            RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                            waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};

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
                    elseif mod(current_trial,6) == 2
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = 2;
                        block(end+1,1) = current_csv_table{current_trial, "Var16"};
                        context_change_command(end+1,1) = NaN;
                        
                        interference_command(end+1,1) = NaN;
                        interference_subtype(end+1,1) = NaN;
                        interference_accuracy(end+1,1) = NaN;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    elseif mod(current_trial,6) == 3
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = 3;
                        block(end+1,1) = current_csv_table{current_trial, "Var16"};
                        context_change_command(end+1,1) = NaN;
                        
                        interference_command(end+1,1) = NaN;
                        interference_subtype(end+1,1) = NaN;
                        interference_accuracy(end+1,1) = NaN;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    elseif mod(current_trial,6) == 4
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = 4;
                        block(end+1,1) = current_csv_table{current_trial, "Var16"};
                        context_change_command(end+1,1) = NaN;
                       
                        interference_command(end+1,1) = NaN;
                        interference_subtype(end+1,1) = NaN;
                        interference_accuracy(end+1,1) = NaN;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    elseif mod(current_trial,6) == 0
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = 6;
                        block(end+1,1) = current_csv_table{current_trial, "Var16"};
                        context_change_command(end+1,1) = NaN;
                        
                        interference_command(end+1,1) = NaN;
                        interference_subtype(end+1,1) = NaN;
                        interference_accuracy(end+1,1) = NaN;
                        accuracy_rates(end+1,1) = abs(current_csv_table{current_trial, "Var6"});
                        RTs(end+1,1) = current_csv_table{current_trial, "Var9"};
                        waitRT(end+1,1) = current_csv_table{current_trial, "Var10"};
                    end
                end

            %Combine all the number vectors to construct the participant's dataset
            data_per_participant = [id_number, trial_number, block, context_change_command, ...
                       interference_command, interference_subtype, accuracy_rates, RTs, waitRT, interference_accuracy];
        
            % Append the current dataset to the final matrix
            all_data_experiment2 = [all_data_experiment2; data_per_participant];
    
            % Repeat the whole process for each participant
            end
    
    % When done with extracting data for experiment 2, save it as a mat file
    % for analysis
    save('all_data_experiment2.mat', 'all_data_experiment2');
    
    elseif experiment_handle == 3

        % Experiment 3 data location
        experiment3_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment3_mat/';
    
        all_data_experiment3 = [];

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
            block = [];
            context_change_command = [];
            interference_command = [];
            interference_subtype = [];
            accuracy_rates = [];
            RTs = [];
            waitRT = [];
            interference_accuracy = [];
            current_interference_accuracy = "";
    
            % Define how many trials experiment 3 had
            trial_count = 720;
    
            % Start looking through each trial
            for current_trial = 1:trial_count
                 if mod(current_trial,6) == 1
                        
                        id_number(end+1,1) = current_subject;
                        trial_number(end+1,1) = 1;
                        block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);
                        
                        if current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "No Interference Presented"
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 0;
                            interference_subtype(end+1,1) = NaN;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            interference_accuracy(end+1,1) = 0;
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "Unique Interference"
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
                        
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
                            interference_subtype(end+1,1) = NaN;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            interference_accuracy(end+1,1) = 0;
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) == "Unique Interference"
                            context_change_command(end+1,1) = 1;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
    
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
                        trial_number(end+1,1) = 5;
                        block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);
                        
                        if current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "No Interference Presented"
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 0;
                            interference_subtype(end+1,1) = NaN;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                           RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            interference_accuracy(end+1,1) = 0;
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "No Change" && current_mat_table.dataMatrix(current_trial, 12) == "Unique Interference"
                            context_change_command(end+1,1) = 0;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
    
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
                            interference_subtype(end+1,1) = NaN;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                            interference_accuracy(end+1,1) = 0;
                        elseif current_mat_table.dataMatrix(current_trial, 11) == "Yes Change" && current_mat_table.dataMatrix(current_trial, 12) == "Unique Interference"
                            context_change_command(end+1,1) = 1;
                            interference_command(end+1,1) = 1;
                            interference_subtype(end+1,1) = 1;
                            accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                            RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.2;
                            waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.2;
    
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
    
                            current_interference_accuracy = current_mat_table.dataMatrix(current_trial, 13);
                           
                            if current_interference_accuracy == "Correct"
                                interference_accuracy(end+1,1) = 1;
                            elseif current_interference_accuracy == "Wrong"
                                interference_accuracy(end+1,1) = 0;
                            elseif current_interference_accuracy == "" || current_interference_accuracy == "No Response"
                                interference_accuracy(end+1,1) = 0; % or 0, depending on how you want to treat it
                           
                            end
    
                        end
                    
                 elseif mod(current_trial,6) == 2
                    id_number(end+1,1) = current_subject;
                    trial_number(end+1,1) = 2;
                    block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);
                    context_change_command(end+1,1) = NaN;
                    interference_command(end+1,1) = NaN;
                    interference_subtype(end+1,1) = NaN;
                    accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                    RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                    waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                    interference_accuracy(end+1,1) = NaN;
         
                 elseif mod(current_trial,6) == 3
                    id_number(end+1,1) = current_subject;
                    trial_number(end+1,1) = 3;
                    block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);
                    context_change_command(end+1,1) = NaN;
                    interference_command(end+1,1) = NaN;
                    interference_subtype(end+1,1) = NaN;
                    accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                    RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                    waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                    interference_accuracy(end+1,1) = NaN;
                 
                 elseif mod(current_trial,6) == 4
                    id_number(end+1,1) = current_subject;
                    trial_number(end+1,1) = 4;
                    block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);
                    context_change_command(end+1,1) = NaN;
                    interference_command(end+1,1) = NaN;
                    interference_subtype(end+1,1) = NaN;
                    accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                    RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                    waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                    interference_accuracy(end+1,1) = NaN;
                 
                 elseif mod(current_trial,6) == 0
                    id_number(end+1,1) = current_subject;
                    trial_number(end+1,1) = 6;
                    block(end+1,1) = current_mat_table.dataMatrix(current_trial, 5);
                    context_change_command(end+1,1) = NaN;
                    interference_command(end+1,1) = NaN;
                    interference_subtype(end+1,1) = NaN;
                    accuracy_rates(end+1,1) = abs(str2double(current_mat_table.dataMatrix(current_trial, 14)));
                    RTs(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 15)) - 0.9;
                    waitRT(end+1,1) = str2double(current_mat_table.dataMatrix(current_trial, 16)) - 0.9;
                    interference_accuracy(end+1,1) = NaN;
                 end
            end
        
        
            %Combine all the number vectors to construct the participant's dataset
            data_per_participant = [id_number, trial_number, block, context_change_command, ...
                       interference_command, interference_subtype, accuracy_rates, RTs, waitRT, interference_accuracy];
                       
        
            % Append the current dataset to the final matrix
            all_data_experiment3 = [all_data_experiment3; data_per_participant];
    
            % Repeat the process for each participant
        end

        % When done with extracting data for experiment 3, save it as a mat file
        % for analysis
        save('all_data_experiment3.mat', 'all_data_experiment3');

    end
end
    



%% Do you want to extract surprise data?

if extract_surprise == true
    if experiment_handle == 1

        % Array to store all the values
        all_data_experiment1_surprise = [];

        % Root file address for experiment 1 data 
        experiment1_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment1/';
        
        % Total subject number
        sample_size = 28;

        % Start iterating over each participant data
        for current_surprise_participant = 1:sample_size
            % Generate plugs for data
            csv_plug = ['output_data' num2str(current_subject) '.csv'];
            csv_plug_surprise = ['output_dataSurprise' num2str(current_subject) '.csv'];

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
            id_number_main = [];
            surprise_image_id = []; 
            trial_number_main = [];
            block_main = [];
            context_change_command_main = [];
            context_change_subtype_main = [];
            interference_command_main = [];
            accuracy_rates_main = [];
            accuracy_rates_surprise = [];
            RTs_main = [];
            RTs_surprise = [];
            waitRT_main = [];
            waitRT_surprise = [];
            surprise_recognition_accuracy = [];
            
            current_surprise_recognition_accuracy = 0;
            current_interference_command_main = 0;
            current_context_change_command_main = 0;
            current_context_change_subtype_main = 0;
        
        
            % Experiment 1 presented 240 study images, 120 of which were
            % randomly chosen and used in surprise. First, fetch those
            % chosen images.  
            surprise_images = current_csv_table_surprise(:,"Var5");
        
        
            % Each surprise image has associated performance measures from both the main and the surprise task 
            for current_surprise_image = 1:size(surprise_images)
                % Choose one surprise image to work with
                current_image_name = surprise_images{current_surprise_image, "Var5"};
                % Find where the chosen image is located in the main task dataset 
                matchIdx = find(strcmp(current_csv_table{:, "Var8"}, current_image_name));
    
                % When location is found, first save the following simple
                % values
                id_number_main(end+1,1) = current_surprise_participant;
                surprise_image_id(end+1, 1) = current_surprise_image;
                trial_number_main(end+1,1) = current_csv_table{matchIdx(5), "Var3"};
                block_main(end+1,1) = current_csv_table{matchIdx(5), "Var15"};

                current_context_change_command_main = current_csv_table{matchIdx(5), "Var4"};

                if current_context_change_command_main == 1
                    context_change_command_main(end+1,1) = 1;
                    context_change_subtype_main(end+1,1) = 1;
                elseif current_context_change_command_main == 2
                    context_change_command_main(end+1,1) = 1;
                    context_change_subtype_main(end+1,1) = 2;
                elseif current_context_change_command_main == 0
                    context_change_command_main(end+1,1) = 0;
                    context_change_subtype_main(end+1,1) = NaN;
                end
        
                current_interference_command_main = current_csv_table{matchIdx(5), "Var5"};

                if current_interference_command_main == 1
                    interference_command_main(end+1, 1) = 1;
                elseif current_interference_command_main == 2
                    interference_command_main(end+1, 1) = 0;
                end
                
                % Then, save performance measures of the image in the main task 
                accuracy_rates_main(end+1,1) = abs(current_csv_table{matchIdx(5), "Var6"});
                RTs_main(end+1,1) = current_csv_table{matchIdx(5), "Var9"};
                waitRT_main(end+1,1) = current_csv_table{matchIdx(5), "Var10"};    
        
                % Also, save those measures' counterparts in the surprise
                % task
                accuracy_rates_surprise(end+1,1) = abs(current_csv_table_surprise{current_surprise_image, "Var4"});
                RTs_surprise(end+1,1) = current_csv_table_surprise{current_surprise_image, "Var7"};
                waitRT_surprise(end+1,1) = current_csv_table_surprise{current_surprise_image, "Var8"}; 

                surprise_recognition_accuracy(end+1,1) = current_csv_table_surprise{current_surprise_image, "Var3"}; 

                if surprise_recognition_accuracy(current_surprise_image) == 2
                    surprise_recognition_accuracy(current_surprise_image) = 0;
                end

            end
           
            
            % Combine all the data taken from the current participant
            data_per_participant_surprise = [id_number_main, surprise_image_id, block_main, context_change_command_main, ...
            context_change_subtype_main, interference_command_main, accuracy_rates_main, accuracy_rates_surprise, RTs_main, RTs_surprise, waitRT_main, ...
            waitRT_surprise, surprise_recognition_accuracy];
            
            % Add the individual's data to the general dataset
            all_data_experiment1_surprise = [all_data_experiment1_surprise; data_per_participant_surprise];

            % Repeat for each participant
        end

    % When done with extracting data for experiment 1, save it as a mat file
    % for analysis
    save('all_data_experiment1_surprise.mat', 'all_data_experiment1_surprise');

    elseif experiment_handle == 2

        % Array to store all the values
        all_data_experiment2_surprise = [];

        % Root file address for experiment 2 data 
        experiment2_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment2/';
        
        % Total subject number
        sample_size = 54;

        for current_surprise_participant = 1:sample_size
        
            % Generate plugs for data
            csv_plug = ['output_data' num2str(current_subject) '.csv'];
            csv_plug_surprise = ['output_dataSurprise' num2str(current_subject) '.csv'];

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
            id_number_main = [];
            surprise_image_id = []; 
            trial_number_main = [];
            block_main = [];
            context_change_command_main = [];
            interference_command_main = [];
            interference_subtype_main = [];
            accuracy_rates_main = [];
            accuracy_rates_surprise = [];
            RTs_main = [];
            RTs_surprise = [];
            waitRT_main = [];
            waitRT_surprise = [];
            interference_accuracy = [];
            surprise_recognition_accuracy = [];

            current_interference_accuracy = "";
            current_surprise_recognition_accuracy = 0;
            current_context_command_main = 0;
            current_interference_command_main = 0;
           
    
            % Make a list of the images used in surprise
            surprise_images = current_csv_table_surprise(1:120, "Var5");

        
            % Iterate over each surprise image
            for current_surprise_image = 1:size(surprise_images)
                current_image_name = surprise_images{current_surprise_image, "Var5"};
                matchIdx = find(strcmp(current_csv_table{:, "Var8"}, current_image_name));
    
        
                id_number_main(end+1,1) = current_surprise_participant;
                surprise_image_id(end+1, 1) = current_surprise_image;
                trial_number_main(end+1,1) = current_csv_table{matchIdx(5), "Var3"};
                block_main(end+1,1) = current_csv_table{matchIdx(5), "Var16"};
                
                current_context_change_command_main = current_csv_table{matchIdx(5), "Var4"};               
                
                if current_context_change_command_main == 2
                    context_change_command_main(end+1, 1) = 1;
                elseif current_context_change_command_main == 0
                    context_change_command_main(end+1, 1) = 0;
                end
                
                current_interference_command_main = current_csv_table{matchIdx(5), "Var5"};

                if current_interference_command_main == 2
                    interference_command_main(end+1, 1) = 0;
                    interference_subtype_main(end+1, 1) = NaN;
                elseif (current_interference_command_main == 1 && current_csv_table{matchIdx(5), "Var13"} == "Left Interference") || (current_interference_command_main == 1 && current_csv_table{matchIdx(5), "Var15"} == "Left Interference")
                    interference_command_main(end+1, 1) = 1;
                    interference_subtype_main(end+1, 1) = 2;
                elseif (current_interference_command_main == 1 && current_csv_table{matchIdx(5), "Var13"} == "Right Interference") || (current_interference_command_main == 1 && current_csv_table{matchIdx(5), "Var15"} == "Right Interference")
                    interference_command_main(end+1, 1) = 1;
                    interference_subtype_main(end+1, 1) = 1;
                end

                accuracy_rates_main(end+1,1) = abs(current_csv_table{matchIdx(5), "Var6"});
                RTs_main(end+1,1) = current_csv_table{matchIdx(5), "Var9"};
                waitRT_main(end+1,1) = current_csv_table{matchIdx(5), "Var10"};    
        
                accuracy_rates_surprise(end+1,1) = abs(current_csv_table_surprise{current_surprise_image, "Var4"});
                RTs_surprise(end+1,1) = current_csv_table_surprise{current_surprise_image, "Var7"};
                waitRT_surprise(end+1,1) = current_csv_table_surprise{current_surprise_image, "Var8"};
    
                current_interference_accuracy = current_csv_table{matchIdx(5), "Var11"};
    
                if current_interference_accuracy == "Left Selection" && (current_csv_table{matchIdx(5), "Var13"} == "Left Interference" || current_csv_table{matchIdx(5), "Var15"} == "Left Interference") 
                    interference_accuracy(end+1,1) = 1;
                elseif current_interference_accuracy == "Right Selection" && (current_csv_table{matchIdx(5), "Var13"} == "Right Interference" || current_csv_table{matchIdx(5), "Var15"} == "Right Interference") 
                    interference_accuracy(end+1,1) = 1;
                elseif current_csv_table{matchIdx(5), "Var13"} == "No Interference" || current_csv_table{matchIdx(5), "Var15"} == "No Interference"
                    interference_accuracy(end+1,1) = NaN;
                else
                    interference_accuracy(end+1,1) = 0;
                end


                surprise_recognition_accuracy(end+1,1) = current_csv_table_surprise{current_surprise_image, "Var3"}; 

                if surprise_recognition_accuracy(current_surprise_image) == 2
                    surprise_recognition_accuracy(current_surprise_image) = 0;
                end
            end
            
            % Combine all the data taken from the current participant
            data_per_participant_surprise = [id_number_main, surprise_image_id, block_main, context_change_command_main, ...
            interference_command_main, interference_subtype_main, accuracy_rates_main, accuracy_rates_surprise, RTs_main, RTs_surprise, waitRT_main, ...
            waitRT_surprise, surprise_recognition_accuracy];
            
            
            % Add the individual's data to the general dataset
            all_data_experiment2_surprise = [all_data_experiment2_surprise; data_per_participant_surprise];
      
            % Repeat for each participant
        end
    
    % When done with extracting data for experiment 1, save it as a mat file
    % for analysis
    save('all_data_experiment2_surprise.mat', 'all_data_experiment2_surprise');

    
    elseif experiment_handle == 3
        
        all_data_experiment3_surprise = [];

        % Root file address for experiment 1 data 
        experiment3_data_dir = '/Users/ali/Desktop/visual imperil project/visuals imperil protect - CODE, STIMULI AND MORE/data_experiment3_mat/';
        
        % Total subject number
        sample_size = 53;

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
                continue;
            end
        
            % Load files
            current_mat_table_surprise = load(current_data_dir_surprise);
            current_mat_table = load(current_data_dir);
                      
    
            %%Create number vectors to store data/ Empty the contents for the next participant
            current_change_value = ""; 
            current_interference_value = ""; 
            current_interference_accuracy = "";
            
            id_number_main = [];
            surprise_image_id = []; 
            trial_number_main = [];
            block_main = [];
            context_change_command_main = [];
            interference_command_main = [];
            interference_subtype_main = [];
            accuracy_rates_main = [];
            accuracy_rates_surprise = [];
            RTs_main = [];
            RTs_surprise = [];
            waitRT_main = [];
            waitRT_surprise = [];
            interference_accuracy = [];
            surprise_recognition_accuracy = [];
            studied_before = [];
    
    
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
            for current_surprise_image = 1:size(surprise_target_images)
                current_image_name = surprise_target_images(current_surprise_image, 1);
    
                % Find which row the current surprise image appears in the main
                % dataset
                matchIdx = find(strcmp(current_mat_table.dataMatrix(:, 8), current_image_name) | strcmp(current_mat_table.dataMatrix(:, 6), current_image_name));
    
                if current_mat_table.dataMatrix(matchIdx(5), 10) == current_image_name
                    studied_before(end+1,1) = 1;
                else
                    studied_before(end+1,1) = 0;
                end

                % Store ID, Trial and Block info from the main dataset
                id_number_main(end+1,1) = current_surprise_participant;
                surprise_image_id(end+1,1) = current_surprise_image;
                trial_number_main(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 3));
                block_main(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 5));
    
                % Since change commands are saved as strings, convert to numeric
                % values
                current_change_value = current_mat_table.dataMatrix(matchIdx(5), 11);
                if current_change_value == "No Change"
                    context_change_command_main(end+1,1) = 0;
                elseif current_change_value == "Yes Change"
                    context_change_command_main(end+1,1) = 1;
                end
    
                % Since interference commands are saved as strings, convert to numeric
                % values
                current_interference_value = current_mat_table.dataMatrix(matchIdx(5), 12);
                if current_interference_value == "No Interference Presented"
                    interference_command_main(end+1,1) = 0;
                    interference_subtype_main(end+1, 1) = NaN;
                    RTs_main(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 15)) - 0.9;
                    waitRT_main(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 16)) - 0.9;
                elseif current_interference_value == "Unique Interference" % All RGBs are unique
                    interference_command_main(end+1,1) = 1;
                    interference_subtype_main(end+1, 1) = 1;
                    RTs_main(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 15)) - 0.2;
                    waitRT_main(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 16)) - 0.2;

                elseif current_interference_value == "Different Interference" % Two RGBs repeat
                    interference_command_main(end+1,1) = 1;
                    interference_subtype_main(end+1, 1) = 2;
                    RTs_main(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 15)) - 0.2;
                    waitRT_main(end+1,1) = str2double(current_mat_table.dataMatrix(matchIdx(5), 16)) - 0.2;
                end
    
                % Fetch ACC and RTs from the main task
                accuracy_rates_main(end+1,1) = abs(str2double(current_mat_table.dataMatrix(matchIdx(5), 14)));
               
        
                % Fetch ACC and RTs for the same image from the surprise task
                accuracy_rates_surprise(end+1,1) = abs(str2double(current_mat_table_surprise.dataMatrix2(current_surprise_image, 4)));
                RTs_surprise(end+1,1) = str2double(current_mat_table_surprise.dataMatrix2(current_surprise_image, 7));
                waitRT_surprise(end+1,1) = str2double(current_mat_table_surprise.dataMatrix2(current_surprise_image, 8)); 
    
                % Find interference decisions and convert to numeric values
                current_interference_accuracy = current_mat_table.dataMatrix(matchIdx(5), 13);
                if current_interference_accuracy == "No Interference Selected"
                    interference_accuracy(end+1,1) = NaN;
                elseif current_interference_accuracy == "Correct"
                    interference_accuracy(end+1,1) = 1;
                elseif current_interference_accuracy == "Wrong"
                    interference_accuracy(end+1,1) = 0;  
                elseif current_interference_accuracy == "" || current_interference_accuracy == "No Response"
                    interference_accuracy(end+1,1) = 0; % or 0, depending on how you want to treat it       
                end

                surprise_recognition_accuracy(end+1,1) = str2double(current_mat_table_surprise.dataMatrix2(current_surprise_image, 3)); 
                    
                if surprise_recognition_accuracy(current_surprise_image) == 2
                    surprise_recognition_accuracy(current_surprise_image) = 0;
                end
            end
            
            
            %Combine all the number vectors to construct the participant's dataset
            data_per_participant_surprise = [id_number_main, surprise_image_id, block_main, context_change_command_main, ...
            interference_command_main, interference_subtype_main, accuracy_rates_main, accuracy_rates_surprise, RTs_main, RTs_surprise, waitRT_main, ...
            waitRT_surprise, surprise_recognition_accuracy, studied_before];
            
            % Add each participant's dataset to the existing one
            all_data_experiment3_surprise = [all_data_experiment3_surprise; data_per_participant_surprise];
        end

        % When done with extracting data for experiment 3, save it as a mat file
        % for analysis
        save('all_data_experiment3_surprise.mat', 'all_data_experiment3_surprise');
    end
end

% Example setup
column_index = 4;     
column_index2 = 5;
column_index3 = 6; % the column to search in
value_to_count = 0;    % the numeric value you're looking for
value_to_count2 = 1;
value_to_count3 = 2;

% Count how many times it appears
count1 = sum((data_per_participant_surprise(:, column_index) == value_to_count) & ...
             (data_per_participant_surprise(:, column_index2) == value_to_count));
disp(["context: 0 and interference: 0", count1]);

count2 = sum((data_per_participant_surprise(:, column_index) == value_to_count2) & ...
             (data_per_participant_surprise(:, column_index2) == value_to_count));
disp(["context: 1 and interference: 0", count2]);

count3 = sum((data_per_participant_surprise(:, column_index) == value_to_count) & ...
             (data_per_participant_surprise(:, column_index3) == value_to_count3));
disp(["context: 0 and interference: 1", count3]);

count4 = sum((data_per_participant_surprise(:, column_index) == value_to_count2) & ...
             (data_per_participant_surprise(:, column_index3) == value_to_count3));
disp(["context: 1 and interference: 1", count4]);
