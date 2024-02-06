kill $(pgrep -f /root/apps/bath/lib/server)
set -e
cd /root/apps/bath
rsync -av /root/dev/apps/bath/ ~/apps/bath
coffee -co lib src/*.coffee
node /root/apps/bath/lib/server.js
