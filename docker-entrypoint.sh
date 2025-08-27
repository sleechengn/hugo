#!/usr/bin/bash
source /opt/venv/bin/activate
nohup nginx > /dev/null &
nohup filebrowser -d /opt/filebrowser/filebrowser.db -a 127.0.0.1 -p 8081 -b /filebrowser -r / --noauth > /dev/null &
nohup ttyd --port 8082 --base-path /ttyd /usr/bin/bash > /dev/null &

/usr/bin/code-server $*
