# Pgenv

This is a personal collection of shell scripts to easily develop and test several PostgreSQL at once.

## Install

Checkout the project in ```$HOME/pgsql```

```bash
    git clone https://github.com/mnencia/pgenv.git $HOME/pgsql
```

Add the following lines to ```~/.bashrc```

```bash
    # pgenv
    if [ -r "$HOME/pgsql/pgenv.sh" ] ; then
        . "$HOME/pgsql/pgenv.sh"
    fi
```

Reload the current shell

```bash
    exec bash
```

## Install master version (required)

Initial postgresql checkout

```bash
    git clone git://git.postgresql.org/git/postgresql.git $HOME/pgsql/master
```

In Ubuntu, install these packages, which are necessary for configure-all.sh

```bash
    sudo apt-get install tcl-dev libssl-dev build-essential bison flex \
    libreadline-dev libxml2-dev
```

If you use openSUSE, you must install these packages:

```bash
    sudo zypper in -t pattern devel_C_C++ 
    sudo zypper in tcl-devel libxml2-devel readline-devel libopenssl-devel
```

If you use Archlinux, please be sure that these packages are installed:

```bash
    sudo pacman -S tcl libxml2 openssl bison flex base-devel
```

If you use Mac Os, install the following packages using brew:
    
```bash
    brew install openssl libxml2 readline 
```

Build and install the development head version


```bash
    cd ~/pgsql
    ./configure-all.sh master
    ./install-all.sh master
```

## Install a stable version (optional)

Add a $VERSION checkout (e.g. 9.4, 9.3, etc...)

```bash
    cd ~/pgsql
    ./new-branch.sh $VERSION
```

Build and install the $VERSION version

```bash
    cd ~/pgsql
    ./configure-all.sh $VERSION
    ./install-all.sh $VERSION
```

# Upgrade an existing installation

Upgrade all the installed versions

```bash
    cd ~/pgsql
    ./pull-all.sh
    ./clean-all.sh
    ./configure-all.sh
    ./install-all.sh
```

Upgrade only one version (numeric version or master)

```bash
    cd ~/pgsql
    ./pull-all.sh
    ./clean-all.sh $VERSION
    ./configure-all.sh $VERSION
    ./install-all.sh $VERSION
```

## Usage

### pgworkon

*Usage: pgworkon VERSION [COMMAND]*

set the environment to use the specific version, if a *COMMAND* is specified, execute it
in the target environment but leave the current environment untouched

There are four special commands to be executed directly using pgworkon: start, stop, restart, reinit
This allows to use the following syntax to control the execution status of a version

    pgworkon $VER {start|stop|restart|reinit}

### pgreinit

*Usage: pgreinit*

destroy the current *$PGDATA* and run *initdb* again, , available only after a *pgworkon* call

### pgstop, pgstart, pgrestart

controls the state of the current environment, available only after a *pgworkon* call

### pgdeactivate

reset the state and exit from any environment

### pgstatus

list the running instances
