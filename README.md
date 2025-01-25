# Overview
Nginx starter with self signed ssl for local https protocol

## Usages
Ensure you have [devenv](https://github.com/cachix/devenv) and [nix](https://nixos.org/) installed.
Your can modify starter on `devenv.nix` adjust it as you wish.

To run you nginx you can type
```bash
$ devenv up --detach
```

To show process status
```bash
$ devenv shell -- process-compose ls --output wide
```

To stop the process
```bash
$ devenv shell -- process-compose down 
```
