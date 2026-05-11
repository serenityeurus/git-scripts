# get-repos-status

A small Bash utility that scans a directory (default: current working directory) for Git repositories and prints a concise status report for each repository.

## Features

- Detects all Git repos up to a configurable depth (default depth 2).
- Shows the current branch (or detached HEAD info).
- Indicates if the working tree is clean, dirty, or has untracked files.
- Summarises staged, modified and untracked file counts.
- Reports sync status with the remote: ahead, behind, diverged or synced.
- Simple, self‑contained, no external dependencies beyond Git.

## Installation

```bash
# Clone the repository
git clone https://github.com/serenityeurus/git-scripts.git
cd git-scripts/get-repos-status
# Make the script executable (optional if you want to run it directly)
chmod +x get-repos-status.sh
```

You can also copy the script to any location in your `$PATH`.

## Usage

```bash
./get-repos-status.sh [target_directory]
```

- If `target_directory` is omitted, the script scans the current directory.
- The script will print a friendly report for each repository it finds.

### Example output

```
Scanning for git repositories in: /Users/jay/projects
==============================================

📦 my-app
   Path: /Users/jay/projects/my-app
   Branch: main
   Status: dirty (+1 staged ~2 modified ?1 untracked)
   Sync: ahead 2

📦 another-repo
   Path: /Users/jay/projects/another-repo
   Branch: feature/awesome
   Status: clean
   Sync: synced

==============================================
Done.
```

## Customisation

- **Depth** – The script uses `find … -maxdepth 2` to locate `.git` directories. Adjust the `-maxdepth` value inside the script if you need a deeper search.
- **Output format** – Feel free to modify the `echo` statements to output JSON or CSV for machine‑readable consumption.

## Contributing

Pull requests are welcome! If you add a new feature or fix a bug, please:
1. Fork the repository.
2. Create a feature branch.
3. Ensure the script still works on macOS/Linux.
4. Open a PR describing your changes.

## License

MIT – see the [LICENSE](LICENSE) file for details.
