import os
import re
import sys
import subprocess as sub

def call(cmd) :
    try :
        return sub.check_output(["which", cmd]).decode().strip()
    except sub.CalledProcessError as e :
        #print("command '{}' return with error (code {}): {}".format(e.cmd, e.returncode, e.output))
        return ""

def setup(param) :
    O_param = open(f'./main_param_setup.txt', 'w')
    for line in open(param, 'r') :
        line = line.strip()
        if line.startswith('#') :
            O_param.write(line + "\n")
        elif re.match(r'^\s*$', line) :
            O_param.write(line + "\n")
        else :
            tool = (line.split('='))[0].strip()
            path = (line.split('='))[1].strip()
            
            if path == "" :
                if tool == "OPTION" :
                    O_param.write(line + "\n")
                else :
                    path = str(call(tool))
                    if path == "" :
                        path = str(call(tool.lower()))
                        O_param.write(tool + " = " + path + "\n")
                    else :
                        O_param.write(tool + " = " + path + "\n")
            else :
                O_param.write(line + "\n")

def main() :
    bindir = os.path.abspath(os.path.dirname(__file__))
    bindir = os.path.dirname(bindir)
    param = bindir + "/params/main_param.txt"

    setup(param)

if __name__ == '__main__' :
    main()
