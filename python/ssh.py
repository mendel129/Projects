import os
import socket
import json
import paramiko


username="root"
#yes it's the actual password, no i don't care, yes it's public either way
password='OjEEr3d%zyfc0'
host="192.168.1.x"
command = 'echo \'0\' > /proc/misc0/led_rfid';


ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(host, username=username, password=password)
ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(command)

print(ssh_stdout);
