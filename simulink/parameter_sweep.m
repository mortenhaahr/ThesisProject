% PipeC_vals = [0.1, 1, 10, 100];
% PipeL_vals = [0.1, 1, 10, 100];
% PipeL_vals = [7.65e-2];

modelName = 'water_system_electrical_model';
open_system(modelName);
oldConf = getActiveConfigSet(modelName);
simConfig = copy(oldConf);
set_param(simConfig,"Name","GrundfosTestSetup","StopTime","20");
attachConfigSet(modelName, simConfig, true);
setActiveConfigSet(modelName, simConfig.Name);


parms = struct("PipeR", [10, 100], "PipeC", [0.1, 1]);
simOutputs = run_simulations(modelName, "10", parms);

% Create a new figure
figure;
% Loop through each SimulationOutput in the simOut vector
for i = 1:numel(simOutputs)
    % Extract time and output data for each simulation
    outputData = simOutputs(i).logsout.getElement("PipingPressure");

    % Plot the data with a unique line style for each simulation
    % ' PipeL: ' num2str(PipeL_vals(i))
    plot(outputData.Values, 'DisplayName', ['Simulation ' num2str(i)]);

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
defaultValues = struct("PipeR", 1, "PipeC", 1, "PipeL", 1, "PipeCOn", false, "PipeLOn", false);

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