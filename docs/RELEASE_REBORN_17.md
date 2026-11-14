FieldKit Reborn 0.1.0-reborn.17 — choice-screen restoration

First-launch and profile-preview controls now yield to native level-up and jewelry choices. Preference transactions release the temporary choice opacity mask before changing presentation ownership and apply it again after the new skin. This avoids saving an invisible frame as its normal presentation during a theme switch.

The native counter strip now uses the verified packaged chest icon. The themed target frame follows the horde/progress gauges instead of overlapping them; known empty jewelry slots display Empty.

The compact first-launch defaults from .16 are retained: independent native cards at 85%, four character bonuses, one counter strip including event currency, direct boss progress and an elapsed clock. Existing preferences and profile slots are preserved.

Validation: repeated empty-database previews, cancellation/logout isolation and choice/theme switching regressions; full offline runtime/settings suites and installed 0.6.5 API/content fixtures, including all meter windows from 5 to 120 seconds.

Live campaign observations: real spell damage, kills, horde and boss progress were present in the themed HUD. The switch to unthemed display coincided with a reward choice and exposed the preview toolbar overlap and masked-presentation problem addressed here. One run ended in death before the agent re-paused; the agent spent no revival resources. The campaign pass also inspected unthemed compact defaults, a real health jewelry bonus, six slots, counter ownership and difficulty/HUD recovery after reload. The final chest icon was visible after reload; final target geometry and known-empty labels are regression-tested offline. A complete live boss encounter and co-op pass remain unverified. Offline checks do not replace these remaining acceptance steps.
