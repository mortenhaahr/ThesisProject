modelName = 'water_system_electrical_model';

parms = struct("Voltage", 1, "KSink_R", 1, "MainPipe_R", [0, 1]);
simOutputs = run_simulations(modelName, "10", parms);

% Create a new figure
figure;
% Loop through each SimulationOutput in the simOut vector
for i = 1:numel(simOutputs)
    Main_F = simOutputs(i).logsout.getElement("Main_F");
    Main_P = simOutputs(i).logsout.getElement("MainPipe_P");

    plot(Main_F.Values, 'DisplayName', ['Simulation ' num2str(i)]);

    hold on; % Keep the current plot open
end

% Add labels, title, and legend
xlabel('Time');
ylabel('Output Signal');
title('Simulation Output Plot');
grid on;
legend('Location', 'best'); % Display the legend

% Turn off hold to prevent further data from being added to the plot
hold off;

% disp(parms);
% disp("Max: " + num2str(max(outputData.Values)));

function res = run_simulations(modelName, stopTime, parms)
% Runs one or more simumlations with the given modelName and for the given
% stopTime. Uses the paramaters as indicated in the parms struct.
% Will run the combinations if attributes in parms are arrays.
% The available parameters can be seen in "do_simulation"

% Conf stuff:
open_system(modelName);
oldConf = getActiveConfigSet(modelName);
simConfig = copy(oldConf);
set_param(simConfig,"Name","GrundfosTestSetup","StopTime", stopTime);
attachConfigSet(modelName, simConfig, true);
setActiveConfigSet(modelName, simConfig.Name);
simIn = Simulink.SimulationInput(modelName);

combinations = struct_to_combination_structs(parms);

for i = 1:length(combinations)
    res(i) = do_simulation(simIn, combinations(i));
end
end

function res = do_simulation(simIn, parms)
defaultValues = struct( "Voltage", 1, ...
                        "MainPipe_R", 0, "MainPipe_CStart", 0, "MainPipe_CEnd", 0, "MainPipe_L", 0, ...
                        "MainLeakage_R", 0, ...
                        "KPipe_R", 0, "KPipe_CStart", 0, "KPipe_CEnd", 0, "KPipe_L", 0, ...
                        "KWM_R", 0, ...
                        "KSink_R", 0, ...
                        "BPipe1_R", 0, "BPipe1_CStart", 0, "BPipe1_CEnd", 0, "BPipe1_L", 0, ...
                        "BPipe2_R", 0, "BPipe2_CStart", 0, "BPipe2_CEnd", 0, "BPipe2_L", 0, ...
                        "BSink_R", 0, ...
                        "BShower_R", 0, ...
                        "BToilet_R", 0, ...
                        "BLeakage_R", 0, ...
                        "GPipe1_R", 0, "GPipe1_CStart", 0, "GPipe1_CEnd", 0, "GPipe1_L", 0, ...
                        "GPipe2_R", 0, "GPipe2_CStart", 0, "GPipe2_CEnd", 0, "GPipe2_L", 0, ...
                        "GHose_R", 0, ...
                        "GLeakage_R", 0);

defaultNames = fieldnames(defaultValues);
for i = 1:numel(defaultNames)
    name = defaultNames{i};
    if isfield(parms, name)
        val = parms.(name);
    else
        val = defaultValues.(name);
    end
    simIn = setVariable(simIn,name,val);
end
res = sim(simIn);
end

function res = struct_to_combination_structs(struc)
% Takes a struct where some of the attributes are arrays and returns an
% array of structs where the attributes are scalars.

fieldNames = fieldnames(struc);
fieldValues = struct2cell(struc);

% Generate combinations for each field
combinations = combvec(fieldValues{:})';

% Initialize a cell array to store structs
combinationsArray = cell(size(combinations, 1), 1);

% Convert combinations to an array of structs
for i = 1:size(combinations, 1)
    newStruct = struct();
    for j = 1:numel(fieldNames)
        newStruct.(fieldNames{j}) = combinations(i, j);
    end
    combinationsArray{i} = newStruct;
end

% Convert the cell array to a structure array
res = [combinationsArray{:}];
end