# -*- coding: utf-8 -*-
"""
Created on Wed Mar 29 16:22:08 2023

@author: Admin
"""
import socket
import sys
import time

num_args=len(sys.argv)

try:
    HOST = None               # Symbolic name meaning all available interfaces
    if num_args>1:
        PORT = int(sys.argv[1])              # Arbitrary non-privileged port
    else:
        PORT = 50025
    s = None
    for res in socket.getaddrinfo(HOST, PORT, socket.AF_UNSPEC,
                                  socket.SOCK_STREAM, 0, socket.AI_PASSIVE):
        af, socktype, proto, canonname, sa = res
        try:
            s = socket.socket(af, socktype, proto)
        except socket.error as msg:
            s = None
            continue
        try:
            s.bind(sa)
            s.listen(1)
        except socket.error as msg:
            s.close()
            s = None
            continue
        break
    if s is None:
        print('Python could not open socket')
        exit()
    conn, addr = s.accept()
    conn.setblocking(0)
    conn.send(str.encode('Start','utf-8'))
    conn.send(str.encode('\n','utf-8'))

    while 1:
        try:
            data_temp = conn.recv(1024)
            if data_temp:
                data=data_temp.decode()
            while data_temp:
                try:
                    data_temp = conn.recv(1024)
                    data = data + data_temp.decode()
                except:
                    break
            output = data
            if output=='terminate_pylink':
                s.close()
                break
            if output:
                if len(output)>6 and output[0:7]=='*query:':
                    try:
                        dict_l=locals();
                        var_name=dict_l[output[7:]]
                        conn.send(str.encode(str(var_name),'utf-8'))
                        conn.send(str.encode('\n','utf-8'))
                    except:
                        pass    
                else:
                    try:
                        exec(output)
                        conn.send(str.encode('S','utf-8'))
                        conn.send(str.encode('\n','utf-8'))
                    except Exception as inst:
                        conn.send(str.encode('F','utf-8'))
                        conn.send(str.encode('\n','utf-8'))
                        conn.send(str.encode(str(inst),'utf-8'))
                        conn.send(str.encode('\n','utf-8'))
                        print(str(inst))
        except:
            pass
except:
    print('Python echo error')
    
