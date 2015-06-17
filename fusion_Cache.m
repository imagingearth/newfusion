% fusion_Cache.m
% Version 1.0
% Step 7
% Write Output
%
% Project: Fusion
% By Xiaojing Tang
% Created On: 6/15/2015
% Last Update: 6/16/2015
%
% Input Arguments: 
%   main (Structure) - main inputs of the fusion process generated by
%     fusion_inputs.m.
%
% Output Arguments: NA
%
% Usage: 
%   1.Customize the main input file (fusion_inputs.m) w     ith proper settings
%       for specific project.
%   2.Run fusion_Inputs() first and get the returned structure of inputs
%   3.Run previous steps first to make sure required data are already
%       generated.
%   4.Run this function with the stucture of inputs as the input argument.
%
% Version 1.0 - 6/16/2015
%   This script caches the Landsat style fusion time series into mat files.
%
% Released on Github on 6/15/2015, check Github Commits for updates afterwards.
%----------------------------------------------------------------

function fusion_Cache(main)

    % get ETM image size
    samp = length(main.etm.sample);
    line = length(main.etm.line);
    nband = main.etm.band;
    dates = main.date.etm;
    
    % calculate the lines that will be processed by this job
    njob = main.set.job(2);
    thisjob = main.set.job(1);
    if njob > 1 && thisjob > 1 
        % subset lines
        start = thisjob;
        stop = floor(line/njob);
        curLine = start:njob:stop;
    end
    
    % line by line processing
    for i = curLine
        
        % initialize
        TS = ones(samp,length(dates),nband);
        
        % loop through images
        
        
        
        % work on individual pixel
        for j = 1:samp
        
        
        
        
        
        end
            
            
    end
        

    
end