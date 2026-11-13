# ChalkBox 2.0.3 — Discoveries window visibility fix

The Discoveries journal has a reliable, readable panel again.

- The window background now stays visible even when Global Appearance background opacity is set to zero. Text and buttons no longer float on an invisible panel.
- Added a subtle framed edge so the full journal boundary remains clear.
- The journal raises itself when opened, while keeping the native world map intact.
- An invalid or unavailable theme callback no longer interrupts Discoveries repainting.
- Added Lua regression tests for transparent themes, appearance refresh errors, and intact journal controls.

The updated presentation does not reset your loot observations, map button position, session history, or other saved options.

This is a Forever-client testing hotfix. Please verify the standalone Discoveries panel and its filters in the live client.

Repository: https://github.com/detok/ChalkBox
