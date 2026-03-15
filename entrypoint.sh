#!/bin/sh
# Fix ownership of the mounted volume (Railway volumes mount as root)
chown -R node:node /paperclip /app/workspace 2>/dev/null || true

# Auto-onboard if config doesn't exist yet
if [ ! -f /paperclip/instances/default/config.json ]; then
  echo "No config found, running onboard..."
  gosu node sh -c 'cd /app && node cli/node_modules/tsx/dist/cli.mjs cli/src/index.ts onboard --yes'
fi

# Symlink agent workspaces from persistent volume to /app/workspace/agents/
# Using symlinks instead of copying so all reads/writes go directly to the volume
mkdir -p /app/workspace/agents
sync_agent() {
  local uuid="$1"
  local slug="$2"
  local src="/paperclip/instances/default/workspaces/$uuid"
  local dst="/app/workspace/agents/$slug"
  if [ -d "$src" ]; then
    rm -rf "$dst" 2>/dev/null || true
    ln -sf "$src" "$dst"
    echo "Linked $slug -> $src"
  fi
}

# One-time migration: move workspace dirs from placeholder UUIDs to real UUIDs
migrate_uuid() {
  local old="$1"
  local new="$2"
  local base="/paperclip/instances/default/workspaces"
  if [ -d "$base/$old" ] && [ ! -d "$base/$new" ]; then
    mv "$base/$old" "$base/$new"
    echo "Migrated workspace $old -> $new"
  fi
}
migrate_uuid "9304728a-4529-4a1b-8c2d-3e4f56789012" "9304728a-4529-4bef-89d9-f8735018bd44"
migrate_uuid "a6236d17-b1c2-4d3e-8f4a-567890123456" "a6236d17-546d-46f9-9c88-0f895c54119e"
migrate_uuid "e0a6d5e1-a2b3-4c4d-8e5f-678901234567" "e0a6d5e1-bc0e-466f-a370-9e5bf596f03f"
migrate_uuid "c751f0f7-b3c4-4d5e-8f6a-789012345678" "c751f0f7-245e-482b-a51d-d9f1df762b83"
migrate_uuid "84b78904-c4d5-4e6f-8a7b-890123456789" "84b78904-d858-4481-88df-8465f286494b"

# Agent mappings (add new agents here)
sync_agent "45486bdf-ea1a-47b5-8be9-1e18744ffc66" "ceo"
sync_agent "21e2e5e9-899f-4854-81c5-a1f043d12159" "head-of-ai"
sync_agent "54e42fa8-1d9c-4c39-aabc-00946d88c155" "coo"
sync_agent "613d5540-7c4b-42ff-be46-562b4d589c37" "finance"
sync_agent "aded25d0-beaf-4ac5-9acc-08787b87f950" "project-kickoff"
sync_agent "62593099-89eb-482a-b61e-9cdb99444db5" "cmo"
sync_agent "49866e21-51ee-4150-baaa-d93023be8b46" "social-manager"
sync_agent "58a58bcd-1afa-49dd-93f7-b92650b8c880" "seo-aeo"
sync_agent "4199b7d9-726f-447e-8797-da101d239fbc" "cro"
sync_agent "ca167c77-8efb-4ff4-9527-0f2d6ed598eb" "client-intake"
sync_agent "337ad0e0-1449-4926-9d05-fbeb11a5d740" "cto"
sync_agent "be89d985-28c9-4c48-8374-6e5383102c2b" "engineer"
sync_agent "9304728a-4529-4bef-89d9-f8735018bd44" "design-tooling"
sync_agent "a6236d17-546d-46f9-9c88-0f895c54119e" "innovation-scout"
sync_agent "e0a6d5e1-bc0e-466f-a370-9e5bf596f03f" "client-success"
sync_agent "c751f0f7-245e-482b-a51d-d9f1df762b83" "qa-review"
sync_agent "84b78904-d858-4481-88df-8465f286494b" "competitive-intel"

# Symlink alfred codebase if it exists
if [ -d "/paperclip/instances/default/workspaces/45486bdf-ea1a-47b5-8be9-1e18744ffc66/alfred" ]; then
  ln -sf /paperclip/instances/default/workspaces/45486bdf-ea1a-47b5-8be9-1e18744ffc66/alfred /app/workspace/alfred
  echo "Linked Alfred codebase"
fi

chown -R node:node /app/workspace

# Drop to node user and start the server
exec gosu node node --import ./server/node_modules/tsx/dist/loader.mjs server/src/index.ts
