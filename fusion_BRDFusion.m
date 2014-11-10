% fusion_BRDFusion.m
% Version 6.1
% Step 4
% Fusion With BRDF Correction
%
% Project: Fusion
% By Qinchuan Xin
% Updated By: Xiaojing Tang
% Created On: Unknown
% Last Update: 10/3/2014
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
% Version 6.0 - Unknown
%   This script generage MODIS swath data based on Landsat synthetic data
%       with BRDF correction.
%
% Updates of Version 6.1 - 10/3/2014 (by Xiaojing Tang)
%   1.Updated comments.
%   2.Changed coding style.
%   3.Modified for work flow of fusion version 6.1.
%   4.Changed from script to function
%   5.Modified the code to incorporate the use of fusion_inputs structure.
%
%----------------------------------------------------------------
%
function fusion_BRDFusion(main)

    % check if BRDF option is checked
    if main.set.brdf == 0
        return
    end

    [Samp,Line] = meshgrid(main.etm.sample,main.etm.line);
    ETMGeo.Northing = main.etm.ulNorth-Line*30+15;
    ETMGeo.Easting = main.etm.ulEast +Samp*30-15;
    [ETMGeo.Lat,ETMGeo.Lon] = utm2deg(ETMGeo.Easting,ETMGeo.Northing,main.etm.utm);
    ETMGeo.Line = main.etm.line;
    ETMGeo.Samp = main.etm.sample;

    % MOD09 Swath Info
    % FileName.Day=datenum(2000,9,27);	% nadir image
    % FileName.Day=datenum(2000,9,12);	% two images
    % FileName.Day=datenum(2000,9,17);	% off-nadir image

    % start timer
    tic;
    
    % loop through all etm images
    for I_Day = 1:numel(main.date.swath)
        
        % get date information of all images
        Day = main.date.etm(I_Day);
        DayStr = num2str(Day);

        % check if result already exist
        File.Check = dir([main.output.modsubbrdf '*' DayStr '*']);
        if numel(File.Check) >= 1
            disp([DayStr ' already exist, skip this date.']);
            continue;
        end
        
        % read ETM
        File.ETM = dir([main.input.etm,'*',DayStr,'*.hdr']);
        if  numel(File.ETM) ~= 1
            disp(['Cannot find ETM for Julian Day: ', DayStr]);     
            continue;
        end

        % find ETM BRDF files
        File.ETMBRDF = dir([main.output.etmBRDF,'ETMBRDF_A',DayStr,'*.hdr']);
        if  numel(File.ETMBRDF)~=1
            disp(['Cannot find ETMBRDF for Julian Day: ', DayStr]);
            continue;
        end   

        % read brdf coefficients
        ETMBRDF = multibandread([main.output.etmBRDF,File.ETMBRDF.name(1:(length(File.ETMBRDF.name)-4))],...
            [numel(main.etm.line),numel(mainetm.sample),main.etm.band],'int16',0,'bsq','ieee-le');
        ETMBRDF(ETMBRDF<=0) = nan;
        ETMBRDF = ETMBRDF/1000;

        % read ETM
        File.ETM = dir([main.input.etm,'*',DayStr,'*.hdr']);
        if  numel(File.ETM) ~= 1
            disp(['Cannot find ETM for Julian Day: ', DayStr]);     
            continue;
        end

        ETM = multibandread([main.input.etm,File.ETM.name(1:(length(File.ETM.name)-4))],...
            [numel(main.etm.line),numel(main.etm.sample),main.etm.band],'int16',0,main.etm.interleave,'ieee-le');
        ETM(ETM>10000) = nan;
        ETM(ETM<1) = nan;
        
        % apply brdf coefficients
        ETMBLU = ETM(:,:,1).*ETMBRDF(:,:,1);
        ETMGRE = ETM(:,:,2).*ETMBRDF(:,:,2);
        ETMRED = ETM(:,:,3).*ETMBRDF(:,:,3);
        ETMNIR = ETM(:,:,4).*ETMBRDF(:,:,4);
        ETMSWIR = ETM(:,:,5).*ETMBRDF(:,:,5);
        ETMSWIR2 = ETM(:,:,6).*ETMBRDF(:,:,6);

        % find modsub
        File.MOD09SUB = dir([main.output.modsub,'MOD09SUB.',num2str(main.set.res),'*',DayStr,'*']);

        if numel(File.MOD09SUB)<1
            disp(['Cannot find MOD09SUB for Julian Day: ', DayStr]);
            continue;
        end

        % loop through MOD09SUB file of current date
        for I_TIME = 1:numel(File.MOD09SUB)
            TimeStr = regexp(File.MOD09SUB(I_TIME).name,'\.','split');
            TimeStr = char(TimeStr(4));

            % load MOD09SUB
            MOD09SUB = load([main.output.modsub,File.MOD09SUB(I_TIME).name]);

            % fusion
            MOD09SUB.FUSB9BLU = etm2swath(ETMBLU,MOD09SUB,ETMGeo);
            MOD09SUB.FUSB9GRE = etm2swath(ETMGRE,MOD09SUB,ETMGeo);
            MOD09SUB.FUSB9RED = etm2swath(ETMRED,MOD09SUB,ETMGeo);
            MOD09SUB.FUSB9NIR = etm2swath(ETMNIR,MOD09SUB,ETMGeo);
            MOD09SUB.FUSB9SWIR = etm2swath(ETMSWIR,MOD09SUB,ETMGeo);
            MOD09SUB.FUSB9SWIR2 = etm2swath(ETMSWIR2,MOD09SUB,ETMGeo);

            % save
            save([main.output.modsubbrdf,'MOD09SUBFB.',RESSTR,'m.',DayStr,'.',TimeStr,'.mat'],'-struct','MOD09SUB');
            disp(['Done with ',DayStr,' in ',num2str(toc,'%.f'),' seconds']);
        end
    end

    % done
    
end
