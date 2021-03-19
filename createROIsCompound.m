% Create createROIsCompound
%
% If you're not sure what to do, just run with no inputs and follow the
% prompts.


function createROIsCompound()

% Select type of plates
    q = questdlg('What type of plates are you using?','Plate type?','WorMotel','WormCamp','WorMotel');

% Select images to use for the compound ROI
    pparent = uigetdir("/home/u23/samfreitas/Worm_Paparazzi/WP_batching/images_for_ROI",'Select a path containing images to use as references'); 
%     pparent = uigetdir(cd,'Select a path containing images to use as references'); 
    if isempty(pparent); return; end

% Select output file
    
    ui = msgbox(sprintf('SPECIFY ROI OUTPUT FILE:\nIf the file already exists, your new ROIs will be APPENDED to the ones already in the file (NOT overwritten)'),...
                'Specify output file');
    uiwait(ui);
    
    [fout,pout] = uiputfile('*.*','Where do you want to save your ROIs?',fullfile(pparent,'ROI_ref_file.mat'));
    outfile = fullfile(pout,fout);
    if isempty(outfile); return; end

tempfile = strrep(outfile,'.mat','_backupEachLoop.mat');
    
% Find all images in the folder and create ROIs. Save compound file at each
% step
[d,N] = verify_dirlist(pparent,0,'.png');
save_flag = 0; % Disables saving within interactive. Saving happens separately

for n = 1:N
    
    if strcmpi(q,'WorMotel')
        [ref_img{n},ROI{n},N_wells{n},figs{n}] = createWormotelROIsInteractive(d(n).fullname,save_flag);
        
    elseif strcmpi(q,'WormCamp')
        [ref_img{n},ROI{n},N_wells{n},figs{n}] = create24WellROIsInteractive(d(n).fullname,save_flag);
        
    else
       error('Incorrect plate type'); 
    end
   save(tempfile,'ref_img','ROI','N_wells','figs','outfile');
   
end

% Make all columns
figs    = figs(:);
N_wells = N_wells(:);
ref_img = ref_img(:);
ROI     = ROI(:);


% If the outfile already exists, load it up and merge its ROIs with these
if exist(outfile,'file')
    
    % Load
    S = load(outfile);
    
    % Make the outfile all columns too
    S.figs    = S.figs(:);
    S.N_wells = S.N_wells(:);
    S.ref_img = S.ref_img(:);
    S.ROI     = S.ROI(:);    
    
    % Concatenate
    figs     = cat(1,figs,S.figs);
    N_wells  = cat(1,N_wells,S.N_wells);
    ref_img  = cat(1,ref_img,S.ref_img);
    ROI      = cat(1,ROI,S.ROI);
end

% Save 
   save(outfile,'ref_img','ROI','N_wells','figs');


% Finished
msgbox(sprintf('Finished!\nYour ROI file is:\n%s',outfile),'Finished');


end



