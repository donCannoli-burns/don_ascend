# don_ascend — named Valhalla presets

This fork bundles the original C2Talon `c2t_ascend` (unchanged) and a new `don_ascend` with separate per-character named profiles and a KoLmafia Relay editor.

## Install via KoLmafia's CLI

```text
git checkout https://github.com/donCannoli-burns/don_ascend.git master
```

If this fork was already checked out, update it with:

```text
git update donCannoli-burns-don_ascend-master
```

KoLmafia's `manifest.json` installs the contents of `kolmafia/`: `scripts/don_ascend.ash` and `relay/relay_don_ascend.ash` alongside the existing C2T scripts. You do **not** need to unzip anything. If you also have the separate upstream C2T checkout installed, remove that duplicate checkout first to avoid two installations providing the same `c2t_ascend.ash` filename.

## Configure and run named profiles

Open the KoLmafia Relay Browser, refresh the `-run script-` dropdown if needed, and select **don ascend**. Select or manually override a choice for path, difficulty (casual/normal/hardcore), sex/gender, class, moon sign, astral deli and armory purchases, skill perm mode, and Karma reserve. You can choose individual skill IDs from the dropdown or enter a comma-separated list manually. Set an optional KoLmafia CLI command to run after a verified reincarnation. Save each preset under a name such as `sea`, `sea-pm`, or `cs`.

```text
verify don_ascend
verify relay_don_ascend
don_ascend list
don_ascend show sea
don_ascend sea --dry-run
don_ascend sea
don_ascend sea-pm
don_ascend cs
```

**Safety:** Saving a Relay preset, `show`, `list` and `--dry-run` do not enter Valhalla. Calling `don_ascend NAME` **does** attempt to ascend, buy astral items, perm skills and leave Valhalla. The optional saved post-command is executed only after checking that a new ascension was registered. The script does not fully verify that every class/path/sign selection is valid for the current character. Check choices before a live run.

**Testing:** Offline static source-structure checks passed. The new ASH has not yet been compiled or live-tested against an active KoLmafia session. Run both `verify` commands and dry-run before depending on it.

## Original C2T ascender (bundled unchanged)

The following section describes the legacy `c2t_ascend` functionality. Its original upstream installation instructions refer to C2Talon's separate repository; **the install command for this fork is above**.

---

### c2t_ascend

Kolmafia script written in ASH to automate valhalla, to include entering valhalla, buying astral items, perming skills, and leaving valhalla.

## Usage

* All configuration is done via the relay script. To start the relay script, find the drop-down menu that says `-run script-` at the top-right corner of the menu pane and select `c2t ascend`, as seen here:

![relay script location](https://github.com/C2Talon/c2t_ascend/blob/master/relay_script_location.png)

* When you want to jump the gash and go through valhalla, run `c2t_ascend.ash` on the CLI.
* There are no checks for combinations of values that may not be valid server input, so don't choose things you don't have access to, or try to enter an Ed run as a Seal Clubber as an example. I have no idea what will happen.
* It is suggested to have a pre-ascension script of some sort set to run on ascension that checks to make sure you are in a state you want to be in for ascension, so, for example, you don't accidentally just blow through valhalla without running any turns for the day.
* The auto-perm skills in valhalla feature will perm skills from the top of the list down without regard with how good or useful a skill is, so if that is not a behavior you want, just keep it off via the `Perm` setting.
* Trade offers can be auto-declined and stored to be viewed later via options in the relay script.

## Installation / Removal

To install, run the following on the kolmafia CLI:

`git checkout https://github.com/C2Talon/c2t_ascend.git master`

To remove, run the following:

`git remove C2Talon-c2t_ascend-master`

## Bugs?

There may be some paths that this doesn't know how to enter valhalla. Report it in the issues tab so I can know about it and maybe figure it out.

Also, report any other issues in the issues tab as well.

