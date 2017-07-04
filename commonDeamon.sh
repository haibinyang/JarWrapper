#!/bin/bash
#
# jarWrapper    Startup script for the RunDeck Launcher install
#   paramaters:
#     - env vars: []
#     - standard RDECK_PORT values: [http: 4440, https: 4443]

# 主目录
BASE_DIR="/home/yanghaibin/deployWorkspace"

# 检查主目录是否可写
[ -w $BASE_DIR ] || {
    echo "BASE_DIR dir not writable: $BASE_DIR"
    exit 1;
}

# 二级目录：upload和instance
UPLOAD_DIR="$BASE_DIR/upload"
INSTANCE_DIR="$BASE_DIR/instance"
mkdir -p $UPLOAD_DIR
mkdir -p $INSTANCE_DIR

# 读取参数
action=$1
serviceName=$2

if [ -z $action ]; then
  echo "action is unset";
  exit 1
fi

if [ -z $serviceName ]; then
  echo "serviceName is unset";
  exit 1
fi

echo "action: $action"
echo "serviceName: $serviceName"

# 创建serviceName下的子目录
JAR_DIR=$INSTANCE_DIR/$serviceName/jar
PID_DIR=$INSTANCE_DIR/$serviceName/pid
LOK_DIR=$INSTANCE_DIR/$serviceName/lock
LOG_DIR=$INSTANCE_DIR/$serviceName/log

mkdir -p $JAR_DIR
mkdir -p $PID_DIR
mkdir -p $LOK_DIR
mkdir -p $LOG_DIR

# 所有操作都要使用到pid, lock文件
PID_FILE=$PID_DIR/pid
LOK_FILE=$LOK_DIR/lock
echo "PID_FILE: $PID_FILE"
echo "LOK_FILE: $LOK_FILE"


# TODO
uploadJarFilePath=$UPLOAD_DIR/$jarFileName

# head 软链接


#JAR_FILE=$JAR_DIR/${serviceName}.jar
#init和replaceJar才要使用到
#平时是使用header指向的jar吧

JAR_FILE=$JAR_DIR/head #指向真实的 jar 的软链接



echo "JAR_FILE: $JAR_FILE"




# 其它
RETVAL=0
DATE=`/bin/date +%Y%m%d-%H%M%S`

echo_success() {
    echo "[OK]"
    return 0
}

echo_failure() {
    echo "[FAILED]"
    return 1
}

init() {
    RETVAL=0
    echo "init"
    return $RETVAL
}

replacejar() {
    RETVAL=0
    echo "replacejar"

    jarFileName=$3
    if [ -z $jarFullPath ]; then
      echo "jarFullPath is unset";
      return 1
    fi
    echo "jarFileName: $jarFileName"

# 创建一个软链接

    return $RETVAL
}

start() {
    jarFullPath=$JAR_DIR/head
    # 检查是否存在
    


    rundeckd="${JAVA_HOME}/bin/java -jar ${jarFullPath}"

    LOG_FILE=$LOG_DIR/$DATE.log
    echo "LOG_FILE: $LOG_FILE"

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
    PID=`cat $PID_FILE`
    ps -p "$PID" >/dev/null
    RETVAL=$?
    [ $RETVAL -eq 0 ] && {
	echo "$serviceName is running (pid=$PID, port=$RDECK_PORT)"
    } || {
	echo "$serviceName dead but pid file exists"
    }
    return $RETVAL
}

case "$action" in
    init)
  init
  ;;
    replacejar)
  stop
  ;;
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
	#status $rundeckd #临时去除
  status
	RETVAL=$?
	;;
    *)
	echo $"Usage: $0 {start|stop|restart|condrestart|status}"
	RETVAL=1
esac

exit $RETVAL
