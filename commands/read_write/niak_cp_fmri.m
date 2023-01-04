function [flag_error,message] = niak_cp_fmri(source,target)
% Copy an fMRI volume under a different name.
%
% SYNTAX:
% [FLAG_ERROR,MESSAGE] = NIAK_CP_FMRI(SOURCE,TARGET)
%
% _________________________________________________________________________
% INPUTS:
%
% SOURCE
%   (string) the name of an fMRI dataset (extension .mnc or .nii with or
%   wihtout .gz).
%
% TARGET
%   (string) the name of an fMRI dataset (extension .mnc or .nii with or
%   wihtout .gz).
%
% _________________________________________________________________________
% OUTPUTS:
%
% FLAG_ERROR
%   (boolean) If the flag is non-zero, an error has occured.
%
% MESSAGE
%   (string) the message generated by the copy command.
%
% _________________________________________________________________________
% COMMENTS:
%
% The difference between that command and a simple cp is that any file
% of the type <BASE SOURCE>_extra.mat will be copied under the name
% <BASE TARGET>_extra.mat.
%
% Copyright (c) Pierre Bellec,
% Research Centre of the Montreal Geriatric Institute
% & Department of Computer Science and Operations Research
% University of Montreal, Qubec, Canada, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : fMRI

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

% Check if this is an omitted file
if strcmp(source,'gb_niak_omitted')
    return
end

% Parse folder information
source = niak_full_file(source);
target = niak_full_file(target);
[path_s,name_s,ext_s] = niak_fileparts(source);
[path_t,name_t,ext_t] = niak_fileparts(target);

% Copy or convert, if necessary
if strcmp(ext_s,ext_t)
    instr_copy = cat(2,'cp ',source,' ',target);
    [status,msg] = system(instr_copy);
    if status~=0
        error(msg)
    end
else
    [hdr,vol] = niak_read_vol(source);
    hdr.file_name = target;
    niak_write_vol(hdr,vol);
end

% Copy the "extra" file, if present
file_extra_s = [path_s filesep name_s '_extra.mat'];
file_extra_t = [path_t filesep name_t '_extra.mat'];
if psom_exist(file_extra_s)
    instr_copy = cat(2,'cp -f ',file_extra_s,' ',file_extra_t);
    [status,msg] = system(instr_copy);
    if status~=0
        error(msg)
    end
end
