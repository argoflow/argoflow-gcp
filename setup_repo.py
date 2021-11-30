#!/usr/bin/env python3

import argparse
from os import path, walk

root_dir = path.dirname(path.realpath(__file__))


parser = argparse.ArgumentParser(description="Configurate the repository")
parser.add_argument("--config", "-c", help="The setup config file path.")
parser.add_argument(
    "--distribution", "-d", default="distribution", help="The distribution directory."
)

args = vars(parser.parse_args())

placeholders = []
with open(path.join(root_dir, args["config"]), "r") as f:
    for line in f.readlines():
        if line.strip() != "":
            placeholders.append(line.split("="))

for (dirpath, _, filenames) in walk(path.join(root_dir, args["distribution"])):
    for filename in filenames:
        p = path.join(dirpath, filename)
        content = ""
        with open(p, "r") as f:
            content = f.read()
            for placeholder in placeholders:
                content = content.replace(
                    placeholder[0].strip(), placeholder[1].strip()
                )

        with open(p, "w") as f:
            f.write(content)
