import sys
import subprocess
if __name__ == '__main__':

    args = sys.argv[2:]

    filtered_args = []
    for arg in args:
        if ("-Wl,-R$PREFIX/lib" in arg )or ("-R" in arg):
            print("removed arg:", arg)
        else:
            filtered_args.append(arg)
    
    # run the actual command in argv[1]
    subprocess.run([sys.argv[1]] + filtered_args, check=True)



