function [process,psw,ODR,EDR] = conda_interface(conda_root,password)
%[process,psw,lh,lh2] = conda_interface(conda_root,password)
%
%Create an interface to anaconda prompt
%
%INPUT:
%conda_root: path for the anaconda root (default:
%'C:\Users\Admin\anaconda3\');
%
%password: password for windows username login. Optional, but may be
%necessary for admin privileges to be enabled. You may have trouble if you have no
%password set.
%
%OUTPUT:
%process - System.Diagnostics.Process
%psw - process.StandardInput (for writing commands to anaconda)
%ODR,EDR - for getting output and error data to display
%
%Outputs of anaconda will be displayed to the command window. Beware that there will be
%a delay for commands that are being actively generated
%
%
    if nargin<1 || isempty(conda_root)
        conda_root='C:\Users\Admin\anaconda3\';
    end
    if nargin<2
        password=[];
    end
  % Initialize the process and its StartInfo properties.
  % The sort command is a console application that
  % reads and sorts text input.
  process = System.Diagnostics.Process;
  process.StartInfo.FileName = 'cmd.exe';
  process.StartInfo.Arguments= ['"/K" ',fullfile(conda_root,'Scripts\activate.bat')];         
  process.EnableRaisingEvents = true;
  process.StartInfo.CreateNoWindow = true;
  % Set UseShellExecute to false for redirection.
  process.StartInfo.UseShellExecute = false;
  %Redirect the standard output of the sort command.
  process.StartInfo.RedirectStandardOutput = true;
  process.StartInfo.RedirectStandardError = true;
  process.StartInfo.RedirectStandardInput = true;
  process.StartInfo.Verb='runas';

%if password is specified
if ~isempty(password)
  process.StartInfo.UserName=getenv('USERNAME');
  securestring = System.Security.SecureString;
  for c = password
     securestring.AppendChar(c);
  end
  process.StartInfo.Password=securestring;
end

  ODR = process.addlistener('OutputDataReceived',@processOutputHandler);
  EDR= process.addlistener('ErrorDataReceived',@processOutputHandler);
  process.Start();
  psw = process.StandardInput;
  process.BeginOutputReadLine();
end

function processOutputHandler(obj,event)
 %print command output in the command window
 if(~isempty(event.Data)) 
     disp(char(event.Data));
 end
end
