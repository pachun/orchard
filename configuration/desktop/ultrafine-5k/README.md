# UltraFine 5K bringup guard

The LG UltraFine 5K's Thunderbolt link against this XPS 14 trains lane 1
into a marginal state most of the time. A marginally-trained link
collapses seconds-to-minutes after video load starts, producing an
endless ~4 s connect/disconnect loop (and workspace jank on every
cycle). Occasionally training lands well — those links run full
dual-tile 5K indefinitely. Which outcome you get is decided at
link-training time; no host-side setting influences it. Kernel bug
report: ~/ultrafine-5k-bug-report.md (filed against drm/xe +
thunderbolt; this guard is the bridge until the driver retrains
marginal links itself).

The guard turns the lottery into a background process. When the
monitor connects, a udev rule starts `ultrafine-bringup.service`,
which repeatedly:

1. lets the GPU light the display and watches it for a probation
   period — a surviving link means training landed well, so the guard
   exits and leaves it alone;
2. on collapse, forces the DP connectors off so the desktop stays
   calm while the link re-trains, then tries again.

Plug the cable in and wait; the screen comes on when a good link
lands. Worst case observed so far took ~40 minutes of cycling, so the
guard gives up after roughly that long and leaves the connectors
enabled (the natural flap continues, just without the guard's
calming).

Both 5K tiles report the same EDID description and serial, so the
hyprland.conf rule for them is desc-matched once and auto-positioned:
the tiles land side by side as two 2560x2880\@60 outputs at scale 2.
