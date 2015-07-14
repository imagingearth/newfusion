% fusion_GenMap.m
% Version 1.0.1
% Step 9
% Generate Map

% Project: New Fusion
% By xjtang
% Created On: 7/7/2014
% Last Update: 7/7/2015
%
% Input Arguments: 
%   main (Structure) - main inputs of the fusion process generated by fusion_inputs.m.
%   
% Output Arguments: NA
%
% Instruction: 
%   1.Customize a config file for your project.
%   2.Run fusion_Inputs() first and get the returned structure of inputs
%   3.Run previous steps first to make sure required data are already generated.
%   4.Run this function with the stucture of inputs as the input argument.
%
% Version 1.0 - 7/7/2015
%   This script generates change map in envi format based on fusion result.
%
% Updates of Version 1.0.1 - 7/13/2015
%   1.Added a new type of map.
%
% Created on Github on 7/7/2015, check Github Commits for updates afterwards.
%----------------------------------------------------------------

function fusion_GenMap(main)
    
    % initialize
    MAP = ones(length(main.etm.line),length(main.etm.sample))*-9999;
    
    % start timer
    tic;
    
    % line by line processing
    for i = (main.etm.line)'
        
        % check if result exist
        File.Check = dir([main.output.chgmat 'ts.r' num2str(i) '.chg.mat']);
        if numel(File.Check) == 0
            disp([num2str(i) ' line cache does not exist, skip this line.']);
            continue;  
        end
        
        % read input data
        CHG = load([main.output.chgmat 'ts.r' num2str(i) '.chg.mat']);
        
        % processing
        for j = main.etm.sample
            
            % subset data
            X = squeeze(CHG.Data(j,:));
            
            % see if this pixel is eligible
            if max(X) <= 0
                continue
            end
            
            % assign result
            MAP(i,j) = genMap(X,CHG.Date,main.set.map,[main.model.chgedge,main.model.nonfstedge]);
            
        end 
        
        % clear processed line
        clear 'CHG';
        
        % show progress
        disp(['Done with line ',num2str(i),' in ',num2str(toc,'%.f'),' seconds']);
        
    end
    
    % determine file name
    if main.set.map == 1
        outFile = [main.output.chgmap 'DateOfChange'];
    elseif main.set.map == 2
        outFile = [main.output.chgmap 'MonthOfChange'];
    elseif main.set.map == 3
        outFile = [main.output.chgmap 'ClassMap'];
    elseif main.set.map == 4
        outFile = [main.output.chgmap 'ChangeOnly'];
    else
        outFile = [main.output.chgmap 'Unknown'];
    end
    
    % see if file already exist
    if exist(outFile,'file')
        disp('Output file already exist, overwrite.')
        system(['rm ',outFile,'*']);
    end
    
    % export map
    enviwrite(outFile,MAP,[main.etm.ulEast,main.etm.ulNorth],main.etm.utm,3,[30,30],'bsq');
    
    % done
    
end

