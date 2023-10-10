# VS Code Extension Downloader

## How to Use

Run below code:

```bash
code --list-extensions --show-versions > vscode-extension-list.txt
python3 download-vscode-extensions.py -f vscode-extension-list.txt
```

Extensions will be downloaded to current folder.
