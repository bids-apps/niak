function [files_in,files_out,opt] = niak_brick_copy(files_in,files_out,opt)
% Copy a bunch of files.
%
% SYNTAX:
% [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_COPY(FILES_IN,FILES_OUT,OPT)
%
% _________________________________________________________________________
% INPUTS
%
% FILES_IN
%   (cell of strings) a list of file names
%
% FILES_OUT
%   (cell of strings, default OPT.FOLDER_OUT/(NAME_FILES_IN))
%   File name for outputs. If FILES_OUT is an empty string, the default
%   name is generated.
%
% OPT
%   (structure) with the following fields.
%
%   FLAG_FMRI
%       (boolean, default false) if the flag is true, then NIAK_CP_FMRI is
%       used instead of a system call to cp. This command copies "_extra.mat" files
%       along with fMRI datasets.
%
%   FOLDER_OUT
%       (string, default: folder of FILES_IN{1}) If present, all default
%       outputs will be created in the folder FOLDER_OUT. The folder
%       needs to be created beforehand.
%
%   FLAG_VERBOSE
%       (boolean, default 1) if the flag is 1, then the function prints
%       some infos during the processing.
%
%   FLAG_TEST
%       (boolean, default 0) if FLAG_TEST equals 1, the brick does not do
%       anything but update the default values in FILES_IN, FILES_OUT and
%       OPT.
%
% _________________________________________________________________________
% OUTPUTS
%
% The structures FILES_IN, FILES_OUT and OPT are updated with default
% valued. If OPT.FLAG_TEST == 0, the specified outputs are written.
%
% _________________________________________________________________________
% COMMENTS
%
% FILES_IN and FILES_OUT can also be passed as strings, in which case a single
% files is copied.
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

niak_gb_vars % Load some important NIAK variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Seting up default arguments %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('files_in','var')
    error('niak:brick','syntax: [FILES_IN,FILES_OUT,OPT] = NIAK_BRICK_COPY(FILES_IN,FILES_OUT,OPT).\n Type ''help niak_brick_copy'' for more info.')
end

%% Check inputs
if ischar(files_in)&&ischar(files_out)
    files_in = {files_in};
    files_out = {files_out};
end

if ~iscellstr(files_in)||~iscellstr(files_out)
    error('FILES_IN and FILES_OUT need to be both either strings or cell of strings')
end

%% Options
gb_name_structure = 'opt';
gb_list_fields    = {'flag_fmri' , 'flag_verbose' , 'flag_test' , 'folder_out' };
gb_list_defaults  = {false       , 1              , 0           , ''           };
niak_set_defaults

%% Output files
[path_f,name_f,ext_f] = fileparts(files_in{1});
if isempty(path_f)
    path_f = '.';
end

if strcmp(ext_f,GB_NIAK.zip_ext)
    [tmp,name_f,ext_f] = fileparts(name_f);
    ext_f = cat(2,ext_f,GB_NIAK.zip_ext);
end

if strcmp(opt.folder_out,'')
    opt.folder_out = path_f;
end
opt.folder_out = niak_full_path(opt.folder_out);

%% Building default output names
nb_files = length(files_in);

if isempty(files_out)

    files_out = cell([nb_files 1]);

    for num_f = 1:nb_files
        [path_f,name_f,ext_f] = niak_fileparts(files_in{num_f});
        files_out{num_f} = cat(2,opt.folder_out,name_f,ext_f);
    end

end

if flag_test == 1
    return
end

%%%%%%%%%%%%%%%%%%%
%% Copying files %%
%%%%%%%%%%%%%%%%%%%

for num_f = 1:nb_files

    if flag_verbose
        msg = sprintf('Copying or converting file %s to %s',files_in{num_f},files_out{num_f});
        fprintf('%s\n',msg);
    end
    if opt.flag_fmri
        niak_cp_fmri(files_in{num_f},files_out{num_f});
    else
        instr_copy = ['cp -f ',files_in{num_f},' ',files_out{num_f}];
        [succ,msg] = system(instr_copy);
        if succ~=0
            error(sprintf('error copying the file : %s',msg));
        end
    end
end
