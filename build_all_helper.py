import json


import argparse
parser = argparse.ArgumentParser()
parser.add_argument("jobname")
parser.add_argument("index",type=int)
args = parser.parse_args()


with open('packages.json') as f:
    pairs = json.load(f)['build_jobs'][args.jobname]
    a = [p[args.index] for p in pairs]
    print(*a, sep =', ')
