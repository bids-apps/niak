function part = niak_vol2part(vol, mask, opt)
% Convert a partition of N individual regions into 3D maps of clusters.
%
% SYNTAX:
% VOL = NIAK_VOL2PART(VOL,MASK)
%
% _________________________________________________________________________
% INPUTS:
%
% VOL
%   (size of MASK x T) the VOL(:,...,:,t) corresponds to the volues of PART(t,:),
%   organized like MASK. In other words, the "t"th volume, the "i"th region of
%   mask is "painted" with the value PART(t,i).
%
% MASK
%   (array with arbitrary number of dimensions, coding for "space", with a
%   total of V elements)
%   MASK==I is a binary mask of region I.
%
% OPT
%   (structure, optional)
%
%   METRIC
%       (string, default 'mean') chooses the summary metric across elements
%       inside one roi
%           'mean' : average
%           'mode' : most frequent element inside the roi
% _________________________________________________________________________
% OUTPUTS:
%
% PART
%   (array T x V) PART(t,I) is the number associated with region I for
%   volume #i
%
% _________________________________________________________________________
% COMMENTS:
%
% Copyright (c) Pierre Bellec
%   McConnell Brain Imaging Center, Montreal
%   Neurological Institute, McGill University, 2007-2011.
%   Centre de recherche de l'institut de Gériatrie de Montréal,
%   Département d'informatique et de recherche opérationnelle,
%   Université de Montréal, 2011-2013.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : partition, roi

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

if nargin < 3
    opt = psom_struct_defaults(struct(),...
          { 'metric' },...
          { 'mean'   });
elseif ~strcmp(opt.metric, 'mean') && ~strcmp(opt.metric, 'mode')
    % The option that was chosen is not implemented
    error('The option chosen for OPT.METRIC is not implemented!');
end


N = length(unique(mask));
S = size(vol,2);

part = zeros(N,S);

for roi_ind = 1:N
    switch opt.metric
        case 'mean'
            part(roi_ind,:) = mean(vol(mask == roi_ind,:),1);
        case 'mode'
            part(roi_ind,:) = mode(vol(mask == roi_ind,:),1);
    end
end
