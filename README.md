# Sky Hop

An original one-tap arcade game for iPhone, built with Swift + SpriteKit.
Tap to flap, guide **Sprout** through the gaps between brick towers, earn medals, and climb the Game Center leaderboard.

Everything — art, sounds, icon — is generated in code or included here, so there's nothing third-party to license.

## What's included

| Feature | Details |
|---|---|
| Gameplay | Tap-to-flap physics, frame-rate independent (smooth at 60 or 120 Hz), fair circular hitbox, gently ramping difficulty |
| Screens | Title, Get Ready, Paused (auto-pauses on calls/notifications), Game Over with animated score count-up |
| Progression | Best score saved on device, bronze / silver / gold / platinum medals (10 / 25 / 50 / 100) |
| Game Center | Sign-in, score submission, leaderboard screen |
| Polish | Parallax hills and clouds, screen shake + flash on crash, haptics, 5 sound effects, sound on/off toggle |
| Audio etiquette | Respects the silent switch and never stops the player's own music |
| App Store plumbing | 1024 app icon, launch screen, privacy manifest, encryption-export flag, review prompt (rarely, only after a good run) |
| Devices | Every iPhone in portrait, iOS 17+ |

## Project layout

```
SkyHop.xcodeproj
SkyHop/
  App/AppDelegate.swift          app + scene lifecycle, view controller
  Game/GameScene.swift           all gameplay, screens and input
  Game/GameConfig.swift          tuning numbers (gravity, speed, gap size…)
  Game/Textures.swift            all sprites, drawn in code
  Game/UINodes.swift             outlined text + buttons
  Services/Services.swift        saved scores, settings, sound
  Services/GameCenterManager.swift
  Resources/Sounds/*.wav
  Resources/PrivacyInfo.xcprivacy
  Assets.xcassets                app icon, colors
Support/Info.plist, SkyHop.entitlements
```

## 1. Run it (10 minutes)

You need a Mac with the current Xcode from the Mac App Store.

1. Open `SkyHop.xcodeproj`.
2. Click the **SkyHop** project → **SkyHop** target → **Signing & Capabilities**.
3. Pick your **Team** and change **Bundle Identifier** from `com.yourcompany.skyhop` to something you own, e.g. `com.yourname.skyhop`.
4. Choose an iPhone simulator (or your plugged-in iPhone) and press **⌘R**.

> This project was written without access to Xcode, so it hasn't been compiled yet. If Xcode shows an error on the first build, copy the red error text back to Claude and it can be fixed quickly.

## 2. Tune the feel (optional)

Open `GameConfig.swift`. The most useful knobs:

- `gravity` and `flapVelocity` — how floaty or snappy the jump feels
- `gap(for:)` — how big the opening is (bigger = easier)
- `speed(for:)` — scroll speed and how fast it ramps up
- `towerSpacing` — distance between towers

Test on a real phone before shipping; feel differs from the simulator.

## 3. Ship it to the App Store

### One-time setup
1. Join the **Apple Developer Program** ($99/year) at developer.apple.com.
2. In **App Store Connect** → **Apps** → **+** → **New App**: platform iOS, name (must be unique on the store — "Sky Hop" may be taken, so have a backup), your bundle ID, a SKU like `skyhop001`.

### Game Center leaderboard
1. In your app's page in App Store Connect → **Services** (or **Features**) → **Game Center** → add a **Classic Leaderboard**.
2. Leaderboard ID: `skyhop.highscore` (must match `GameConfig.leaderboardID`).
3. Score format: Integer, sort: High to Low. Add an English display name like "High Scores".
4. On the App Store version page, scroll to **Game Center** and tick it, then add the leaderboard.

### Upload a build
1. In Xcode, select **Any iOS Device (arm64)** as the destination.
2. **Product → Archive**. When the Organizer opens, choose **Distribute App → App Store Connect → Upload**.
3. Each new upload needs a higher **Build** number (target → General → Identity).

### Fill in the store listing
Use `APP_STORE_LISTING.md` for ready-to-paste text. You also need:

- **Screenshots**: run on the iPhone 6.9" simulator (e.g. iPhone 16/17 Pro Max), press **⌘S** in the Simulator to save. Grab the title screen, mid-game, and the game-over panel with a medal.
- **Privacy Policy URL**: host `PRIVACY.md` somewhere public (a free GitHub Pages site, Notion page, or your stream's website) and paste the link.
- **App Privacy** questionnaire: answer **"No, we do not collect data from this app."** (Game Center data is handled by Apple, not you.)
- **Age rating**: answer "None" to everything → 4+.
- **Export compliance** is already answered in Info.plist (no non-exempt encryption).

Then **Add for Review** → **Submit**. Reviews usually take 1–3 days.

## Avoiding a rejection

Apple's guideline **4.3 (Spam)** targets games that are near-copies of well-known titles. To keep the odds in your favor:

- Never use "Flappy" (or "Bird" + "Flap" combos) in your app name, subtitle, keywords, or screenshots.
- Sky Hop already has original art, a different character, Game Center and medals. Adding one signature twist of your own (unlockable characters, a daily challenge, power-ups, a theme tied to your stream) makes it clearly its own game.
- Make sure the Game Center leaderboard is set up before you submit — reviewers tap the Ranks button.
