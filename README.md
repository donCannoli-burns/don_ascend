# don_ascend — named Valhalla presets (preview release)

A separate, preset-driven KoLmafia ascension tool based on C2Talon's `c2t_ascend` architecture and the existing `donCannoli-burns/don_ascend` repository. The upstream `c2t_ascend.ash` and `relay_c2t_ascend.ash` remain **untouched**.

**Status: Source-reviewed / static checks only. Not yet compiled or live-tested against KoLmafia.** The first real use should be after running `verify` and a `--dry-run`, with an expendable/ready ascension.

## Install by Git checkout (recommended)

From KoLmafia gCLI:

```text
git checkout https://github.com/donCannoli-burns/don_ascend.git master
```

Already checked out? Use `git update donCannoli-burns-don_ascend-master`. KoLmafia reads `manifest.json` with `root_directory` set to `kolmafia`. The plugin files are in `kolmafia/scripts` and `kolmafia/relay`.

## Quick install (downloadable ZIP)

Unzip with the **contents** rooted at your KoLmafia directory:

```bash
unzip -o ~/Downloads/don_ascend_named.zip -d ~/.kolmafia/
```

The installed files are:

- `~/.kolmafia/scripts/don_ascend.ash`
- `~/.kolmafia/scripts/don_ascend_prep.ash` (imported helper; no standalone main)
- `~/.kolmafia/relay/relay_don_ascend.ash`

KoLmafia stores per-character profiles in `~/.kolmafia/data/don_ascend_profiles_<playerID>.txt` on first save. You do **not** need to edit your existing `c2t_ascend` preferences.

Open KoLmafia's Relay Browser and choose **don ascend** from the `-run script-` dropdown. Create or load a named profile (e.g. `sea`, `sea-pm`, `cs`), edit its fields, then click **Save profile**. This only saves the data file.

## CLI commands

```
verify don_ascend
verify don_ascend_prep
verify relay_don_ascend

don_ascend list
don_ascend show sea
don_ascend sea --dry-run
don_ascend sea

don_ascend sea-pm
don_ascend cs
```

**`don_ascend NAME` is a LIVE ascension command.** It runs a mandatory, fail-closed pre-ascension prep list and then, only when all gates pass and you approve a final confirmation/countdown, enters Valhalla, buys the saved astral items, perms skills, reincarnates with selected options, and runs the optional saved `cli_execute` command after a new ascension is verified. `list`, `show`, `--dry-run` and Relay editor actions do not contact KoL.

## Mandatory pre-ascension prep (`prep_list`)

The **live** `don_ascend NAME` command now runs the following stages, in order. If a stage fails, it stops **without entering Valhalla** (but earlier successfully completed purchases and other changes are not rolled back):

1. Visit Mr. Store 2002 and spend verified remaining credits on Spooky VHS Tape (#11270).
2. Spend real-inventory Interesting Coins on liquid/intangible/toxic assets (three each at most per day), then inexpensive 2/3-coin fallback items. A remaining balance due to daily shop limits **blocks** ascension. The original request did not identify a specific higher-priced item for balances over seven coins.
3. Visit Sept-Ember shop, spend `floor(embers/2)` on Mmm-brr! brand mouthwash and any leftover single ember on a wheel of camembert. Recheck balances after every transaction.
4. Ensure one aerated diving helmet and three each of Boris's bread, roasted vegetable of Jarlsberg, Pete's rich ricotta, roasted vegetable focaccia, plain calzone, and baked veggie ricotta casserole using KoLmafia CLI. This may acquire ingredients and spend Meat.
5. Purchase available Trophy Hut trophies, one at a time, verifying successful purchase and respecting the 10,000-Meat price. Visit the tavern Suspicious Guy; if no raffle tickets, attempt `raffle 11`; if exactly 11 tickets afterward, attempt `raffle 100`.
6. Inspect stomach/spleen/liver/adventures/PvP. If anything needs cleanup, ask **Fill organs and burn adventures now?**. When approved, equip `maxorgan`, run `consume all value 3700`, wait 5 seconds and overdrink `bucket of wine` if not already overdrunk, conditionally run `dpills`, `combo`, and `combo watersheep-N` for 1–5 adventures, then attempt local `pvp_mab` and `flogger.ash` only if PvP remains. No PvP interactions are automatic until approved in the cleanup prompt.
7. Hard-stop unless stomach and spleen are full, liver is **over** the maximum, adventures = 0, PvP fights = 0, and all verified expendable currencies are zero. Display path/difficulty/class/sex/astral purchases/perm configuration, ask for final explicit approval, then wait 30 seconds (KoLmafia Stop aborts; Escape may depend on UI). Recheck state after countdown and only then enter Valhalla.

`don_ascend NAME --dry-run` does **not** visit shops, spend currencies, or perform any prep actions; it previews and validates only the saved profile. Because the workflow performs potentially expensive and irreversible operations, the first live run should be monitored and tested after `verify`. The new helper must be installed alongside the main script.

## Fields

All fixed-choice fields are dropdowns with a numeric **manual override**. The override is used in preference to the dropdown when populated. Path and class options are discovered from your installed KoLmafia at runtime; keep KoLmafia updated for newer paths/classes. Unknown or unsupported IDs may be rejected by KoL. Type values: casual 1, normal 2, hardcore 3. Sex/gender: male 1, female 2. Moon sign: Mongoose 1 through Packrat 9.

Astral deli options: no item, hot dog dinner, six-pack, or carton of energy drinks (current item ID 10882; legacy ID 5139 is also offered with a legacy label). Armory options: no item or item IDs 5028–5042 (astral equipment). Unknown astral item IDs are rejected before action; a newer shop inventory would require code changes.

Perm mode:

- `0` — none
- `1` — auto-perm all available softcore skills subject to reserved Karma
- `2` — auto-perm all available hardcore skills subject to reserved Karma
- `3` — softcore-perm only listed skill IDs
- `4` — hardcore-perm only listed skill IDs

Use the complete skill dropdown and **Add skill to queue** to construct a comma-separated list of skill IDs, or enter it manually. For modes 3/4, a missing/unavailable selected skill or inadequate Karma stops the script **in Valhalla**, before reincarnation. Starter-skill skipping only affects auto modes. The Karma reserve can be manually specified (default `0`).

The optional post-ascension command is passed directly to KoLmafia's `cli_execute(...)`, **after** exiting Valhalla and seeing an increased ascension count. Leave blank to disable. Enter only commands you intentionally trust; do not use `don_ascend` itself as the post-command.

Pending trade auto-decline is **off** by default. If enabled, optionally archive the page of trade offers first. If archive is requested but fails, trade declines stop. Trade operations are mutating; the normal no-trade setting is safest.

## Safety and limitations

- The form **does not** execute or ascend; CLI `don_ascend NAME` does.
- A dry-run validates fields and displays the profile, but does **not** validate whether KoL will allow the chosen path/class/sign combination, whether a skill is actually available in the permery, or whether you can afford astral purchases.
- Casually ascending with a nonzero challenge path is rejected before action. Other path-specific restrictions depend on the game server.
- First-live run: check `verify don_ascend` and `verify relay_don_ascend`, inspect `don_ascend show NAME` and `don_ascend NAME --dry-run`; test after finishing the current run. Verify the actual reincarnation and command behavior before relying on it unattended.
- The script tries to confirm a new life with `main.php` and a rise in `my_ascensions()`. If KoLmafia cannot verify that, **it skips the post-command**, even if the ascension may actually have succeeded.
- A server-side failure partway through Valhalla may require manual recovery; there is no rollback of purchases or skill perms.
- There is no auto-generated preset: `sea`, `sea-pm`, and `cs` are examples and must each be saved explicitly.
- The original C2T script and its data are not changed by this add-on.

## Licensing

MIT. Original copyright (c) 2023 C2Talon retained, see `LICENSE`. Derivative implementation attributed to original `c2t_ascend`.
