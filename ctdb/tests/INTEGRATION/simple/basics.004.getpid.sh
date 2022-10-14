#!/usr/bin/env bash

# Verify that 'ctdb getpid' works as expected

. "${TEST_SCRIPTS_DIR}/integration.bash"

set -e

ctdb_test_init

try_command_on_node 0 "$CTDB listnodes | wc -l"
num_nodes="$out"
echo "There are $num_nodes nodes..."

# Call getpid a few different ways and make sure the answer is always the same.

try_command_on_node -v 0 "onnode -q all $CTDB getpid"
pids_onnode="$out"

cmd=""
n=0
while [ $n -lt $num_nodes ] ; do
    cmd="${cmd}${cmd:+; }$CTDB getpid -n $n"
    n=$(($n + 1))
done
try_command_on_node -v 0 "( $cmd )"
pids_getpid_n="$out"

if [ "$pids_onnode" = "$pids_getpid_n" ] ; then
    echo "They're the same... cool!"
else
    die "Error: they differ."
fi

echo "Checking each PID for validity"

n=0
while [ $n -lt $num_nodes ] ; do
    read pid
    try_command_on_node $n "ls -l /proc/${pid}/exe | sed -e 's@.*/@@'"
    echo -n "Node ${n}, PID ${pid} looks to be running \"$out\" - "
    case "$out" in
    ctdbd) : ;;
    memcheck*)
	    if [ -z "$VALGRIND" ] ; then
		    die "BAD"
	    fi
	    ;;
    *) die "BAD"
    esac

    echo "GOOD!"

    n=$(($n + 1))
done <<<"$pids_onnode"
