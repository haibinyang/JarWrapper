#!/bin/bash
#
# rundeckd    Startup script for the RunDeck Launcher install
#   paramaters:
#     - env vars: [RDECK_BASE, RDECK_PORT, RDECK_LAUNCHER]
#     - standard RDECK_PORT values: [http: 4440, https: 4443]


action=$4
prog=$1
RDECK_BASE=$2
RDECK_LAUNCHER=$3

if [ -z $action ]; then
  echo "action is unset";
  exit 1
fi

if [ -z $prog ]; then
  echo "prog is unset";
  exit 1
fi

if [ -z $RDECK_BASE ]; then
  echo "RDECK_BASE is unset";
  exit 1
fi

if [ -z $RDECK_LAUNCHER ]; then
  echo "RDECK_LAUNCHER is unset";
  exit 1
fi

echo "action: $action"
echo "prog: $prog"
echo "RDECK_BASE: $RDECK_BASE"
RDECK_LAUNCHER=$RDECK_BASE/$RDECK_LAUNCHER
echo "RDECK_LAUNCHER: $RDECK_LAUNCHER"

echo_success() {
    echo "[OK]"
    return 0
}

echo_failure() {
    echo "[FAILED]"
    return 1
}

rundeckd="${JAVA_HOME}/bin/java ${RDECK_JVM} -jar ${RDECK_LAUNCHER}"
RETVAL=0
PID_FILE=$RDECK_BASE/var/run/${prog}.pid
LOK_FILE=$RDECK_BASE/var/lock/subsys/$prog
servicelog=$RDECK_BASE/var/log/${prog}.log

echo "PID_FILE: $PID_FILE"
echo "LOK_FILE: $LOK_FILE"
echo "servicelog: $servicelog"

echo

[ -w $RDECK_BASE/var ] || {
    echo "RDECK_BASE dir not writable: $RDECK_BASE"
    exit 1 ;
}

mkdir -p $RDECK_BASE/var/run
mkdir -p $RDECK_BASE/var/log
mkdir -p $RDECK_BASE/var/lock/subsys

start() {
    RETVAL=0
    printf "%s" "Starting $prog: "
    [ -f $LOK_FILE -a -f $PID_FILE ] && {
	echo_success; #already running
	return $RETVAL
    }
    nohup $rundeckd >>$servicelog 2>&1 &
    RETVAL=$?
    PID=$!
    echo $PID > $PID_FILE
    if [ $RETVAL -eq 0 ]; then
	touch $LOK_FILE
	echo_success
    else
	echo_failure
    fi
    return $RETVAL
}

stop() {
    RETVAL=0
    printf "%s" "Stopping $prog: "
    [ ! -f $PID_FILE ] && {
	echo_success; #already stopped
	return $RETVAL
    }
    PID=`cat $PID_FILE`
    RETVAL=$?
    [ -z "$PID" ] && {
	echo_failure; #empty pid value"
	return $RETVAL;
    }
    ps -p "$PID" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
	kill $PID >/dev/null 2>&1
	RETVAL=$?
	[ $RETVAL -eq 0 ] || {
	    echo_failure; # could not kill process
	    return $RETVAL
	}
    fi
    rm -f $PID_FILE; # Remove control files
    rm -f $LOK_FILE
    echo_success
    return $RETVAL
}

status() {
    RETVAL=0
    printf "%s" "Status $prog: "
    test -f "$PID_FILE"
    RETVAL=$?
    [ $RETVAL -eq 0 ] || {
	echo "$prog is stopped";
	return 3;
    }
    echo "4"
    PID=`cat $PID_FILE`
    ps -p "$PID" >/dev/null
    RETVAL=$?
    [ $RETVAL -eq 0 ] && {
	echo "$prog is running (pid=$PID, port=$RDECK_PORT)"
  echo "5"
    } || {
	echo "$prog dead but pid file exists"
  echo "6"
    }
    return $RETVAL
}

case "$action" in
    start)
	start
	;;
    stop)
	stop
	;;
    restart)
	stop
	start
	;;
    condrestart)
	if [ -f $LOK_FILE ]; then
	    stop
	    start
	fi
	;;
    status)
	status $rundeckd
	RETVAL=$?
	;;
    *)
	echo $"Usage: $0 {start|stop|restart|condrestart|status}"
	RETVAL=1
esac

echo "8"
exit $RETVAL
