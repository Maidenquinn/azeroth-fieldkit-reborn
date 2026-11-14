FieldKit Reborn 0.1.0-reborn.21

Empty/dead/incomplete guardian or boss rows no longer create 0/0 cards. Repeated ids are displayed once. Endless boss progression now reads the native rift percentage even when the campaign schedule is empty. An absent boss name is shown as “Next boss”; an absent percentage is never derived from time.

FieldKit stays visible behind reward choices with child input disabled and layers kept below the cards. Native replacement ownership remains active, so counters, jewelry, meter and progression do not return as duplicates. Each frame’s prior input, opacity and layer are restored afterwards. Preview controls remain hidden during choices.

Spells read explicit bonus/upgrade sections directly from fresh AZS_SPELLTIPS, as well as available action tooltips, without displaying the entire base description. The public API does not provide a structured per-spell upgrade breakdown. Descriptions without explicit bonus sections cannot supply those values; a developer request is prepared in docs/DEVELOPER_API_REQUEST_21.md.

Validation: offline regression for invalid/duplicate guardians, endless zero/missing/37% values and missing names, choice HUD in theme off/minimal/complete/alternative, child mouse/strata restoration, native duplicate suppression and native spell bonus extraction; full runtime and installed 0.6.5 public API fixtures. No new live client test is claimed.
