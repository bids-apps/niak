%
% _________________________________________________________________________
% SUMMARY NIAK_DEMO_REALIGN
%
% This is a script to demonstrate the usage of :
% NIAK_BRICK_REALIGN
% Just type in NIAK_DEMO_REALIGN
%
% _________________________________________________________________________
% OUTPUT
%
% It will apply a motion correction on the functional data of subject
% 1 and use the default output names.
%
% _________________________________________________________________________
% COMMENTS
%
% NOTE 1
% This script will clear the workspace !!
%
% NOTE 2
% Note that the path to access the demo data is stored in a variable
% called GB_NIAK_PATH_DEMO defined in the script NIAK_GB_VARS.
%
% NOTE 3
% The demo database exists in multiple file formats.NIAK looks into the demo
% path and is supposed to figure out which format you are intending to use
% by himself.You can the format by changing the variable GB_NIAK_FORMAT_DEMO
% in the script NIAK_GB_VARS.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, slice timing, fMRI

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

clear
niak_gb_vars

%% Setting input/output files
switch GB_NIAK.format_demo

    case 'minc2' % If data are in minc2 format

        %% The two datasets have actually been acquired in the same
        %% session, but this is just to demonstrate how the procedure works
        %% in general.
        files_in.session1{1} = cat(2,GB_NIAK.path_demo,filesep,'func_motor_subject1.mnc');
        files_in.session2{1} = cat(2,GB_NIAK.path_demo,filesep,'func_rest_subject1.mnc');

    case 'minc1' % If data are in minc1 format

        %% The two datasets have actually been acquired in the same
        %% session, but this is just to demonstrate how the procedure works
        %% in general.
        files_in.session1{1} = cat(2,GB_NIAK.path_demo,filesep,'func_motor_subject1.mnc.gz');
        files_in.session2{1} = cat(2,GB_NIAK.path_demo,filesep,'func_rest_subject1.mnc.gz');

    otherwise

        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',GB_NIAK.format_demo)
end

%% Setting output files
files_out.motion_corrected_data = ''; % use default names
files_out.motion_parameters = ''; % use default names
files_out.fig_motion  = ''; % use default names

%% Options
opt.session_ref = 'session2'; % Use the second 'session' as a target
opt.vol_ref = 5; % Use the 40th volume as a target
opt.flag_test = 0; % Actually perform the motion correction

[files_in,files_out,opt] = niak_brick_realign(files_in,files_out,opt);

%% Note that opt.interpolation_method has been updated, as well as files_out
