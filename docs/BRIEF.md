# 🎮 Game Brief Document

**Title:** *Scab Claus* (a.k.a. *Père Casseur*)
**Format:** Mobile game (portrait mode, 720×1280)
**Session Length:** ~24 minutes per run

---

## 🌍 High‑Level Concept
*Père Casseur* is a satirical idle‑arcade hybrid where Santa Claus, reimagined as a grotesque capitalist pig caricature, must “save Christmas” after his elves go on strike. Instead of respecting labor, Santa doubles down on exploitation, fossil fuels, and global capitalism to deliver presents to **8.2 billion people in 24 hours** (compressed into a 24‑minute game session).

The player snowboards downhill on a gas‑powered hoverboard, flinging presents left and right into houses that line the ski slope. As time passes, the hoverboard spews smoke, the snow melts, and the world visibly deteriorates.

The irony: the player “wins” by delivering all the presents, but the planet is ruined in the process.

---

## 🎮 Core Gameplay
- **Movement:** Santa snowboards downhill, moving left/right with limited downward drift.
- **Delivery:** Gifts automatically arc into houses on either side.
- **Power‑Ups:** Collected on the slope or unlocked via milestones, they accelerate delivery.
- **Progression:** Presents counter ticks down from 8.2 billion to 0.
- **Obstacles:** Slow Santa slightly, but never kill him.
- **HUD:** Upper half of the screen displays unlocked power‑ups as icons/stats.

---

## 🏆 Win Condition
- Deliver all presents
- End screen: “Christmas Saved!” banner over a ruined, garbage‑strewn wasteland.

---

## 📈 Power‑Up Progression
Each power‑up is both a **mechanical boost** and a **satirical commentary**. They unlock in tiers as the player delivers more presents, ensuring steady escalation.

| Tier | Power‑Up | Description | Visual/Icon Idea | Effect |
|------|----------|-------------|------------------|--------|
| 1 | **Amazon Fulfillment Deal** | Santa outsources to Prime drones. | Drone with gift box | Steady passive delivery boost |
| 1 | **Scab Post Express** | Gig workers replace striking elves. | Van with dollar signs | Small multiplier, steady growth |
| 2 | **Oil Baron’s Pact** | Shadowy fossil fuel tycoons bankroll Santa’s hoverboard. | Oil barrel with candy cane stripe | Hoverboard speed boost, more presents per second |
| 2 | **Plastic Wonderland** | Cheap plastic toys flood the market. | Melting doll/toy | Doubles delivery rate, adds visible garbage |
| 3 | **Coal‑Powered Christmas** | Coal plants power Santa’s sleigh. | Smokestack with bow | Huge speed boost, snow melts faster |
| 3 | **Fast Fashion Frenzy** | Sweatshops churn out gifts. | Sewing machine with Santa hat | Multiplier spike, pollution meter jumps |
| 4 | **Military Logistics Contract** | Cargo planes drop presents worldwide. | Plane with red nose | Massive burst deliveries |
| 4 | **Crypto Christmas** | Presents “mined” via blockchain. | Glowing Bitcoin with bow | Passive surge, accelerates warming |
| 5 | **SpaceX Sleigh Launch** | Rockets deliver gifts globally. | Rocket with christmas colours | Huge late‑game multiplier, adds space junk |
| 5 | **World Bank Bailout** | Santa gets a bailout to “save Christmas.” | Money bag with snowflake | Final surge to finish counter |

---

## 🎨 Visual & Tone Guidelines
- **Santa:** Bloated, cigar‑smoking, capitalist caricature.
- **World:** Bright and festive at first, gradually polluted and melting.
- **HUD Icons:** Cartoonish, satirical, instantly readable.
- **Feedback:** Each power‑up worsens the environment (smoke, garbage, melting snow).

---

## HUD Layout

Window width 720 px, height 1280 px


Top bar (HUD zone Santa can’t enter):
- ⏱️ Left: Timer
- 🎁 Center: Presents Counter
- ☠️ Below: 10 power‑ups, empty silhouettes first, shows icon as they unlock
- 📈 Realtime stats


Playfield (ski hill):
- Santa in the middle, moving left/right.
- Presents arcing to houses.
- Avoid striking elves and collect power‑ups.

---

## 🏆 Player Experience


🏂 Collects:
- Red fuel canisters
- Oil barrels
- Bribes


🏂 Avoids:
- Elves on strike


How does the player know they are accomplishing something?

- Power‑up silhouettes in the HUD have progress bars. Collectibles fill these faster.
- “+X% delivery rate” stats when they grab a collectible.
- Presents arc more rapidly into houses.
- Santa’s hoverboard exhaust grows bigger.
- Unlocked power‑up icons fly across the screen delivering gifts to help Santa.


Timer caps:

Each tier of power‑ups has a minimum unlock time (e.g., Tier 2 can’t appear before 2 minutes, Tier 3 before 5 minutes). Example: “Amazon Fulfillment Deal” unlocks at 334 presents. If idle, you hit it at 2 minutes. If you collect aggressively, you hit it at 45 seconds.

- Doing nothing = ~24 minutes to finish the game.
- Playing casually = ~16 minutes.
- Playing optimally = ~10 minutes.
