
pgstatus() {
    local PG_DIR="$HOME/.pgenv"
    local versiondir version bindir datadir
    for versiondir in $PG_DIR/data/*
    do
        version=${versiondir##*/}
        bindir="$PG_DIR/versions/$version/bin"
        for datadir in $versiondir/*
        do
            if [ -d "$bindir" ]; then
                "$bindir/pg_ctl" -D "$datadir" status | grep PID | sed -n "/pg_ctl:/s//$version: PostgreSQL $($bindir/pg_ctl --version | awk '{print $3}'):/p"
            else
                echo  "WARNING: datadir $datadir without corresponding executables in $bindir"
            fi
        done
    done
}

_pgenv_hook() {
    if [[ -n "$PG_VERSION" ]]
    then
	if [[ "$PG_BRANCH" = dev ]]
	then
            echo -n "{pgDEV} "
	else
            echo -n "{pg$PG_VERSION} "
	fi
    fi
}

if ! [[ "$PROMPT_COMMAND" =~ _pgenv_hook ]]; then
    PROMPT_COMMAND="_pgenv_hook;$PROMPT_COMMAND";
fi

pgworkon() {
    local PG_DIR="$HOME/.pgenv"
    local SOURCE_DIR="$HOME/pgsql"
    local CURRENT_DEVEL=10
    local BASE_PORT=54

    if [ -n "$2" ]
    then
        (
            pgworkon "$1"
            shift
            # alias the pg* functions to a more intuitive name
            stop(){ pgstop "$@";}
            start(){ pgstart "$@";}
            restart(){ pgrestart "$@";}
            reinit(){ pgreinit "$@";}
            "$@"
        )
        return
    fi

    usage() {
        [ -n "$1" ] && echo "$1" 1>&2
        echo 1>&2
        echo "usage: $0 pg_version [command]" 1>&2
    }

    case "$1" in
      "")
        usage "ERROR: missing argument"
        return 1
        ;;
      dev)
        PG_BRANCH=dev
        PG_VERSION=$CURRENT_DEVEL
        BASE_PORT=64
        ;;
      master|$CURRENT_DEVEL)
        PG_BRANCH=master
        PG_VERSION=$CURRENT_DEVEL
        ;;
      *)
        PG_BRANCH="REL${1/./_}_STABLE"
        PG_VERSION="$1"
        ;;
    esac

    local DIR="$SOURCE_DIR/$PG_BRANCH"
    local BINDIR="$PG_DIR/versions/$PG_BRANCH/bin"
    local DATADIR="$PG_DIR/data/$PG_BRANCH/main"
    if [ ! -d "$DIR" ]
    then
        usage "Unknown version $1"
        return 1
    fi
    if [ -z "$PG_OLD_PATH" ]; then
        PG_OLD_PATH=$PATH
    fi
    PGSRC=$DIR
    export PATH="$BINDIR:$PG_OLD_PATH"
    export PGDATA="$DATADIR"
    export PGDATABASE="postgres"
    export PGUSER="postgres"
    export PGPORT=${BASE_PORT}${PG_VERSION/./}
    export PGHOST=/tmp

    if which dpkg-architecture > /dev/null; then
        # No undo action on pgdeactivate. Having libreadline preloaded
        # shouldn't be of any harm
        if ! [[ "$LD_PRELOAD" =~ 'libreadline.so' ]]
        then
            export LD_PRELOAD=/lib/$(dpkg-architecture -qDEB_BUILD_GNU_TYPE)/libreadline.so.6:$LD_PRELOAD
        fi
    fi

    pgreinit() {
        pgstop
        rm -fr "$PGDATA"
        mkdir -p "$PGDATA"
        initdb -U postgres $([ ${PG_VERSION/./} -ge 93 ] && echo '-k')
        cat <<-EOF >> "$PGDATA/postgresql.conf"
archive_mode = on
archive_command = 'cd .'
checkpoint_completion_target = 0.9

# Sane logging
logging_collector = on
log_directory = '/tmp'
log_filename = 'pgsql-$PG_BRANCH.log'
log_min_duration_statement = 0
log_autovacuum_min_duration = 0
log_min_messages = info
log_lock_waits = on
log_checkpoints = on
log_temp_files = 0
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d '
EOF
        if [ ${PG_VERSION/./} -ge 90 ] && [ ${PG_VERSION/./} -lt 95 ]
        then
            echo "wal_level = hot_standby" >> "$PGDATA/postgresql.conf"
        elif [ ${PG_VERSION/./} -ge 95 ]
        then
            echo "wal_level = logical" >> "$PGDATA/postgresql.conf"
            echo "track_commit_timestamp=on" >> "$PGDATA/postgresql.conf"
        fi
        if [ ${PG_VERSION/./} -ge 90 ]
        then
            echo "hot_standby = on" >> "$PGDATA/postgresql.conf"
            echo "max_wal_senders = 10" >> "$PGDATA/postgresql.conf"
        fi
        if [ ${PG_VERSION/./} -ge 94 ]
        then
            echo "max_replication_slots = 10" >> "$PGDATA/postgresql.conf"
        fi
        if [ ${PG_VERSION/./} -le 94 ]
        then
            echo "checkpoint_segments = 32" >> "$PGDATA/postgresql.conf"
        fi
        cat <<-EOF >> "$PGDATA/pg_hba.conf"
local replication postgres trust
host  replication postgres 127.0.0.1/8 trust
host  replication postgres ::1/128 trust
EOF
        :> /tmp/pgsql-$PG_BRANCH.log start
        pgstart
    }

    pgstop() {
        if pg_ctl status &> /dev/null
        then
            pg_ctl stop -m fast
        else
            echo "PostgreSQL $PG_VERSION ($PG_BRANCH) is already stopped"
        fi
    }

    pgstart() {
        if ! pg_ctl status &> /dev/null
        then
            pg_ctl -w -l /tmp/pgsql-$PG_BRANCH.log start
        else
            echo "PostgreSQL $PG_VERSION ($PG_BRANCH) is already started"
        fi
    }

    pgrestart() {
        pgstop && pgstart
    }

    pgdeactivate() {
        if [ -n "$PG_OLD_PATH" ]; then
            export PATH=$PG_OLD_PATH
            unset PG_OLD_PATH
        fi
        unset PGSRC PGDATA PGHOST PGDATABASE PGUSER PGPORT PG_BRANCH PG_VERSION
        unset pgdeactivate pgreinit pgstop pgstart pgrestart
    }

    unset usage
}
