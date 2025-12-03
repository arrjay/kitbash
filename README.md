## Kitbash

Kitbash is a fork of [babashka](https://github.com/aurynn/babashka), a [babushka][1] like clone, written in bash, originally by [richo](https://github.com/richo).

## Installing

The included [bootstrap.sh] script will install Kitbash on Debian-alike systems.

Clone this repo to the location of your choice, and add `kitbash/bin` to your path.

```bash
git clone https://github.com/aurynn/babashka 
echo "export PATH=$PWD/babashka/bin:\${PATH}" >>.bashrc
```

or, to install system-wide,

```bash
cd /opt
sudo git clone https://github.com/aurynn/kitbash
sudo mkdir /etc/kitbash
cd /etc/kitbash
sudo ln -s /opt/kitbash/dependencies .
sudo ln -s /opt/kitbash/helpers .
sudo ln -s /opt/kitbash/bin/kitbash /usr/bin/kitbash
```


## Organising dependencies

`kitbash` looks for dependencies by searching the `./kitbash/`, `./kitbash/dependencies/` and `/etc/kitbash/provisioners` folders for files ending in `.bash` or `.sh`.

Project-specific dependencies are conventionally kept in `./kitbash/` and global dependencies are conventionally kept in `/etc/kitbash/provisioners`.

Files to be copied to the filesystem are kept in a subdirectory named `files/`, which will not be processed.

For example, `~/projects/myapp/kitbash/deploy.sh` might contain deployment scripts for an app called `myapp`, while `/etc/kitbash/provisioners/packages.sh` might contain dependencies which install packages you commonly need on new systems.

## Custom dependency directories

`kitbash` takes an argument, `-d`, to add another search path for dependencies.

## Files

kitbash will ignore anything in subdirectories named `files/`. This is to allow for files that will be moved into the filesystem to be included in a kitbash directory tree.

## Built-ins

kitbash comes with a number of built-in functions to make developing your infrastructure-as-code easier. Documentation (in-progress) for these builtins is in [docs/README.md](docs/README.md).

## Templating

`kitbash` comes with the built-in `system.file.template`, which takes advantage of [Mo](https://github.com/tests-always-included/mo). This is an optional dependency.

## Writing dependencies

Write dependencies with a similar form to their babushka counterparts:

```bash

# dep zsh_installed
zsh_installed() {
  function is_met() {
    which zsh
  }
  function meet() {
    sudo apt-get -y install zsh
  }
  process # Process line is important, you must include it.
}

# dep mysql_environment
mysql_environment() {
  requires "mysql_server"
  requires "mysql_client"
  # Don't need process if this dep doesn't have meet or is_met
}

mysql_server() {
  function is_met() {
    which mysqld
  }
  function meet() {
    sudo aptitude install mysql-server
  }
  process
}

mysql_client() {
  function is_met() {
    which mysql
  }
  function meet() {
    sudo aptitude install mysql-client
  }
  process
}
```

## Running deps

Then invoke:

```bash

kitbash zsh_installed
kitbash mysql_environment
```

## What people are saying about kitbash

"This is absolutely f**king cursed"
~ [@ryankurte](https://twitter.com/ryankurte)

[1]: https://babushka.me
