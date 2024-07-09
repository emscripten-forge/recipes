import sys
import subprocess
if __name__ == '__main__':

    # get all the arguments
    args = sys.argv[2:]

    filtered_args = []
    for arg in args:
        print("arg:", arg)
        if "-Wl,-R$PREFIX/lib" in arg:
            print("removed -Wl,-R$PREFIX/lib")
            continue
        filtered_args.append(arg)
    
    # run the actual command in argv[1]
    subprocess.run([sys.argv[1]] + filtered_args)

    