function [] = niak_write_vol(hdr,vol)
% Write a 3D or 3D+t dataset into a file (analyze, nifti or minc)
%
% SYNTAX:
% [] = NIAK_WRITE_VOL(HDR,VOL)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL
%    (3D or 4D array) a 3D or 3D+t dataset
%
% HDR
%    (structure) a header structure (usually modified from the
%    output of NIAK_READ_VOL). The following fields are of
%    particular importance :
%
%    FILE_NAME
%        (string) a single 4D fMRI image file with multiple frames, or
%        a matrix of image file names, each with a single 3D frame,
%        either NIFIT (*.nii,*.img/hdr) ANALYZE (.img/hdr) or MINC
%        (.mnc) format.
%        Extra blanks are ignored. Frames are assumed to be equally
%        spaced in time.
%        If the file name contains an additional extension '.gz', the
%        output will be zipped using 'gzip'.
%
%    TYPE
%        (string) the output format (either 'minc1', 'minc2', 'nii',
%        'img' or 'analyze').
%
%    INFO
%        (structure, optional) with the following (optional) fields :
%
%        PRECISION
%            (string, default 'float') the
%            precision for writting data ('int', 'float' or
%            'double').
%
%        VOXEL_SIZE
%            (vector 1*3, default [1 1 1]) the
%            size of voxels along each spatial dimension in the same
%            order as in vol.
%
%        TR
%            (double, default 1) the time between two volumes (in
%            second)
%
%        MAT
%            (2D array 4*4, default identity) an affine transform
%            from voxel to world space.
%
%        DIMENSION_ORDER
%            (string, default 'xyz') describes the dimensions of
%            VOL. Letter 'x' is for 'left to right, 'y' for
%            'posterior to anterior', 'z' for 'ventral to dorsal' and
%            't' is time. Example : 'xzyt' means that dimension 1 of
%            VOL is 'x', dimension 2 is 'z', etc.
%
%        EXTRA
%            (structure) whatever field that is found here is saved
%            as a variable in a file <BASE FILE_NAME>_extra.mat
%            This feature is only supported when a single file is
%            created.
%
%        HISTORY
%            (string, default '') history of the operations applied to
%            the data.
%
%    DETAILS
%        (structure, optional in minc format) This field contains some
%        format-specific information, but is not necessary to write a
%        file. If present, the information will be inserted in the new
%        file. Note that the fields of HDR.INFO override HDR.DETAILS.
%        See NIAK_WRITE_MINC for more information under the minc format.
%
% _________________________________________________________________________
% OUTPUTS:
%
% Case 1: HDR.FILE_NAME is a string.
%
%   The data is written in a file called HDR.FILE_NAME in HDR.TYPE format.
%
% Case 2: HDR.FILE_NAME is a matrix of strings
%
%   Each row of file names has to correspond to the one element in the fourth
%   dimension of VOL. One file will be written for each volume VOL(:,:,:,i) in the file
%   HDR.FILE_NAME(i,:) after blanks have been removed.
%
% Case 3: HDR.FILE_NAME is a string, ending by '_'
%
%   One file will be written for each volume VOL(:,:,:,i) in the file
%   [HDR.FILE_NAME 000i]. The '000i' part meaning that i is converted to a
%   string and padded with '0' to reach at least four digits.
%
% _________________________________________________________________________
% SEE ALSO:
% NIAK_READ_HDR_MINC, NIAK_READ_HDR_NIFTI, NIAK_READ_MINC, NIAK_READ_VOL,
% NIAK_READ_NIFTI, NIAK_WRITE_MINC, NIAK_WRITE_NIFTI
%
% _________________________________________________________________________
% COMMENTS:
%
% As mentioned in the description of HDR.FILE_NAME, the extension of zipped
% file is assumed to be .gz. The tools used to zip files is 'gzip'. This
% setting can be changed by changing the variables GB_NIAK_ZIP_EXT and
% GB_NIAK_UNZIP in the file NIAK_GB_VARS.
%
% Other fields of HDR can be used in MINC format to speed up writting.
% See the help of NIAK_WRITE_MINC.
%
% The field HDR.TYPE is forced by the extension of the file name:
%   '.mnc.gz' -> ',minc1' ; '.mnc' -> 'minc2';
%   '.nii' or '.nii.gz' -> 'nii';
%   '.img' -> HDR.TYPE if it is 'img' or 'analyze', 'img' otherwise.
%
% If the file type is changed, HDR.DETAILS is ignored and all header fields
% are extrapolated from HDR.INFO. The exception to this behaviour is
% a conversion across nifti/analyze variants, which share the structure of
% their details.
%
% Copyright (c) Pierre Bellec, Montreal Neurological Institute, 2008.
% Maintainer : pbellec@bic.mni.mcgill.ca
% See licensing information in the code.
% Keywords : medical imaging, I/O, reader, minc


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


niak_gb_vars

if isempty(vol)
    warning('you are trying to write an empty dataset (I honestly do not know what is going to happen)!');
end

try
    file_name = hdr.file_name;
catch
    error('niak_write_vol: Please specify a file name in hdr.file_name.\n')
end

if ~ischar(file_name)
    error('niak_write_vol: FILE_NAME should be a string or a matrix of strings')
end

nb_file = size(file_name,1);

if any(isnan(vol(:)));
    vol(isnan(vol)) = 0; % replace NaNs with 0
end

if nb_file > 1

    %% Case 1: multiple file names have been specified

    if size(vol,4)~= nb_file
        warning('The number of files in hdr.file_name does not correspond to size(vol,4)! Try to proceed anyway...')
    end

    hdr2 = hdr;

    for num_f = 1:nb_file
        hdr2.file_name = deblank(hdr.file_name(num_f,:));
        niak_write_vol(hdr2,vol(:,:,:,num_f));
        if num_f == 1
            warning('off','niak:default')
        end
    end
    warning('on','niak:default')

elseif ischar(file_name)

    %% Case 2: a single file name has been specified

    if isempty(file_name)
        error('niak_write_vol: Please specify a non-empty file name in hdr.file_name')
    end

    if strcmp(file_name(end),'_')

        %% Case 2a : A string ending by '_'

        nt = size(vol,4);
        nb_digits = max(4,ceil(log10(nt)));

        try
            type_f = hdr.type;
        catch
            error('niak:write_vol: Please specify a file format in hdr.type.\n')
        end

        switch type_f
            case {'minc1','minc2'} % That's a minc file
                ext_f = '.mnc';
            case {'nii'}
                ext_f = '.nii';
            case{'img','analyze'}
                ext_f = '.img';
            otherwise
                error('niak:write: %s : unrecognized file format\n',type_f);
        end

        base_name = hdr.file_name;
        for num_f = 1:nt
            file_names = cat(2,base_name,repmat('0',1,nb_digits-length(num2str(num_f))),num2str(num_f),ext_f);
            hdr.file_name = file_names;
            if num_f > 1
                warning('off','niak:default')
            end
            niak_write_vol(hdr,vol(:,:,:,num_f));
        end
        warning('on','niak:default')

    else

        %% Case 2b : a regular string

        %% Check the type of the file
        [path_f,name_f,ext_f] = niak_fileparts(hdr.file_name);
        if isempty(path_f)
            path_f = '.';
        end

        if ~isfield(hdr,'type')
            error('niak:write: Please specify a file format in hdr.type.')
        end
        switch ext_f
          case '.mnc.gz'
            type_f = 'minc1';
          case '.mnc'
            type_f = 'minc2';
          case {'.nii','.nii.gz'}
            type_f = 'nii';
          case '.img'
            if ismember(hdr.type,{'img','analyze'})
                type_f = hdr.type;
            else
                type_f = 'img';
            end
          otherwise
            error('%s is not a supported extension',ext_f)
        end

        %% Check if the format has changed
        %% if it has, remove details, unless we are only moving between nifti subtypes
        if ~strcmp(type_f,hdr.type)&&~min(ismember({type_f,hdr.type},{'analyze','nii','img'}))
            hdr.type = type_f;
            if isfield(hdr,'details')
                hdr = rmfield(hdr,'details');
            end
        end

        %% Deal with extra information
        if isfield(hdr,'extra')
            extra = hdr.extra;
            hdr = rmfield(hdr,'extra');
        else
            extra = struct();
        end

        %% check if the path exist
        if ~exist(path_f,'dir')
            error(sprintf('Could not write %s, the folder %s does not exist !',hdr.file_name,path_f));
        end
        file_name = hdr.file_name;
        if (length(ext_f)>=3) && strcmp( ext_f((end-2):end) , '.gz');
            flag_zip = true;
            hdr.file_name = niak_file_tmp(['_' name_f ext_f(1:(end-3))]);
        else
            flag_zip = false;
        end

        switch type_f
            case {'minc1','minc2'} % That's a minc file
                niak_write_minc(hdr,vol);
            case {'nii','img','analyze'}
                niak_write_nifti(hdr,vol);
            otherwise
                error('niak:write: %s : unrecognized file format\n',type_f);
        end

        if flag_zip
            instr_zip = cat(2,GB_NIAK.zip,' ',hdr.file_name);
            [status,msg] = system(instr_zip);
            if status~=0
                error(cat(2,'niak:write: ',msg,'. There was a problem when attempting to zip the file. Please check that the command ''',GB_NIAK.zip,''' works, or change program using the variable GB_NIAK_ZIP in the file NIAK_GB_VARS'));
            end
            instr_mv = ['mv "' hdr.file_name GB_NIAK.zip_ext '" "' file_name '"'];
            [status,msg] = system(instr_mv);
            if status~=0
                error(cat(2,'niak:write: ',msg,'. There was a problem moving the compressed file from the temporary folder to its final destination'));
            end
        end

        %% Copy extra information, only if the number of time frames match with the actual data
        if (length(fieldnames(extra))>1)&&(length(extra.time_frames)==size(vol,4))
            [path_extra,name_extra] = niak_fileparts(file_name);
            file_extra = [path_extra filesep name_extra '_extra.mat'];
            save(file_extra,'-struct','extra')
        end
    end
else
    error('niak:write: hdr.filename has to be a string or a char array')
end
