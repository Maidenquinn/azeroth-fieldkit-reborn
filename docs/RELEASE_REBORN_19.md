FieldKit Reborn 0.1.0-reborn.19

The previous collision fix reduced the nominal gap but still counted transparent native border-atlas gutters as solid artwork. That kept the drawn cards visibly far apart. The collider now follows the visible metal (7 px outsets) rather than the entire backdrop quad (10/18 px outsets). Transparent shadows may overlap while metal borders retain the one-physical-pixel clearance.

The regression now builds actual Mode and Meter card rectangles, verifies one pixel of visible clearance does not trigger a push, and verifies a genuine metal overlap still does. The earlier abstract rectangle test could not catch the extra texture gutters.

Validation: full offline runtime/theme/settings verification and installed client API/content fixtures. No new live client visual pass is claimed. Existing preferences and default anchors are preserved; this changes collision clearance, not saved placement.
