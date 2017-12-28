# Update scripts for docker(-compose) env files

Supplying environment variables through files is a convenient way to manage a larger number of configuration options applied through environment variables. Both, [docker](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e-env-env-file) and [docker-compose](https://docs.docker.com/compose/env-file/) support reading environment variables from a file.

## Docker

> You can also load the environment variables from a file.
> This file should use the syntax `<variable>=value` (which
> sets the variable to the given value) or `<variable>`
> (which takes the value from the local environment),
> and `#` for comments.

Note: Only the `<variable>=value` syntax, blank lines and comments are supported by this collection of scripts (i.e. not `<variable>`). Please feel free submitting merge requests to overcome this shortcoming.

## Docker-compose

> Compose supports declaring default environment variables
> in an environment file named `.env` placed in the folder
> where the `docker-compose` command is executed (*current
> working directory*).

> These syntax rules apply to the .env file:
>
> - Compose expects each line in an `env` file to be in `VAR=VAL` format.
> - Lines beginning with `#` (i.e. comments) are ignored.
> - Blank lines are ignored.
> - There is no special handling of quotation marks (i.e. **they will be part of the VAL**, you have been warned ;) ).

## Contents

- Limitations: Might not handle literal `\n` in comments correctly. Please submit merge requests.
- Requirements: Bash version 4 support or higher

### update-env.sh

- Updates an existing `.env` file with missing variables from a template file by prompting for their value (offering a default from the template).
- Tracks who made the additions and when the additions were made.
- Prints possibly unused/obsolete variables to stdout.

### prettify-env.sh

- Re-creates an existing `.env` file using a templates fills missing variables by prompting for their value (offering a default from the template)
- Adds possibly unused/obsolete variables in a bottom section.
- Because the whole file is rewritten each time, the template structure is restored. With `diff .env.example .env` changes to the default values from the template are easily spotted.

## Useful snippets

### Convert Docker `.env` file to bash-compatible `.env` file format

```sh
cat .env | sed -rn 's/(.+?)\=(.+)/\1="\2"/p' > .env.bash
```

## Git: Self-update when checking out another version

Git provides so-called hooks. The `post-checkout` hook script is executed by git after a new version is checked out (e.g. after a `git pull` or a `git checkout hash/tag/version`). This allows for keeping your `.env` file automatically up-to-date. Note that hooks are a local concept and do not become part of the repository, so install them in each clone of your repo you need them on.

Example:
0. Assuming that your template file's name is `.env.example` and your env file's name is `.env`.
1. In your repository create a `.git/hooks/post-checkout` file with the follwing contents:

```sh
#!/bin/sh
#
# After you run a successful git checkout, the post-checkout hook runs;
# you can use it to set up your working directory properly for your
# project environment. This may mean moving in large binary files that
# you don’t want source controlled, auto-generating documentation, or
# something along those lines.

if [ -f prettify-env.sh ]; then
  bash prettify-env.sh .env.example .env
else
  echo "prettify-env.sh not found. Your .env file won't be updated."
fi
```

2. Put a copy of `prettify-env.sh` into your repository (example is for the working directory but it should also work in the hidden `.git` directory if you adjust the paths in `.git/hooks/post-checkout` accordingly).
3. Test, however note that `prettify-env.sh` will remove all customized comments from `.env`. If you do not wish this behaviour, use `update-env.sh` instead. For instance, try `git checkout master`

