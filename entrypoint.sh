#!/bin/sh
# Fix ownership of the mounted volume (Railway volumes mount as root)
chown -R node:node /paperclip /app/workspace 2>/dev/null || true

# Auto-onboard if config doesn't exist yet
if [ ! -f /paperclip/instances/default/config.json ]; then
  echo "No config found, running onboard..."
  su -s /bin/sh node -c 'cd /app && node cli/node_modules/tsx/dist/cli.mjs cli/src/index.ts onboard --yes'
fi

# Drop to node user and start the server
exec su -s /bin/sh node -c 'node --import ./server/node_modules/tsx/dist/loader.mjs server/src/index.ts'
