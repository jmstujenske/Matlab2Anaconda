conda_root='C:\Users\Admin\anaconda3\';
conda_package='deepcadrt';
tcpport=50028;
echo_mat='C:/Users/Admin/Documents/Matlab/echo_mat.py';
m2p=mat2py_connection(tcpport,conda_root,conda_package,echo_mat);

jup_root='C:\\\\Users\\\\Admin\\\\Documents\\\\DeepCAD-RT\\\\DeepCAD_RT_pytorch';
for n=1:5
data_set_path=['G:/M',num2str(n),'/Toconvert/'];
result_path=['G:/M',num2str(n),'/DeepCad/'];
if ~exist(result_path)
    mkdir(result_path);
end
init_folders=dir(result_path);
init_folders=init_folders(3:end);
pth_path='C:/Users/Admin/Documents/Deepcad_files_Stujenske/pth';
denoise_model='E15';
clear coms;coms=[];

coms{length(coms)+1}="from deepcad.test_collection import testing_class";
coms{length(coms)+1}=["from deepcad.movie_display import display";
    "from deepcad.utils import get_first_filename, download_demo";
    "import os";
%     "os.chdir('" + jup_root + "')"
   ];

coms{length(coms)+1}=["datasets_path = '" + data_set_path + "'";
    "denoise_model = '"+denoise_model+"' # A folder containing all models to be tested"];

coms{length(coms)+1}=["test_datasize = 60000                   # the number of frames to be tested";
    "GPU = '0'                             # the index of GPU you will use for computation (e.g. '0', '0,1', '0,1,2')";
    "patch_xy = 150                        # the width and height of 3D patches";
    "patch_t = 150                         # the time dimension (frames) of 3D patches";
    "overlap_factor = 0.4                  # the overlap factor between two adjacent patches";
    "num_workers = 0                       # if you use Windows system, set this to 0.";
    "",
    "# Setup some parameters for result visualization during the test (optional)";
    "visualize_images_per_epoch = False    # whether to display inference performance after each epoch";
    "save_test_images_per_epoch = True     # whether to save inference image after each epoch in pth path"];

coms{length(coms)+1}=["test_dict = {";
    "    # dataset dependent parameters";
    "    'patch_x': patch_xy,                 # the width of 3D patches";
    "    'patch_y': patch_xy,                 # the height of 3D patches";
    "    'patch_t': patch_t,                  # the time dimension (frames) of 3D patches";
    "    'overlap_factor': overlap_factor,     # overlap factor";
    "    'scale_factor': 1,                   # the factor for image intensity scaling";
    "    'test_datasize': test_datasize,      # the number of frames to be tested";
    "    'datasets_path': datasets_path,      # folder containing all files to be tested";
    "    'pth_dir': '"+pth_path+"',                  # pth file root path";
    "    'denoise_model' : denoise_model,     # A folder containing all models to be tested";
    "    'output_dir' : '"+result_path+"',          # result file root path";
    "    # network related parameters";
    "    'fmap': 16,                          # number of feature maps";
    "    'GPU': GPU,                          # GPU index";
    "    'num_workers': num_workers,          # if you use Windows system, set this to 0.";
    "    'visualize_images_per_epoch': visualize_images_per_epoch,  # whether to display inference performance after each epoch";
    "    'save_test_images_per_epoch': save_test_images_per_epoch   # whether to save inference image after each epoch in pth path";
    "}"
   ];

coms{length(coms)+1}="tc = testing_class(test_dict)";
coms{length(coms)+1}="tc.run()";

for com_rep=1:length(coms)
    coms{com_rep}=commandify(coms{com_rep});
    out=m2p.py_command(coms{com_rep});
    if out==0
%         break;
        disp(['Error reached in command ',num2str(com_rep),' for animal ',num2str(n)]);
        disp('Skipping to next animal.');
        break;
    end
end
folders=dir(result_path);
folders=folders(3:end);
newfolder=setdiff({folders.name},{init_folders.name});
newfolder=newfolder{1};
newvid_path{n}=fullfile(result_path,newfolder);
subfolder=dir(newvid_path{n});subfolder=subfolder(3:end);
wrongfile=strmatch('para.yaml',strvcat(subfolder.name));
subfolder_name=subfolder(setdiff(1:2,wrongfile));
newvid_path{n}=fullfile(newvid_path{n},subfolder_name.name);
end
% for com_rep=1:length(coms)
%     write(t,char(sprintf(join(coms{com_rep},''))));
% end