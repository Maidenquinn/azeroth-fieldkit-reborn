Hi! Could we clarify and complete the endless next-boss API for third-party HUDs?

The official addon guide exposes AZS_RUN.endless/endl, nbn, nb and rift, plus AZS_SCHEDULE. FieldKit now keeps its endless indicator visible even if there is no due schedule entry or rift charge, and reports missing data rather than inventing a percentage from the run clock or nb.

Could the API expose, for every endless cycle (including after /reload):
- A stable cycle/encounter id and whether its next boss is known.
- The next boss's localized name, or an explicit unknown state if chosen later.
- Its spawn mechanism (charge/kills/time/other), current value and threshold, or a normalized 0..1 charge with an explicit availability status.
- The corresponding update event/snapshot, and which existing rift/nbn fields remain valid once the campaign schedule has been exhausted.

A player reports that the next-boss indicator disappears on entering endless. The HUD now distinguishes missing API charge from a genuine 0%, but future identity/charge cannot be reconstructed reliably if the server omits them. Is there an existing public API we should use instead?

Thanks!
