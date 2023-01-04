% Upload fields of a structure as variables of the workspace, with default
% values.
%
% SYNTAX:
% NIAK_SET_DEFAULTS
%
% This is a script !! Values of the workspace which calls the script will
% be affected.
%
% _________________________________________________________________________
% INPUTS :
% There is no input per say, as this is a script and not a function.
% The following variables still need to exist in the workspace before
% calling the script :
%
% GB_NAME_STRUCTURE
%       (string) the name of the structure to test.
%
% GB_LIST_FIELDS
%       (cell of strings) names of fields.
%
% GB_LIST_DEFAULTS
%       (cell) the default values. A Nan will produce an error message and
%       exit if no value is defined in the field.
%
% _________________________________________________________________________
% OUTPUTS :
%
% All fields listed in GB_LIST_FIELDS are checked in the structure
% GB_NAME_STRUCTURE, and default values are applied if they don't exist.
% In addition, the listed fields are uploaded as variables. A warning is
% issued if unlisted fields are found in GB_NAME_STRUCTURE. Values of the
% structure are updated.
%
% COMMENTS:
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.

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

%% Test if the structure exist, otherwise initialize an empty one
try
    %GB_NIAK.struct = evalin('caller',gb_name_structure); % for some reason it does not seem to work in octave

    eval(sprintf('GB_NIAK.struct = %s;',gb_name_structure));
catch
    GB_NIAK.struct = struct([]);
end

%% Loop on every field
GB_NIAK.nb_fields = length(gb_list_fields);

for num_f = 1:GB_NIAK.nb_fields

    GB_NIAK.field = gb_list_fields{num_f};
    GB_NIAK.val = gb_list_defaults{num_f};
    GB_NIAK.flag_field = isfield(GB_NIAK.struct,GB_NIAK.field);

    %% If the field does not exist, create it with default value
    if ~GB_NIAK.flag_field
        if isnumeric(GB_NIAK.val)
            if isnan(GB_NIAK.val)
                error(cat(2,'niak:defaults: Please specify field ',GB_NIAK.field,' in structure ',gb_name_structure,' !\n'))
            end
        end
        GB_NIAK.struct(1).(GB_NIAK.field) = GB_NIAK.val;
    end

    % Upload the field as a variable

    %assignin('caller',field,GB_NIAK.struct.(field));
    instr_upload = sprintf('%s = GB_NIAK.struct.%s;',GB_NIAK.field,GB_NIAK.field);
    eval(instr_upload);
end

%% Test if some field were not used, and eventually issue a warning.
gb_list_fields_init = fieldnames(GB_NIAK.struct);
if length(gb_list_fields_init)~=length(gb_list_fields);
    gb_mask_init = ismember(gb_list_fields_init,gb_list_fields);
    if min(gb_mask_init)==0
        gb_fields_warning = [];
        gb_ind_init = find(gb_mask_init==0);
        for num_i = 1:length(gb_ind_init)
            gb_fields_warning = [gb_fields_warning ' ' gb_list_fields_init{gb_ind_init(num_i)}];
        end
        warning(cat(2,'niak:default: The following field(s) were ignored in the structure ',gb_name_structure,' : ',gb_fields_warning));
    end
end

%% Export the structure
eval(cat(2,gb_name_structure,' = GB_NIAK.struct;'))
