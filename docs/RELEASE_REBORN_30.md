FieldKit Reborn 0.1.0-reborn.30

Campaign bosses now participates in the reference theme's shared collision resolver, including preferred anchors, last-dragged priority, viewport/element scale, screen clamping and one-pixel edge clearance. Dragging a roster row moves the card itself. The resolver handles the card in both directions: it yields to other cards and they yield to it. Theme release restores the original parent, row levels and native movement.

Collapsing Campaign bosses places it in the existing shared dock. Repeated data/theme refreshes keep it hidden until its dock button restores it. The dock allocates one control per registered entry and respects the card's enabled setting. No new separate dock or movement handle is introduced.

Validation: Automated bidirectional collision checks, row drag, preferred-position preservation, collapse/dock/restore through repeated refreshes, both theme families and all variants, native restoration; existing campaign data, locale, API and full runtime/settings regressions. No new live-client visual validation is claimed.
