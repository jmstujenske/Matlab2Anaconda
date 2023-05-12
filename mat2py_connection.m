classdef mat2py_connection < handle
    %mat2py_connection(port,conda_root,conda_pkg,echo_mat)
    %
    %open connection to evoke python commands in an
    %anaconda environment, with some limited functionality to pull
    %information back into Matlab
    %
    %INPUT:
    %
    %port - any unused TCP port; used for python <--> Matlab communication
    %conda_root - folder where anaconda3 root is located
    %ponda_pkg - name of the environment to use
    %echo_mat - location of the echo_mat.py file
    %
    %A System.Diagnostics.Process is used to open an Anaconda session,
    %accessible within Matlab
    %
    %This temporarily copies an echo_mat.py file into the indicated
    %environment, which allows for Matlab to issue commands to python
    %The echo_mat.py script is run.
    %
    %Matlab and Python become connected by a local TCP port, and Matlab
    %passes messages to python that are then echoed by the .py script.
    %Individual lines of python code can be passed or it can run .py or
    %other files.
    %
    %Python sends messages back to Matlab indicating the success of
    %individual commands, and when requested, returning some information.
    %
    %COMMANDS:
    %out=m2p.py_command(string,blocking) excecutes the command in string
    %with or without blocking (default: blocking = true)
    %
    %out=m2p.run_py_file(filename,blocking) executes a python .py file, line by line
    %with or without blocking (default: blocking = true)
    %
    %m2p.release(blocking) executes all commands in the buffer with or
    %without blocking (default: blocking = true)
    %
    %If run without blocking, m2p will not execute any commands until it
    %receives a reply from python for all passed commands
    %
    %out=py_query(string) queries python about the value of an input, and
    %gives a corresponding output
    %
    %m2p.terminate_connect terminates the TCP/IP connection
    %
    %m2p.buf(commands) adds a command to a buffer
    %
    properties
        tcp_obj
        port;
        echo_mat_loc
        echo_copy_path
        connected=false;
        psw
        lh
        lh2
        process
        conda_p
        waiting_reply=false;
        com_buffer=[];
        count=0;
    end

    methods
        function obj = mat2py_connection(port,conda_root,conda_pkg,echo_mat)
            if nargin<4
                echo_mat='C:/Users/Admin/Documents/Matlab/echo_mat.py';
            end
            if nargin<3
                conda_pkg=[];
            end
            if nargin<2
                conda_root=[];
            end
            %build a matlab to python connection with tcp
            obj.echo_mat_loc=echo_mat;
            obj.port = port;
            obj.conda_p.root=conda_root;
            obj.conda_p.pkg=conda_pkg;
            start_py_echo(obj);
            pause(.5);
            connect_tcp(obj);
        end

        function connect_tcp(obj)
            %connect to tcpclient
            for rep=1:5 %try to connect 5 times
                if isempty(obj.tcp_obj) || ~isvalid(obj.tcp_obj)
                    try
                        obj.tcp_obj = tcpclient('localhost', obj.port);
                        obj.connected=true;
                        break;
                    catch
                        pause(.01);
                    end
                end
            end
            if ~isempty(obj.conda_p.pkg)
                obj.connected=false;
                tic;
                t_start=toc;
                while 1
                    if obj.tcp_obj.NumBytesAvailable>0
                        connect_confirmed=readline(obj.tcp_obj);
                        %         if ~isempty(S2)
                        %         write(S2,123,'uint8');
                        %         end
                        obj.connected=true;
                        break;
                    elseif toc-t_start>3
                        disp('Could not establish connection.');
                        break;
                    end
                end
            end
        end

        function start_py_echo(obj)
            if ~isempty(obj.conda_p.pkg)
                copyfile(obj.echo_mat_loc,fullfile(obj.conda_p.root,'envs',obj.conda_p.pkg,'Lib\site-packages'));
                [folder,file,ext]=fileparts(obj.echo_mat_loc);
                obj.echo_copy_path=fullfile(obj.conda_p.root,'envs',obj.conda_p.pkg,'Lib\site-packages',[file,ext]);
                [obj.process,obj.psw,obj.lh,obj.lh2] = conda_interface(obj.conda_p.root);
                obj.psw.WriteLine(['conda activate ',obj.conda_p.pkg]);
                obj.psw.WriteLine([fullfile(obj.conda_p.root,'envs\',obj.conda_p.pkg,'\python.exe -m echo_mat'),' ',num2str(obj.port)]);
            end
        end

        function out=run_py_file(obj,filename,blocking)
            if nargin<3 || isempty(blocking)
                blocking=true;
            end
            if obj.waiting_reply
                out=check_reply(obj);
            end
            if ~obj.waiting_reply
                if obj.connected
                    n_commands=runpy(obj.tcp_obj,filename);
                else
                    disp('Python not yet connected.')
                    return;
                end
                obj.count=n_commands;
                if blocking
                    while obj.count>0
                        if obj.tcp_obj.NumBytesAvailable>0
                            msgback=readline(obj.tcp_obj);
                            if strcmp(msgback,'S')
                                out=1;
                            elseif strcmp(msgback,'F')
                                out=0;
                                msgback=readline(obj.tcp_obj);
                                disp(['Python Error: ',char(msgback)]);
                            else
                                disp('Unknown reply.')
                                out=NaN;
                            end
                            obj.count=obj.count-1;
                        end
                    end
                else
                    obj.waiting_reply=true;
                end
            end
        end

        function py_buf(obj,command)
            if isstring(command)
                command=char(sprintf(join(command)));
            end
            obj.com_buffer=[obj.com_buffer,command,uint8([13 10])];
        end

        function py_release(obj,blocking)
            if nargin<2 || isempty(blocking)
                blocking=true;
            end
            if obj.waiting_reply
                out=check_reply(obj);
            end
            if ~obj.waiting_reply
                n_commands=length(obj.com_buffer)/2;
                obj.tcp_obj.write(obj.com_buffer);
                obj.com_buffer=[];
                obj.count=n_commands;
                if blocking
                    while obj.count>0
                        if obj.tcp_obj.NumBytesAvailable>0
                            msgback=readline(obj.tcp_obj);
                            if strcmp(msgback,'S')
                                out=1;
                            elseif strcmp(msgback,'F')
                                out=0;
                                msgback=readline(obj.tcp_obj);
                                disp(['Python Error: ',char(msgback)]);
                            else
                                disp('Unknown reply.')
                                out=NaN;
                            end
                            obj.count=obj.count-1;
                        end
                    end
                else
                    obj.waiting_reply=true;
                end
            end
        end

        function out=py_command(obj,command,blocking)
            if nargin<3 || isempty(blocking)
                blocking=true;
            end
            if obj.waiting_reply
                out=check_reply(obj);
            end
            if ~obj.waiting_reply
                if isstring(command)
                    command=char(sprintf(join(command,'')));
                end
                %flush(obj.tcp_obj);
                obj.tcp_obj.write(command);
                if blocking
                    obj.count=1;
                    while 1
                        if obj.tcp_obj.NumBytesAvailable>0
                            msgback=readline(obj.tcp_obj);
                            if strcmp(msgback,'S')
                                out=1;
                            elseif strcmp(msgback,'F')
                                out=0;
                                msgback=readline(obj.tcp_obj);
                                disp(['Python Error: ',char(msgback)]);
                            else
                                disp('Unknown reply.')
                                out=NaN;
                            end
                            obj.count=0;
                            break;
                        end
                    end
                else
                    obj.count=1;
                    obj.waiting_reply=true;
                end
            end
        end

        function out=check_reply(obj)
            if obj.waiting_reply && obj.tcp_obj.NumBytesAvailable>0
                msgback=readline(obj.tcp_obj);
                if strcmp(msgback,'S')
                    out=1;
                elseif strcmp(msgback,'F')
                    out=0;
                    msgback=readline(obj.tcp_obj);
                    disp(['Python Error: ',char(msgback)]);
                else
                    disp('Unknown reply.')
                    out=NaN;
                end
                obj.count=obj.count-1;
                if obj.count==0
                    obj.waiting_reply=false;
                end
            else
                out=[];
            end
        end

        function msgback=py_query(obj,command)
            if obj.waiting_reply
                out=check_reply(obj);
            end
            if ~obj.waiting_reply
                if isstring(command)
                    command=char(sprintf(join(command)));
                end
                obj.tcp_obj.write(['*query:',command]);
                tic;
                while 1
                    if obj.tcp_obj.NumBytesAvailable>0
                        msgback=readline(obj.tcp_obj);
                        break;
                    end
                    if toc>1
                        msgback=[];
                        break;
                    end
                end
            end
        end

        function terminate_connect(obj)
            if obj.waiting_reply
                out=check_reply(obj);
            end
            if ~obj.waiting_reply
                if obj.connected
                    write(obj.tcp_obj,'terminate_pylink');
                    pause(.5);
                    delete(obj.process)
                    delete(obj.psw)
                    flush(obj.tcp_obj);
                    clear obj.tcp_obj
                    delete(obj.lh)
                    obj.connected=false;
                    obj.port=[];
                    delete(obj.echo_copy_path);
                else
                    disp('Connection not established yet.')
                end
            else
                disp('Awaiting Reply.')
            end
        end

    end
end