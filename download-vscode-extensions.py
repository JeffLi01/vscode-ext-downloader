#!/bin/env python

import argparse
import copy
import logging
from logging import debug, error, info, warning
import os
import sys
import time
import urllib.request


def get_extensions_from_file(filename):
    extensions = []
    with open(filename) as f:
        for line in f:
            identifier, version = line.strip().split("@")
            publisher, name = identifier.split(".", maxsplit=1)
            extension = (publisher, name, version)
            debug(f"found extension: {extension}")
            extensions.append(extension)
    return extensions

def download_extension(extension, output):
    publisher, name, version = extension
    url = f"https://marketplace.visualstudio.com/_apis/public/gallery/publishers/{publisher}/vsextensions/{name}/{version}/vspackage"
    try:
        res = urllib.request.urlopen(url)
        content = res.read()
        with open(output, "bw") as f:
            f.write(content)
        return 0
    except urllib.error.HTTPError as err:
        if err.code == 429:
            warning("too many request, move to end of queue to retry")
            return 1
        else:
            error(err.code, err.reason)
            return 1

def download_extensions(extensions):
    total = len(extensions)
    exts = copy.copy(extensions)
    while len(exts) > 0:
        next = total - len(exts) + 1
        ext = exts.pop(0)
        publisher, name, version = ext
        filename = f"{publisher}.{name}-{version}.vsix"
        if os.path.exists(filename):
            info(f"{next}/{total}: {ext}: already exists")
            continue
        info(f"{next}/{total}: {ext}: downloading")
        if download_extension(ext, filename) == 1:
            exts.append(ext)
            time.sleep(1)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file", help="file contains vscode extension list including version", required=True)
    parser.add_argument('--verbose', '-v', action='count', default=0)

    args = parser.parse_args()
    if args.verbose == 0:
        level = logging.WARNING
    elif args.verbose == 1:
        level = logging.INFO
    else:
        level = logging.DEBUG

    FORMAT = '%(asctime)s %(message)s'
    logging.basicConfig(format=FORMAT, level=level)

    extensions = get_extensions_from_file(args.file)
    
    if len(extensions) == 0:
        info("no extensions to download")
        return -1

    download_extensions(extensions)

    return 0


if __name__ == "__main__":
    sys.exit(main())
