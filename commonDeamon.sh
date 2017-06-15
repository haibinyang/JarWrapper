#!/bin/bash
#
# rundeckd    Startup script for the RunDeck Launcher install
#   paramaters:
#     - env vars: [INSTANCE_DIR, RDECK_PORT, jarFullPath]
#     - standard RDECK_PORT values: [http: 4440, https: 4443]

serviceName=$1
jarFileName=$2
action=$3

UPLOAD_DIR="/home/yanghaibin/deployWorkspace/upload"
INSTANCE_DIR="/home/yanghaibin/deployWorkspace/instance"

jarFullPath=$UPLOAD_DIR/$jarFileName

if [ -z $action ]; then
  echo "action is unset";
  exit 1
fi

if [ -z $serviceName ]; then
  echo "serviceName is unset";
  exit 1
fi

if [ -z $INSTANCE_DIR ]; then
  echo "INSTANCE_DIR is unset";
  exit 1
fi

if [ -z $jarFullPath ]; then
  echo "jarFullPath is unset";
  exit 1
fi

echo "action: $action"
echo "serviceName: $serviceName"
echo "INSTANCE_DIR: $INSTANCE_DIR"
echo "jarFullPath: $jarFullPath"

echo_success() {
    echo "[OK]"
    return 0
}

echo_failure() {
    echo "[FAILED]"
    return 1
}

[ -w $INSTANCE_DIR ] || {
    echo "INSTANCE_DIR dir not writable: $INSTANCE_DIR"
    exit 1 ;
}

JAR_DIR=$INSTANCE_DIR/$serviceName/jar
PID_DIR=$INSTANCE_DIR/$serviceName/pid
LOK_DIR=$INSTANCE_DIR/$serviceName/lock
LOG_DIR=$INSTANCE_DIR/$serviceName/log

mkdir -p $JAR_DIR
mkdir -p $PID_DIR
mkdir -p $LOK_DIR
mkdir -p $LOG_DIR

JAR_FILE=$JAR_DIR/${serviceName}.jar
PID_FILE=$PID_DIR/${serviceName}.pid
LOK_FILE=$LOK_DIR/$serviceName
LOG_FILE=$LOG_DIR/${serviceName}.log

echo "JAR_FILE: $JAR_FILE"
echo "PID_FILE: $PID_FILE"
echo "LOK_FILE: $LOK_FILE"
echo "LOG_FILE: $LOG_FILE"

rundeckd="${JAVA_HOME}/bin/java ${RDECK_JVM} -jar ${jarFullPath}"
RETVAL=0

start() {
    RETVAL=0
    printf "%s" "Starting $serviceName: "
    [ -f $LOK_FILE -a -f $PID_FILE ] && {
	echo_success; #already running
	return $RETVAL
    }
    nohup $rundeckd >>$LOG_FILE 2>&1 &
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
    printf "%s" "Stopping $serviceName: "
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
    printf "%s" "Status $serviceName: "
    test -f "$PID_FILE"
    RETVAL=$?
    [ $RETVAL -eq 0 ] || {
	echo "$serviceName is stopped";
	return 3;
    }
    echo "4"
    PID=`cat $PID_FILE`
    ps -p "$PID" >/dev/null
    RETVAL=$?
    [ $RETVAL -eq 0 ] && {
	echo "$serviceName is running (pid=$PID, port=$RDECK_PORT)"
  echo "5"
    } || {
	echo "$serviceName dead but pid file exists"
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
