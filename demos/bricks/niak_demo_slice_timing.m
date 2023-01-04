function [files_in,files_out,opt] = niak_demo_slice_timing(path_demo)
% This is a script to demonstrate the usage of NIAK_BRICK_SLICE_TIMING
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_DEMO_SLICE_TIMING(PATH_DEMO)
%
% _________________________________________________________________________
% INPUTS:
%
% PATH_DEMO
%       (string, default GB_NIAK_PATH_DEMO in the file NIAK_GB_VARS)
%       the full path to the NIAK demo dataset. The dataset can be found in
%       multiple file formats at the following address :
%       http://www.bic.mni.mcgill.ca/users/pbellec/demo_niak/
%
% _________________________________________________________________________
% OUTPUTS:
%
% FILES_IN,FILES_OUT,OPT : outputs of NIAK_BRICK_SLICE_TIMING (a
% description of input and output files with all options).
%
% _________________________________________________________________________
% OUTPUT
%
% This function applies a slice timing correction on the functional data of
% subject 1 (motor condition) and use the default output name.
%
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

if nargin>=1
    path_demo = niak_full_path(path_demo);
else
    path_demo = GB_NIAK.path_demo;
end

niak_gb_vars

%% In which format is the niak demo ?
format_demo = 'minc2';
if exist(cat(2,path_demo,'anat_subject1.mnc'))
    format_demo = 'minc2';
elseif exist(cat(2,path_demo,'anat_subject1.mnc.gz'))
    format_demo = 'minc1';
elseif exist(cat(2,path_demo,'anat_subject1.nii'))
    format_demo = 'nii';
elseif exist(cat(2,path_demo,'anat_subject1.img'))
    format_demo = 'analyze';
end

%% Setting input/output files
switch format_demo

     case 'minc1' % If data are in minc1 format

        files_in = cat(2,path_demo,filesep,'func_motor_subject1.mnc.gz');
        files_out = ''; % The default output name will be used

    case 'minc2' % If data are in minc2 format

        files_in = cat(2,path_demo,filesep,'func_motor_subject1.mnc');
        files_out = ''; % The default output name will be used

    otherwise

        error('niak:demo','%s is an unsupported file format for this demo. See help to change that.',GB_NIAK.format_demo)

end

%% Options
opt.suppress_vol = 3; % Suppress the three first volumes
opt.type_acquisition = 'interleaved ascending'; % Interleaved ascending (odd first by default)
opt.flag_test = 0; % This is not a test, the slice timing is actually performed

[files_in,files_out,opt] = niak_brick_slice_timing(files_in,files_out,opt);

%% Note that opt.interpolation_method has been updated, as well as files_out
