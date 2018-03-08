%% Instructions
warning([...
'Use the scripts sections seperately (Ctrl+Enter).'...
'\n']);
edit processing.m
return

%% Instantiate datasets
datasets = [...
    struct('name','AVIRIS_L1','subsets',1,'dims',[2776 754 224]),...
    struct('name','AVIRIS_L2','subsets',4,'dims',[ 512 614 224]),...
    struct('name','HICO_L1B', 'subsets',6,'dims',[2000 512 128]),...
    struct('name','HICO_L2',  'subsets',6,'dims',[2000 512  65])];

%% Set default parameters
interleave = 'bsq';
precision = 'int16';
byteOrder = 'ieee-le';
offset = 0;
cdir = [interleave '/'];
ext = ['.' interleave];

%% Compression parameters
bpf = 3; % bands per file
spatial = true;
format = 'tif';

%% Clean up exports (clear up disk space)
rmdir(format, 's');

%% Load single cube
dataset_n = 1;
subset = 1;
filepath = [cdir datasets(dataset_n).name '_' int2str(subset)  ext];
M = multibandread(filepath, datasets(dataset_n).dims, precision, ...
    offset, interleave, byteOrder);

%% JP2 Tile size benchmarking
Exp = 7:10
for i = 1:length(Exp)
    tilewidth = 2^Exp(i);
    tilesize = [tilewidth tilewidth];
    name = ['tiled' int2str(tilewidth)];
    [CR,PSNR,origsize,newsize] = ...
        cube_transcode(name,M,format,spatial,bpf,0,tilesize);
end

%% Perform compression statistics
fprintf('Cube %22s %13s %4s %s\n',...
    'Original size','New size','CR','PSNR');
for i = 1%:length(datasets)
    for subset = 1%:datasets(i).subsets
        filepath = [cdir datasets(i).name '_' int2str(subset)  ext];
        2
        % Quickfix for odd HICO_L1B_5 and missing HICO_L2_5
        if i == 3 && subset == 5
            M = multibandread(filepath, ...
                [2000 500 87], precision, offset, ...
                interleave, byteOrder);
        elseif i == 4 && subset == 5
            continue
        else
            M = multibandread(filepath, ...
                datasets(i).dims, precision, offset, ...
                interleave, byteOrder);
        end
        return
        % Print statistics
        M = int16(M);
        name = sprintf('%s_%i', datasets(i).name, subset);
        [CR,PSNR,origsize,newsize] = ...
            cube_transcode(name,M,format,spatial,bpf);
        fprintf('%12s: %13d %13d %1.2f %4.2d\n',...
            name,origsize,newsize,CR,PSNR)

    end
end

%% Perform post PCA compression statistics
assert(strcmp(precision,'int16')); % Because this is hardcoded
components = [10,20,30,40,50];
pca_dir = ['pca/' precision '/'];
suffix = [upper(interleave) '_M_PCA'];

fprintf('Cube %22s %13s %4s \n',...%s\n',...
    'Original size','New size','Components')%,'PSNR');

% Table entries
Name = {};
Size = [];
Ratio = []; %Compression ratio
ii = 1;

for i = 4:length(datasets)
    for subset = 1:5%datasets(i).subsets
        for c = components
            dims = datasets(i).dims;
            origdims = dims;
            dims(3) = c;
            filepath = ...
                [cdir pca_dir datasets(i).name '_' int2str(subset)  ...
                suffix int2str(c) ext];

            % Quickfix for odd HICO_L1B_5 and missing HICO_L2_5
            if i == 3 && subset == 5
                origdims = [2000 500 87];
                dims = [2000 500 c]
                M = multibandread(filepath, ...
                    dims, precision, offset, ...
                    interleave, byteOrder);
            elseif i == 4 && subset == 5
                continue
            else
                M = multibandread(filepath, ...
                    dims, precision, offset, ...
                    interleave, byteOrder);
                %return
            end

            % Print statistics
            M = int16(M);
            name = sprintf('%s_%i', datasets(i).name, subset);
            [CR,PSNR,origsize,newsize] = ...
                cube_transcode(name,M,format,spatial,bpf,c);
            
            fprintf('%12s: %13d %13d %02d\n',...%1.2f %4.2d\n',...
                name,origsize,newsize, c)%,CR,PSNR)
            
            Name{ii,1} = [datasets(i).name '_' int2str(subset) ...
                '_PCA' int2str(c)]; ii = ii+1;
            Size = [Size;(newsize * 8)];
            Ratio = [Ratio;(16 * prod(origdims) / (newsize*8))];
        end
    end
end
T = table(Size,Ratio,...
    'RowNames',Name)

%% Export (and view)
table_file = 'PCA.xls';
writetable(T,table_file,'writeRowNames',true);
winopen(table_file);
