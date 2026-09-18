# Runtime Validation

Select relevant scenarios rather than blindly running everything:

- clean state and existing user state.
- enter flow → leave → re-enter.
- background/resume; restart/process recreation when relevant.
- offline, slow network, and error paths.
- Arabic RTL and English LTR.
- text scaling, long content, small screens, keyboard/safe areas.
- Android back/navigation and platform lifecycle where applicable.
- upgrade from old persisted data when migrations/state changes are involved.

Record exactly which scenarios were run and what was not verified.
