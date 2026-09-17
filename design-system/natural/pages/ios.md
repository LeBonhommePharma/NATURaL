# iOS — phone session

Overrides MASTER for `Bonhomme/` compact width.

- **Nav:** Home catalog (scroll) + History / About in the trailing toolbar. No tab bar of 5+. Session is a full-screen cover, dismiss disabled until End.
- **HUD:** `SessionHUDBar` in the bottom `safeAreaInset` during `.active` only. SCI ring 56pt, HR readout, entropy/tempo/AirPods chips, pose `n/N` last.
- **Hits:** Begin / Pause / End ≥52pt (`phoneControlHeight`). Welcome Continue and `home.start` stay reachable at XXXL.
- **Motion:** Reduce Motion kills SCI glow and numeric content transitions.
- **Do not:** duplicate the large SCI gauge from iPad; put metrics under the notch; use emoji.
