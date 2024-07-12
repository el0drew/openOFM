function [data,walkDir] = getDir(data,ch)

% [data,dir] = GETDIR(data,ch) determines the global axis and direction of
% walking
%
% ARGUMENTS
%  data    ... Zoo data
%  ch      ... Channel to use to determine direction. Default 'SACR'
%
% RETURNS
%  data    ... Zoo data with direction information added to 'data.MetaInformation.CompInfo.Direction'
%  walkDir ... Main direction of motion
%
% NOTES
% - Axis of walking direction (I or J) chosen based on axis with greatest average velocity
% - Direction ('neg' or 'pos') based on whether average velocity is negative or positive


% Revision History
%
% updated November 2012
%
% updated Jan 8th
% - compliant with MetaInformation v1.1
%
% Updated June 2016
% - any channel can be used to determine direction. Not just SACR. It is recommended
%   that a trunk or pelvis marker should be used
%
% Updated September 2016
% - Can track motion along x or y
% - z direction motion not supported
%
% Updated June 2017
% - Identifies correct direction for static trials
%
% Updated Oct 2017
% - Error check for files without 'OtherMetaInfo' in MetaInformation
%
% Updated Dec 2017
% - Bug fix for some Qualysis systems
% - Bug fix for PiG data with 'RPSI/LPSI' instead of 'SACR'

% Error Check / Set defaults
%
if nargin==1
    if isfield(data,'LPSI') && ~isfield(data,'SACR')
        vec = (data.LPSI + data.RPSI)/2;
    elseif isfield(data,'SACR')
        vec = data.SACR;
    else
        error('getDir works with PiG data using SACR or L/R PSI markers')
    end
else
    vec = data.(ch);
end

% determine type of trial
%
if isfield(data.MetaInformation,'OtherMetaInfo')
    static=false;
else
    static=true;
end
%     if isfield(data.MetaInformation.OtherMetaInfo.Parameter,'MANUFACTURER')
%         if isfield(data.MetaInformation.OtherMetaInfo.Parameter.MANUFACTURER,'Company')
%             company = strjoin(data.MetaInformation.OtherMetaInfo.Parameter.MANUFACTURER.Company.data,'');
%         elseif isfield(data.MetaInformation.OtherMetaInfo.Parameter.MANUFACTURER,'COMPANY')
%             
%             if isfield(data.MetaInformation.OtherMetaInfo.Parameter.MANUFACTURER.COMPANY,'data')
%                 
%                 company = strjoin(data.MetaInformation.OtherMetaInfo.Parameter.MANUFACTURER.COMPANY.data,'');
%             else
%                 company =  strjoin(data.MetaInformation.OtherMetaInfo.Parameter.MANUFACTURER.COMPANY.info.values,'');
%             end
%             
%         else
%             company = 'unknown';
%         end
%     else
%         company = 'unknown';
%     end
%     
%     if strfind(company, 'Qualisys')
%         static = '';
%     elseif isempty(strfind(company,'AnalysisCorp'))
%         if isfield(data.MetaInformation.OtherMetaInfo.Parameter.SUBJECTS.IS_STATIC, 'data')
%             static = data.MetaInformation.OtherMetaInfo.Parameter.SUBJECTS.IS_STATIC.data;
%         else
%             static = '';
%         end
%     else
%         if isfield(data.MetaInformation.CompInfo,'TrialType')
%             trialType = lower(data.MetaInformation.CompInfo.TrialType);
%             if strfind(trialType,'static')
%                 static = true;
%             else
%                 static = false;
%             end
%         elseif strfind(lower(data.MetaInformation.SourceFile),'static')
%             static = true;
%         elseif strfind(lower(data.MetaInformation.SourceFile),'vmtmpl')
%             static = true;
%         else
%             static = false;
%         end
%     end
%     
% end

% Run algorithm for static or dynamic trials
%
if static
    front = mean(data.RASI);
    back = mean(vec);
  
    xr = front(1);
    yr = front(2);
    xs = back(1);
    ys = back(2);
    
    if xr > xs && yr < ys
        walkDir = 'Ipos';
    elseif xr < xs && yr > ys
        walkDir = 'Ineg';
    elseif xr > xs && yr > ys
        walkDir = 'Jpos';
    elseif xr < xs && yr < ys
        walkDir = 'Jneg';
    else
        error('unknown standing direction')
    end
    
else
    
    istart = find(~isnan(vec(:,1)),1,'first');
    iend = find(~isnan(vec(:,1)),1,'last');
    vec = vec(istart:iend,:);
    
    % Determine if most of motion is along global X or Y
    %
    X = abs(vec(1,1)-vec(end,1));
    Y = abs(vec(1,2)-vec(end,2));
    
    if Y > X % moving along Y
        axis = 'J';
        dim = 2;
    else     % moving along X
        axis = 'I';
        dim = 1;
    end
    
    % determine which direction along known axis person is travelling
    %
    vec =  vec(:,dim);
    indx = ~isnan(vec);
    vec = vec(indx);
    
    if vec(1) >  vec(end)  %
        dir = 'neg'; % negative slope
    else
        dir = 'pos';
    end
    
    walkDir = [axis,dir];
    
end

% Write to MetaInformation
%
data.MetaInformation.CompInfo.Direction = walkDir;