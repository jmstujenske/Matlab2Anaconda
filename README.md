# Matlab2Anaconda
Interface for Matlab to issue commands within specified Anaconda environments

This repo is based around the mat2py_connection class. This allows for Matlab to directly send commands within an installed anaconda environment. There is limited functionality for passing information back from python to Matlab; the purpose of this class is to batch process in Python packages within Anaconda, invoked by Matlab. This works best if there is a file output by the packages, which can then be subsequently acted upon in Matlab. This allows for using a mixture of Matlab and Python/Anaconda packages in a batch workflow.

The mat2py_connection talks to python through TCP/IP, which is implemented through the echo_mat.py script, which is copied into the anaconda environment (and subsequently deleted, when done).

Specify a series of python commands in vertical string arrays (or character arrays) and then these can be run in the anaconda environment like so:

_%%Implement the Matlab connection with anaconda_

conda_root='C:\Users\Admin\anaconda3\';
conda_package='XXXXXXX';
tcpport=50028;
echo_mat='C:/Users/Admin/Documents/Matlab/echo_mat.py';
m2p=mat2py_connection(tcpport,conda_root,conda_package,echo_mat);


_%%Specify commands_

command_string_array=["command 1";"command 2";"command 3"];


_%%Append carriage returns to each command (and convert to string if you give a character array)_
command_string_array=commandify(command_string_array);


_%%Execute a series of commands in the Python package within the conda environment_
out=m2p.py_command(command_string_array);


_%%Close TCP/IP connection_
m2p.terminate_connect
