#!/bin/sh
# Fix ownership of the mounted volume (Railway volumes mount as root)
chown -R node:node /paperclip /app/workspace 2>/dev/null || true

# Drop to node user and start the server
exec su -s /bin/sh node -c 'node --import ./server/node_modules/tsx/dist/loader.mjs server/src/index.ts'
