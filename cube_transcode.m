function [CR,PSNR,origsize,newsize] = cube_transcode(name,cube,ext,varargin)
%CUBE_TRANSCODE statistics
%   CUBE_TRANSCODE performs buildt-in MATLAB transcoding of cubes to
%   perform pseudo-analysis on the compression ratio as well as calculate
%   its total PSNR.
%
%   [CR,PSNR] = CUBE_TRANSCODE('name',cube,'ext') calculates the
%   compression ratio CR and the peak signal-to-noise ratio PSNR of
%   transcoding multi-band image cube. The output files are stored in a
%   directory named 'name'. The compression scheme used is determined by
%   the file extension 'ext'.
%
%   [CR,PSNR] = CUBE_TRANSCODE('name',cube,ext,spatial,bpf) transcodes
%   spatial planes if spatial is true, otherwise in the spectral domain.
%   Bands per file bpf determines the number of bands in each file (eg. 3
%   for RGB/YUV encoding).
%
%   [CR,PSNR,origsize,newsize] = CUBE_TRANSCODE(...) also returns the
%   original and new bytesizes of the transcoded cube.
%
%   CUBE_TRANSCODE('name',cube,ext,spatial,bpf,pca) means post-PCA analysis

WORDSIZE = 16; % Hard-coded for convenience
SPATIAL = true;
bpf = 1;
suffix = '';

if nargin>3
    %assert(nargin==5);
    SPATIAL = varargin{1};
    bpf = varargin{2};
    if nargin == 6 % post PCA analysis
        suffix = ['/PCA_' int2str(varargin{3})];
    end
end

if SPATIAL
    prefix = 'spatial';
else
    prefix = 'spectral';
end

cdir = [ext '/' prefix '/' name suffix];
mkdir(cdir);
m = cube;
%m = double(m);
%m = m-min(min(min(m)));
%m = uint16(m); % Hard-coded for convenience
if ~SPATIAL
    %m = permute(m, [1 3 2]); %5.75
    m = permute(m, [3 1 2]); %5.76
    %m = permute(m, [3 2 1]); %5.70 (HICO_L2_1)
    %m = permute(m, [2 3 1]); %5.70
end

%rm = uint16(zeros(size(m))); % Hard-coded for convenience
h = waitbar(0);
n = size(m, 3);
for i = 1:bpf:n+1-bpf
    waitbar(i/n, h, sprintf('Compressing band %i of %i',i,n));
    subs = i:i+bpf-1;
    curr_file = [cdir sprintf('/%03i_%03i_%03i.',subs) ext];
    imwrite(m(:,:,subs), curr_file);
    %rm(:,:,subs) = imread(curr_file);
end
delete(h);

%Single channels
for i = 1:mod(n,3)
    ii = n+1-i;
    curr_file = [cdir sprintf('/%03i.',ii) ext];
    if nargin > 6 % tilesize specified (TODO: Refactor code)
        imwrite(m(:,:,ii), curr_file, 'tilesize', varargin{4});
    else
        imwrite(m(:,:,ii), curr_file);
    end
    %rm(:,:,ii) = imread(curr_file);
end
%rm = int16(zeros(size(m))); % ONLY DEBUG
PSNR = NaN;%psnr(rm, m); % Deactivated because of bad performance
D = dir(cdir);
origsize = (WORDSIZE/8)*numel(cube);
newsize = sum([D.bytes]);
CR = origsize/newsize;
%rmdir([cdir '/..'], 's');
