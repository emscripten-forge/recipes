if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser(prog="PatchSysConfigData")

    parser.add_argument("--fname-in", required=True)
    parser.add_argument("--fname-out", required=True)
    parser.add_argument("--emcc", required=True)
    parser.add_argument("--emar", required=True)
    parser.add_argument("--emcpp", required=True)

    args = parser.parse_args()

    fname_in = args.fname_in

    with open(fname_in, "r") as f:
        content = f.read()

    content = content.replace(args.emcc, "emcc")
    content = content.replace(args.emcpp, "em++")
    content = content.replace(args.emar, "emar")

    with open(args.fname_out, "w") as f:
        f.write(content)
