# ChalkBox 2.2.23 — Combat report reliability (Beta)

**This is a test release for World of Warcraft: Forever.** The published **2.2.22 remains stable** until a player verifies reporting on the real client.

The built-in combat meter and ChalkBox compact meter read the native Blizzard `C_DamageMeter` values. Version 2.2.23 only changes what happens when you ask to share a completed fight.

- A manual PARTY or SAY report checks Forever chat restrictions before attempting to send.
- If Forever rejects the report, ChalkBox keeps the exact validated summary in a small text field you can select with **Ctrl+C** and paste into chat yourself. No automatic channel switching and no attempts to bypass protected chat.
- Automatic reports never display surprise copy dialogs, and automatically triggered SAY outside instances is skipped where client restrictions apply.
- Any successful chat API call is described as a **submission request**, not proof other players received the text.
- A valid after-combat report still requires unprotected native combat information; secret values remain protected.

**Test requested:** Fight, leave combat, open Blizzard's native meter gear menu, select **Print top 3 to PARTY**, and report whether a normal send succeeds or the copy dialog appears. Verify `/chalk meter print` also produces a usable summary. Preserve existing SavedVariables. No auction, bag, quest, map or macro behavior was changed.
