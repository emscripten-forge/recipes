import yaml
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("recipe_dir")
args = parser.parse_args()

with open(f"{args.recipe_dir}/recipe.yaml", 'r') as stream:
    parsed_yaml=yaml.safe_load(stream)
    print(parsed_yaml['package']['name'])