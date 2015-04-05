% fusion_WriteETM.m
% Version 1.2
% Step 6
% Output Result
%
% Project: Fusion
% By Xiaojing Tang
% Created On: 1/28/2015
% Last Update: 4/3/2015
%
% Input Arguments: 
%   main (Structure) - main inputs of the fusion process generated by
%     fusion_inputs.m.
%
% Output Arguments: NA
%
% Usage: 
%   1.Customize the main input file (fusion_inputs.m) with proper settings
%       for specific project.
%   2.Run fusion_Inputs() first and get the returned structure of inputs
%   3.Run previous steps first to make sure required data are already
%       generated.
%   4.Run this function with the stucture of inputs as the input argument.
%
% Version 1.0 - 1/28/2015
%   This script save DIF and Change image into ETM scale.
%   This script saves the results as an ETM image in ENVI format.
%
% Updates of Version 1.1 - 2/7/2015
%   1.Bugs Fixed.
%   2.Operational.
%
% Updates of Version 1.1.1 - 2/10/2015
%   1.Adjusted output structure that fits CCDC style.
%
% Updates of Version 1.1.2 - 4/2/2015
%   1.Implemented a new option
%   2.Fixed the file name bug.
%   3.nob band is removed
%
% Updates of Version 1.2 - 4/3/2015
%   1.Combined 250 and 500 fusion.
%
% Released on Github on 1/30/2015, check Github Commits for updates afterwards.
%----------------------------------------------------------------

function fusion_WriteETM(main)

    % calculate pixel center coordinates
    [Samp,Line] = meshgrid(main.etm.sample,main.etm.line);
    ETMGeo.Northing = main.etm.ulNorth-Line*30+15;
    ETMGeo.Easting = main.etm.ulEast +Samp*30-15;
    [ETMGeo.Lat,ETMGeo.Lon] = utm2deg(ETMGeo.Easting,ETMGeo.Northing,main.etm.utm);
    ETMGeo.Line = main.etm.line;
    ETMGeo.Samp = main.etm.sample;

    % start timer
    tic;
          
    % check platform
    plat = main.set.plat;
    
    % loop through all etm images
    for I_Day=1:numel(main.date.swath)
        
        % get date information of all images
        Day = main.date.swath(I_Day);
        DayStr = num2str(Day);

        % check if result already exist
        File.Check = dir([main.output.dif plat '*' 'ALL' '*' DayStr '*']);
        if numel(File.Check) >= 1
            disp([DayStr ' already exist, skip this date.']);
            continue;
        end

        % find MOD09SUB files
        File.MOD09SUB = dir([main.output.modsubd,plat,'09SUBD.','ALL','*',DayStr,'*']);

        if numel(File.MOD09SUB)<1
            disp(['Cannot find MOD09SUB for Julian Day: ', DayStr]);
            continue;
        end

        % loop through MOD09SUB file of current date
        for I_TIME = 1:numel(File.MOD09SUB)
            TimeStr = regexp(File.MOD09SUB(I_TIME).name,'\.','split');
            TimeStr = char(TimeStr(4));

            % load MOD09SUB
            MOD09SUB = load([main.output.modsubd,File.MOD09SUB(I_TIME).name]);

            % initialize ETM image
            ETMImage = 0*ones([numel(ETMGeo.Line),numel(ETMGeo.Samp),8]);
            
            % generate ETM scale dif map
            if main.set.dif == 0
                [~,ETMImage(:,:,1),~] = swath2etm(MOD09SUB.DIF09BLU500,MOD09SUB,ETMGeo,500);
                [~,ETMImage(:,:,2),~] = swath2etm(MOD09SUB.DIF09GRE500,MOD09SUB,ETMGeo,500);
                [~,ETMImage(:,:,3),~] = swath2etm(MOD09SUB.DIF09RED250,MOD09SUB,ETMGeo,250);
                [~,ETMImage(:,:,4),~] = swath2etm(MOD09SUB.DIF09NIR250,MOD09SUB,ETMGeo,250);
                [~,ETMImage(:,:,5),~] = swath2etm(MOD09SUB.DIF09SWIR500,MOD09SUB,ETMGeo,500);
                [~,ETMImage(:,:,6),~] = swath2etm(MOD09SUB.DIF09SWIR2500,MOD09SUB,ETMGeo,500);
                [~,ETMImage(:,:,7),~] = swath2etm(MOD09SUB.DIF09NDVI250,MOD09SUB,ETMGeo,250);
                [~,ETMImage(:,:,8),~] = swath2etm(MOD09SUB.QACloud250,MOD09SUB,ETMGeo,250);
            else
                [~,~,ETMImage(:,:,1)] = swath2etm(MOD09SUB.DIF09BLU500,MOD09SUB,ETMGeo,500);
                [~,~,ETMImage(:,:,2)] = swath2etm(MOD09SUB.DIF09GRE500,MOD09SUB,ETMGeo,500);
                [~,~,ETMImage(:,:,3)] = swath2etm(MOD09SUB.DIF09RED250,MOD09SUB,ETMGeo,250);
                [~,~,ETMImage(:,:,4)] = swath2etm(MOD09SUB.DIF09NIR250,MOD09SUB,ETMGeo,250);
                [~,~,ETMImage(:,:,5)] = swath2etm(MOD09SUB.DIF09SWIR500,MOD09SUB,ETMGeo,500);
                [~,~,ETMImage(:,:,6)] = swath2etm(MOD09SUB.DIF09SWIR2500,MOD09SUB,ETMGeo,500);
                [~,~,ETMImage(:,:,7)] = swath2etm(MOD09SUB.DIF09NDVI250,MOD09SUB,ETMGeo,250);
                [~,ETMImage(:,:,8),~] = swath2etm(MOD09SUB.QACloud250,MOD09SUB,ETMGeo,250);
            end

            % clean up
            Temp = ETMImage(:,:,8);
            Temp(Temp>0) = 1;
            ETMImage(:,:,8) = Temp;
            Temp = ETMImage(:,:,7);
            Temp(Temp~=-9999) = Temp(Temp~=-9999)*1000;
            ETMImage(:,:,7) = Temp;
            ETMImage = int16(ETMImage);
   
            % save as ENVI imsge
            mkdir([main.output.dif,plat,'DIF','ALL',DayStr,'T',TimeStr]);
            enviwrite([main.output.dif,plat,'DIF','ALL',DayStr,'T',TimeStr,...
                '/',plat,'DIF','ALL',DayStr,'T',TimeStr,'_stack'],...
                ETMImage,[main.etm.ulEast,main.etm.ulNorth],main.etm.utm);
            disp(['Done with ',DayStr,' in ',num2str(toc,'%.f'),' seconds']);
            
        end
    end

    % done
    
end
