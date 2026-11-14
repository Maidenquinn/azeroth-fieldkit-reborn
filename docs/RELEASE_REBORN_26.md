FieldKit Reborn 0.1.0-reborn.26

Floating damage spell names now use the native AZS_L translations at rendering time. This applies to chat fallback and world-anchored combat events, including grouped hits. Amounts, grouping identities, saved filters and names-off behaviour are preserved; unknown names pass through unchanged.

Validation: Offline regression covers native French spell names in floating combat text from chat and world events, grouped amounts, critical hits, unknown names, live locale refresh, names-off and unchanged saved raw-name filters. Full runtime/settings/theme and installed API checks. No new live client visual test is claimed.
