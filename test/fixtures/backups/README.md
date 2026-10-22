# Backup compatibility fixture

`pre_ayah_notes_v1.talia` was generated with the unchanged
`lib/core/backup/backup_file_format.dart` encoder from commit
`a15bee823e8dbed228ab9fa3fb224be3fc8f9d2a`, before ayah notes and schema v2.
It contains the six original v1 sections, all empty, and a fixed creation
time of `2026-10-18T00:00:00.000Z`. It contains no personal or religious text.

SHA-256: `2afb45eed5926184c7c51640563a55af11dcdb315e350c81dd7c3c0168dc0fbf`.

Keep this fixture unchanged when the current exporter changes. Its purpose
is to exercise decoding and restoration of a file produced by the old encoder.
