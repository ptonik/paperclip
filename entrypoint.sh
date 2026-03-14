#!/bin/sh
# Fix ownership of the mounted volume (Railway volumes mount as root)
chown -R node:node /paperclip /app/workspace 2>/dev/null || true

# Auto-onboard if config doesn't exist yet
if [ ! -f /paperclip/instances/default/config.json ]; then
  echo "No config found, running onboard..."
  su -s /bin/sh node -c 'cd /app && node cli/node_modules/tsx/dist/cli.mjs cli/src/index.ts onboard --yes'
fi

# Sync agent config files from persistent volume to /app/workspace
CEO_WORKSPACE="/paperclip/instances/default/workspaces/45486bdf-ea1a-47b5-8be9-1e18744ffc66"
CEO_TARGET="/app/workspace/agents/ceo"
if [ -d "$CEO_WORKSPACE" ]; then
  mkdir -p "$CEO_TARGET"
  cp -r "$CEO_WORKSPACE"/* "$CEO_TARGET"/ 2>/dev/null || true
  chown -R node:node "$CEO_TARGET"
  echo "Synced CEO agent files to $CEO_TARGET"
fi

# Drop to node user and start the server
exec su -s /bin/sh node -c 'node --import ./server/node_modules/tsx/dist/loader.mjs server/src/index.ts'
