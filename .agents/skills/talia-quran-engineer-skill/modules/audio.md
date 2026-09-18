# Audio

Cover play, pause, seek, queue/reciter state, current ayah synchronization, interruption, background/resume, screen lock, app lifecycle, subscriptions, and device/Bluetooth changes when relevant.

A wrong highlighted ayah with valid playback may be a synchronization defect rather than a player failure. Trace player position → queue/current item → ayah mapping → UI state before changing the player itself.

For Quran audio, load `quran-engine.md` and `quran-integrity.md` when identifiers or recitation mappings are touched.
