function [in,out,opt] = niak_brick_preproc_func2report(in,out,opt)
% Generate javascript formatted measure of quality for functional registration
%
% SYNTAX: [IN,OUT,OPT] = NIAK_BRICK_PREPROC_FUNC2REPORT(IN,OUT,OPT)
%
% IN (string) The name of a .csv file with measures of brain mask overlap with
%   group brain mask, as well as spatial correlation between individual and
%   average group BOLD images, after registration.
% OUT (string) the name of a .js file with two variables:
%   dataBOLD spatial correlation of individual and group BOLD images.
%   dataBrain is a measure of overlap between the individual brain functional
%   mask and the group functional mask.
% OPT.FLAG_TEST (boolean, default false) if the flag is true, the brick does nothing but
%    update IN, OUT and OPT.
%
% Copyright (c) Pierre Bellec
% Centre de recherche de l'Institut universitaire de griatrie de Montral, 2016.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords: preprocessing report

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

%% Defaults
if ~ischar(in)
    error('IN should be a string');
end

if ~ischar(out)
    error('OUT should be a string');
end

if nargin < 3
    opt = struct;
end
opt = psom_struct_defaults ( opt , ...
    { 'flag_test' }, ...
    { false         });

if opt.flag_test
    return
end

%% Load parameters
tab = niak_read_csv_cell(in);

%% Spatial correlation
text_bold = sprintf('var dataBOLD = [\n[''Subject'' ');
val = str2double(tab(2:end,3));
[val,order] = sort(val,'ascend');
order = order(:)'+1;
for ss = order
	text_bold = [text_bold, ', ''' tab{ss,1} ''''];
end
text_bold = [text_bold sprintf('],\n[''corr_target'' ')];
for ss = order
    text_bold = [text_bold, ', ''' tab{ss,3} ''''];
end
text_bold = [text_bold sprintf(']\n];\nvar dataBrain = [\n[''Subject'' ')];

%% overlap with brain mask
val = str2double(tab(2:end,2));
[val,order] = sort(val,'ascend');
order = order(:)'+1;
for ss = order
	text_bold = [text_bold, ', ''' tab{ss,1} ''''];
end
text_bold = [text_bold sprintf('],\n[''overlap_brain'' ')];
for ss = order
    text_bold = [text_bold, ', ''' tab{ss,2} ''''];
end
text_bold = [text_bold sprintf(']\n];\n')];

%% Write output
[hf,msg] = fopen(out,'w');
if hf == -1
    error(msg)
end
fprintf(hf,'%s',text_bold);
fclose(hf);
