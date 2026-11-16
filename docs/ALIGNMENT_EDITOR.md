# HUD alignment editor — .36-dev

Open **Interface > Layout & arrange > Align HUD**, or `/fieldkit align`.
This editor keeps the actual active theme. The older Previews flow continues to arrange sample cards without a theme.

- Centre-based grid, spacing 8–64 UI pixels, independent grid and snap toggles.
- Snap on release within eight UI pixels: with the grid visible, only its lines are targets for the visible top-left anchor. With the grid hidden, screen/peer edges and centres are targets. Guides and drawing share the same bounded spacing, including extreme viewports. Visible themed card bounds use the collision engine's insets.
- Existing overlap rules can displace a card when an otherwise aligned position would collide. The grid never rewrites anchors merely by opening it.
- Existing grouped cards keep their group movement. Native bars/minimap use their existing direct-drag controls. The editor temporarily unlocks and restores the previous lock when closed.
- Preferences belong to each HUD profile. Existing schema-2 slots are hydrated with newly declared preferences before validation, without replacing their saved layouts.
- Chat automatically exposes its Move chat handle while either editor is open, regardless of chatStyle/chatMove. These preferences and chat-copy opt-in are never changed. Closing the editor finishes any held drag and restores the normal mover state. Editor-chosen native positions persist even with styling disabled, without changing font, size, colours or message capture. The themed chat moves its whole card.
- The overlay reuses texture regions and does not take mouse input.

The minimap candidate normalizes its local scale inside a themed owner and restores the native scale on exit. Position, size, effective scale and viewport changes invalidate the native renderer cache. No replacement map texture or native data edits are involved.

## Validation

Synthetic tests cover 1920x1080, 2560x1080, 3440x1440 and 1280x720 geometry; all six reference layouts (including the unavailable Naxx research layouts); scaled anchor conversion; profile persistence and .35 upgrade; bounded texture reuse; minimap cache invalidation and exact scale restoration.

Native client 0.6.8 at 1920x1080: the grid and toolbar displayed with the current unthemed French profile and the Elwynn English profile. Spacing and Done responded, and the original .35 profiles switched after correcting missing new preferences. The existing map stayed within the themed frame at this resolution. Automated drag injection did not visibly move the cards while paused; actual mouse dragging/snapping is NOT certified. The supplied ultrawide overflow has NOT yet been visually reproduced or certified fixed at 2560x1080.

## Remaining player recipe

1. With no reward choice open, enter Align HUD; move an unthemed card and native minimap/bar. Check near-grid drops with snap on, then off.
2. Repeat with Elwynn, including campaign bosses and a grouped card. Verify overlap prevention still applies and the minimap moves with its frame.
3. Adjust spacing, toggle grid, exit, switch profiles and reload. Check saved positions, spacing and lock restoration.
4. At 2560x1080 verify minimap containment after resize, drag, profile switch and reload. Repeat after changing window dimensions if available.

The native QA used external verified profile copies. FieldKit and Stats .lua/.bak files are restored byte-for-byte after the test; private evidence and account data are never committed. This candidate is not published.
