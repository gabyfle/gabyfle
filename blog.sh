#!/bin/bash

start_server() {
  echo "Starting Jekyll server..."
  nohup bundle exec jekyll serve > /dev/null 2>&1 &
  echo "Jekyll server is now running in the background."
}

stop_server() {
  echo "Stopping Jekyll server..."
  pkill -f "jekyll serve"
  echo "Jekyll server stopped."
}

case "$1" in
  start)
    start_server
    ;;
  stop)
    stop_server
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

exit 0
