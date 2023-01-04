%
% _________________________________________________________________________
% SUMMARY NIAK_DEMO_AUTOCORRELATION
%
% This is a script to demonstrate the usage of :
% NIAK_BRICK_AUTOCORRELATION
%
% SYNTAX:
% Just type in NIAK_DEMO_AUTOCORRELATION.
%
% _________________________________________________________________________
% OUTPUT
%
% It will derive the spatial and temporal autocorrelation maps for the rest
% condition for subject1.
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
% _________________________________________________________________________
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

     case 'minc1' % If data are in minc1 format

        files_in = cat(2,GB_NIAK.path_demo,filesep,'func_rest_subject1.mnc.gz');
        files_out.spatial = ''; % The default output name will be used
        files_out.temporal = ''; % The default output name will be used

    case 'minc2' % If data are in minc2 format

        files_in = cat(2,GB_NIAK.path_demo,filesep,'func_rest_subject1.mnc');
        files_out.spatial = ''; % The default output name will be used
        files_out.temporal = ''; % The default output name will be used

    otherwise

        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',GB_NIAK.format_demo)

end

%% Options
opt.flag_test = 0; % This is not a test, the slice timing is actually performed

[files_in,files_out,opt] = niak_brick_autocorrelation(files_in,files_out,opt);

%% Note that opt.interpolation_method has been updated, as well as files_out
