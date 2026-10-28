// don_ascend - named Valhalla presets, based on C2T's c2t_ascend.
// Standalone: does not modify the original c2t_ascend preferences or script.
// A CLI invocation with a profile name is intentionally a LIVE ascension.
import <don_ascend_prep.ash>

string don_trim(string input) {
    matcher m = create_matcher("^\\s+|\\s+$", input);
    return replace_all(m, "");
}

string don_store_file() {
    return "don_ascend_profiles_" + my_id() + ".txt";
}

boolean don_profile_name_ok(string name) {
    matcher m = create_matcher("^[A-Za-z0-9][A-Za-z0-9_-]{0,39}$", name);
    return m.find();
}

string [int] don_fields() {
    return split_string("type,class,gender,path,moon,deli,armory,perm_mode,karma_hold,perm_skills,post_command,skip_starter,trade_decline,trade_archive,auto_approve", ",");
}

string [string] don_defaults() {
    string [string] p;
    p["type"] = "2";
    p["class"] = "1";
    p["gender"] = "1";
    p["path"] = "0";
    p["moon"] = "1";
    p["deli"] = "0";
    p["armory"] = "0";
    p["perm_mode"] = "0";
    p["karma_hold"] = "0";
    p["perm_skills"] = "";
    p["post_command"] = "";
    p["skip_starter"] = "1";
    p["trade_decline"] = "0";
    p["trade_archive"] = "0";
    // Older profiles default to explicit human approval.
    p["auto_approve"] = "0";
    return p;
}

boolean don_exists(string name) {
    if (!don_profile_name_ok(name)) return false;
    string [string] db;
    file_to_map(don_store_file(), db);
    return (db contains (name + ".type"));
}

string [string] don_load(string name) {
    string [string] p = don_defaults();
    string [string] db;
    if (!don_profile_name_ok(name)) return p;
    file_to_map(don_store_file(), db);
    string [int] fields = don_fields();
    foreach i, field in fields {
        string key = name + "." + field;
        if (db contains key) p[field] = db[key];
    }
    return p;
}

boolean don_digits(string value) {
    matcher m = create_matcher("^[0-9]+$", value);
    return m.find();
}

boolean don_skill_id_ok(string value) {
    return don_digits(value) && value.to_int() > 0;
}

// Return a diagnostic; empty string means structurally valid, NOT that KoL will
// accept the path/class/sign combination or that Karma is sufficient.
string don_validate(string [string] p) {
    string [int] fields = don_fields();
    foreach i, field in fields {
        if (!(p contains field)) return "Missing field: " + field;
    }
    string [int] numeric_fields = split_string("type,class,gender,path,moon,deli,armory,perm_mode,karma_hold,skip_starter,trade_decline,trade_archive,auto_approve", ",");
    foreach i, field in numeric_fields {
        if (!don_digits(p[field])) return "Expected numeric ID for " + field;
    }
    int t = p["type"].to_int();
    int c = p["class"].to_int();
    int g = p["gender"].to_int();
    int path_id = p["path"].to_int();
    int moon = p["moon"].to_int();
    int deli = p["deli"].to_int();
    int armory = p["armory"].to_int();
    int mode = p["perm_mode"].to_int();
    int hold = p["karma_hold"].to_int();
    if (t < 1 || t > 3) return "Type must be 1 (casual), 2 (normal), or 3 (hardcore).";
    if (c < 1) return "Class ID must be positive.";
    if (g < 1 || g > 2) return "Gender must be 1 (male) or 2 (female).";
    if (path_id < 0 || moon < 1 || moon > 9) return "Invalid path or moon sign ID.";
    if (t == 1 && path_id != 0) return "Casual ascensions cannot take a challenge path.";
    if (mode < 0 || mode > 4) return "Invalid perm mode (0-4).";
    if (hold < 0) return "Karma reserve must be nonnegative.";
    if (deli != 0 && deli != 5045 && deli != 5046 && deli != 5139 && deli != 10882)
        return "Unknown astral deli item ID (allowed: 5045, 5046, 5139, 10882).";
    if (armory != 0 && (armory < 5028 || armory > 5042))
        return "Unknown astral armory ID (allowed: 5028-5042).";
    string [int] bool_fields = split_string("skip_starter,trade_decline,trade_archive,auto_approve", ",");
    foreach i, field in bool_fields
        if (p[field] != "0" && p[field] != "1") return field + " must be 0 or 1.";
    if (p["post_command"].contains_text("\n") || p["post_command"].contains_text("\r"))
        return "Post-ascension command must be a single line.";
    if (mode == 3 || mode == 4) {
        if (don_trim(p["perm_skills"]) == "") return "Selected-skill perm mode requires skill IDs.";
        string [int] ids = split_string(p["perm_skills"], ",");
        foreach i, id in ids
            if (!don_skill_id_ok(don_trim(id))) return "Skill list must contain comma-separated positive numeric skill IDs.";
    }
    return "";
}

boolean don_save(string name, string [string] p) {
    if (!don_profile_name_ok(name)) return false;
    if (don_validate(p) != "") return false;
    string [string] db;
    if (!file_to_map(don_store_file(), db)) return false;
    string [int] fields = don_fields();
    foreach i, field in fields db[name + "." + field] = p[field];
    return map_to_file(db, don_store_file());
}

string [int] don_names() {
    string [int] names;
    boolean [string] found;
    string [string] db;
    file_to_map(don_store_file(), db);
    foreach key, value in db {
        string [int] parts = split_string(key, "\\.");
        if (count(parts) == 2 && parts[1] == "type" && don_profile_name_ok(parts[0]))
            found[parts[0]] = true;
    }
    foreach name, present in found names[count(names)] = name;
    return names;
}

string [int] don_type_options() {
    string [int] out = {1:"Casual", 2:"Normal", 3:"Hardcore"};
    return out;
}
string [int] don_gender_options() {
    string [int] out = {1:"Male", 2:"Female"};
    return out;
}
string [int] don_path_options() {
    string [int] out;
    out[0] = "No Path";
    foreach p in $paths[] out[p.id] = p.name;
    return out;
}
string [int] don_class_options() {
    string [int] out;
    foreach c in $classes[] out[c.id] = c.to_string();
    return out;
}
string [int] don_moon_options() {
    string [int] out = {
        1:"The Mongoose", 2:"The Wallaby", 3:"The Vole",
        4:"The Platypus", 5:"The Opossum", 6:"The Marmot",
        7:"The Wombat", 8:"The Blender", 9:"The Packrat"
    };
    return out;
}
string [int] don_deli_options() {
    string [int] out = {0:"None", 5045:"astral hot dog dinner", 5046:"astral six-pack", 5139:"carton of astral energy drinks (legacy)", 10882:"carton of astral energy drinks (current)"};
    return out;
}
string [int] don_armory_options() {
    string [int] out;
    out[0] = "None";
    for i from 5028 to 5042 out[i] = i.to_item().to_string();
    return out;
}
string [int] don_perm_options() {
    string [int] out = {
        0:"No perming", 1:"Auto-perm softcore skills", 2:"Auto-perm hardcore skills",
        3:"Perm selected skills (softcore)", 4:"Perm selected skills (hardcore)"
    };
    return out;
}
string [int] don_karma_options() {
    string [int] out = {0:"0 (spend down to zero)"};
    return out;
}
string [int] don_bool_options() {
    string [int] out = {0:"No", 1:"Yes"};
    return out;
}

string [int] don_approval_options() {
    string [int] out = {
        0:"Human-approve on (explicit YES required)",
        1:"Auto-on (YES after 30 seconds; NO cancels)"
    };
    return out;
}

boolean don_blocked_starter(int skill_id) {
    boolean [int] blocked;
    foreach sk in $skills[seal clubbing frenzy, clobber, patience of the tortoise, toss,
        manicotti meditation, spaghetti spear, sauce contemplation, salsaball,
        disco aerobics, suckerpunch, moxie of the mariachi, sing, cleesh, mild curse]
        blocked[sk.id] = true;
    return blocked contains skill_id;
}

boolean don_decline_trades(string [string] p) {
    if (p["trade_decline"] != "1") return false;
    buffer page = visit_url("makeoffer.php", false, true);
    if (p["trade_archive"] == "1") {
        string file = "don_ascend_trades_" + my_id() + "_" + today_to_string() + ".html";
        if (!buffer_to_file(page, file)) {
            print("Trade archive failed: refusing to discard pending offers.", "red");
            return false;
        }
        print("Trade offers archived to data/" + file, "blue");
    }
    matcher m = create_matcher("makeoffer\\.php\\?action=(cancel2?|decline)&whichoffer=\\d+", page);
    while (m.find()) visit_url(m.group(0), false, true);
    return true;
}

// Parses currently offered Valhalla permery actions; never tries to perm IDs
// not actually found in the page. Stops on an explicit missing skill or low Karma.
boolean don_perm_skills(string [string] p) {
    int mode = p["perm_mode"].to_int();
    if (mode == 0) return true;
    buffer page = visit_url("afterlife.php?place=permery", false, true);
    string [int] actions = xpath(page, '//form[@action="afterlife.php"]//input[@name="action"]/@value');
    string [int] skills = xpath(page, '//form[@action="afterlife.php"]//input[@name="whichskill"]/@value');
    string [int] buttons = xpath(page, '//form[@action="afterlife.php"]//input[@type="submit"]/@value');
    if (count(skills) == 0 && (mode == 1 || mode == 2)) {
        print("No permable skills currently offered; continuing without perming.", "blue");
        return true;
    }
    if (count(skills) == 0 || count(skills) != count(actions) || count(skills) != count(buttons)) {
        print("Could not parse current permery; halting in Valhalla.", "red");
        return false;
    }
    string desired = (mode == 2 || mode == 4) ? "hcperm" : "scperm";
    boolean selected = (mode == 3 || mode == 4);
    boolean [int] wanted;
    boolean [int] completed;
    if (selected) {
        string [int] ids = split_string(p["perm_skills"], ",");
        foreach i, id in ids wanted[don_trim(id).to_int()] = true;
    }
    foreach i, rawskill in skills {
        if (actions[i] != desired) continue;
        int skill_id = rawskill.to_int();
        if (selected && !(wanted contains skill_id)) continue;
        if (!selected && p["skip_starter"] == "1" && don_blocked_starter(skill_id)) continue;
        matcher cm = create_matcher("Permanent\\s+\\((\\d+)\\s+Karma\\)", buttons[i]);
        if (!cm.find()) {
            print("Unable to parse permery Karma cost for skill #" + skill_id, "red");
            return false;
        }
        int cost = cm.group(1).to_int();
        if (get_property("bankedKarma").to_int() - cost < p["karma_hold"].to_int()) {
            if (selected) {
                print("Insufficient Karma to perm selected skill #" + skill_id + "; stopping in Valhalla.", "red");
                return false;
            }
            print("Auto-perming stopped at reserved Karma threshold.", "blue");
            break;
        }
        visit_url("afterlife.php?action=" + desired + "&whichskill=" + skill_id, true, true);
        completed[skill_id] = true;
        print("Perm request sent for skill #" + skill_id + " (" + desired + ")", "blue");
    }
    if (selected) {
        foreach skill_id, enabled in wanted {
            if (!(completed contains skill_id)) {
                print("Selected skill #" + skill_id + " not permable in requested mode; stopping in Valhalla.", "red");
                return false;
            }
        }
    }
    return true;
}

// Persistent, per-character receipt written BEFORE reincarnation; never
// re-send the irreversible afterlife request to recover a redirected response.
string don_handoff_file() {
    return "don_ascend_handoff_" + my_id() + ".txt";
}
string [string] don_handoff_read() {
    string [string] receipt;
    file_to_map(don_handoff_file(), receipt);
    return receipt;
}
boolean don_handoff_begin(string name, string [string] profile, int before) {
    string [string] receipt;
    receipt["status"] = "awaiting_verification";
    receipt["profile"] = name;
    receipt["ascensions_before"] = before.to_string();
    receipt["expected_path"] = profile["path"];
    receipt["expected_class"] = profile["class"];
    receipt["post_command"] = profile["post_command"]; // frozen command, not editable later
    return map_to_file(receipt, don_handoff_file());
}
void don_handoff_status() {
    string [string] receipt = don_handoff_read();
    if (receipt["status"] == "") {
        print("No recorded handoff. Current ascension count: " + my_ascensions(), "blue");
        return;
    }
    print("Handoff status=" + receipt["status"] + " profile=" + receipt["profile"] +
        " ascensions before=" + receipt["ascensions_before"] + " current=" + my_ascensions() +
        " path expected=" + receipt["expected_path"] + " current=" + my_path().id +
        " choice active=" + handling_choice(), "blue");
    if (receipt["status"] == "awaiting_verification")
        print("Resolve pending choices in Relay, then use: don_ascend resume " + receipt["profile"], "blue");
    if (receipt["status"] == "post_command_claimed")
        print("Post-command outcome is potentially ambiguous. Do not auto-retry.", "red");
}
boolean don_handoff_resume(string name) {
    string [string] receipt = don_handoff_read();
    if (receipt["status"] == "" || receipt["profile"] != name) {
        print("No matching handoff receipt. Old, unrecorded ascensions cannot be resumed automatically.", "red");
        return false;
    }
    if (receipt["status"] == "completed") {
        print("Handoff already completed. No duplicate post-command.", "green");
        return true;
    }
    if (receipt["status"] != "awaiting_verification") {
        print("Handoff status " + receipt["status"] + " is not automatically retryable.", "red");
        return false;
    }
    if (handling_choice()) {
        print("Choice #" + last_choice() + " is active. Finish it manually in Relay first. Do not rerun ascension.", "red");
        return false;
    }
    if (!refresh_status()) {
        print("Status refresh failed. No post-command. Ascension remains uncertain.", "red");
        return false;
    }
    if (handling_choice()) {
        print("A choice remains active after refresh. Finish it manually in Relay.", "red");
        return false;
    }
    int before = receipt["ascensions_before"].to_int();
    if (my_ascensions() != before + 1 ||
        my_path().id != receipt["expected_path"].to_int() ||
        my_class().id != receipt["expected_class"].to_int()) {
        print("New life NOT verified: ascensions " + before + " -> " + my_ascensions() +
            ", path " + my_path().id + " vs " + receipt["expected_path"] +
            ", class " + my_class().id + " vs " + receipt["expected_class"] +
            ". No post-command and NO ascension retry.", "red");
        return false;
    }
    string cmd = don_trim(receipt["post_command"]);
    if (cmd == "") {
        receipt["status"] = "completed";
        if (!map_to_file(receipt, don_handoff_file())) return false;
        print("New life verified; no post-command to run.", "green");
        return true;
    }
    // Write a durable claim BEFORE calling an arbitrary, possibly mutating CLI.
    receipt["status"] = "post_command_claimed";
    if (!map_to_file(receipt, don_handoff_file())) {
        print("Cannot persist exactly-once post-command claim. Not executing.", "red");
        return false;
    }
    print("Verified new ascension. Executing saved post-command ONCE: " + cmd, "blue");
    if (!cli_execute(cmd)) {
        print("Post-command reported failure. Receipt stays claimed; inspect manually.", "red");
        return false;
    }
    receipt["status"] = "completed";
    if (!map_to_file(receipt, don_handoff_file())) {
        print("Command returned success but completion receipt could not save; no retry allowed.", "red");
        return false;
    }
    print("Post-ascension handoff completed.", "green");
    return true;
}

boolean don_run(string name, boolean dry_run) {
    if (!don_exists(name)) {
        print("Unknown preset '" + name + "'. Open Relay > don_ascend to create one.", "red");
        return false;
    }
    string [string] p = don_load(name);
    string error = don_validate(p);
    if (error != "") {
        print("Preset '" + name + "' invalid: " + error, "red");
        return false;
    }
    print("don_ascend [" + name + "] type=" + p["type"] + " path=" + p["path"] +
        " class=" + p["class"] + " gender=" + p["gender"] + " moon=" + p["moon"] +
        " deli=" + p["deli"] + " armory=" + p["armory"] + " perm=" + p["perm_mode"] +
        " approval=" + (p["auto_approve"] == "1" ? "auto-on" : "human-approve"), "blue");
    print("Post-ascension CLI: " + (p["post_command"] == "" ? "(none)" : p["post_command"]), "blue");
    if (dry_run) {
        print("DRY RUN: no visits, purchases, perms, ascension, or CLI command.", "green");
        return true;
    }
    // An unresolved handoff must NEVER be treated as a fresh ascension request.
    string [string] prior = don_handoff_read();
    if (prior["status"] != "" && prior["status"] != "completed") {
        print("Unresolved " + prior["status"] + " handoff for '" + prior["profile"] +
            "'. Use don_ascend status / don_ascend resume " + prior["profile"] +
            ". Do not rerun Valhalla.", "red");
        return false;
    }
    // LIVE ACTIONS BEGIN. Preflight must pass BEFORE touching Valhalla.
    if (!prep_list(p)) return false;
    // Do not assume a valid preset means a legal server-side combo.
    int starting_ascensions = my_ascensions();
    buffer page;
    if (get_property("csServicesPerformed") != "")
        page = visit_url("ascend.php?alttext=communityservice", false, true);
    else page = visit_url("ascend.php", false, true);
    if (page == "".to_buffer() || page.contains_text("You may not enter the Astral Gash again until tomorrow.")) {
        print("Ascension page unavailable or too early; stopping.", "red");
        return false;
    }
    if (!page.contains_text(">Beyond the Pale</b>")) {
        page = visit_url("ascend.php?pwd&action=ascend&confirm=on&confirm2=on", true, true);
        if (page.contains_text("You may not ascend while you have pending trade offers.")) {
            if (!don_decline_trades(p)) {
                print("Pending trades block ascension; auto-decline disabled or failed.", "red");
                return false;
            }
            visit_url("ascend.php", false, true);
            page = visit_url("ascend.php?pwd&action=ascend&confirm=on&confirm2=on", true, true);
        }
        if (!page.contains_text(">Beyond the Pale</b>")) {
            print("Could not verify entry to Valhalla; stopping.", "red");
            return false;
        }
    }
    if (page.contains_text("afterlife.php?action=pearlygates"))
        visit_url("afterlife.php?action=pearlygates", false, true);
    if (p["deli"].to_int() > 0)
        visit_url("afterlife.php?action=buydeli&whichitem=" + p["deli"], true, true);
    if (p["armory"].to_int() > 0)
        visit_url("afterlife.php?action=buyarmory&whichitem=" + p["armory"], true, true);
    if (!don_perm_skills(p)) return false;
    if (!don_handoff_begin(name, p, starting_ascensions)) {
        print("Failed to save reincarnation checkpoint; stopping IN Valhalla.", "red");
        return false;
    }
    print("Leaving Valhalla as profile '" + name + "' (one request only).", "blue");
    page = visit_url("afterlife.php?pwd&action=ascend&confirmascend=1&whichsign=" + p["moon"] +
        "&gender=" + p["gender"] + "&whichclass=" + p["class"] + "&whichpath=" + p["path"] +
        "&asctype=" + p["type"] + "&nopetok=1&noskillsok=1&lamesignok=1&lamepathok=1", true, true);
    // A redirect to choice.php may be the EXPECTED result of reincarnation.
    // Do not visit main.php or retry afterlife.php. Pending choices are human-owned.
    if (handling_choice()) {
        print("HANDOFF PENDING: new-run choice #" + last_choice() +
            ". Resolve it in Relay, then run: don_ascend resume " + name +
            ". Never rerun don_ascend " + name + ".", "red");
        return true;
    }
    if (page == "".to_buffer() || page.contains_text("confirmascend")) {
        print("Afterlife reply inconclusive. Receipt saved; no retry. Check state with " +
            "don_ascend status, then don_ascend resume " + name + ".", "red");
        return true;
    }
    if (!don_handoff_resume(name)) {
        print("Exit not yet verified. Receipt saved; resume once server/new-run choice settles.", "red");
        return true;
    }
    return true;
}

void main(string args) {
    string arg = don_trim(args);
    if (arg == "" || arg == "help") {
        print("Usage: don_ascend list | status | resume NAME | show NAME | NAME --dry-run | NAME", "blue");
        print("CAUTION: don_ascend NAME performs live ascension. Create profiles via Relay > don_ascend.", "red");
        return;
    }
    if (arg == "status") {
        don_handoff_status();
        return;
    }
    if (arg.starts_with("resume ")) {
        string pending_name = don_trim(arg.substring(7));
        if (!don_profile_name_ok(pending_name)) {
            print("Invalid handoff profile name.", "red");
            return;
        }
        don_handoff_resume(pending_name);
        return;
    }
    if (arg == "list") {
        string [int] names = don_names();
        if (count(names) == 0) print("No profiles saved; use Relay > don_ascend.");
        foreach i, name in names print("  " + name);
        return;
    }
    if (arg.starts_with("show ")) {
        string name = don_trim(arg.substring(5));
        if (!don_exists(name)) { print("Unknown preset '" + name + "'.", "red"); return; }
        string [string] profile = don_load(name);
        string [int] fields = don_fields();
        foreach i, field in fields print(field + " = " + profile[field]);
        return;
    }
    boolean dry = false;
    if (arg.ends_with(" --dry-run")) {
        arg = don_trim(arg.substring(0, length(arg) - length(" --dry-run")));
        dry = true;
    }
    if (!don_profile_name_ok(arg)) {
        print("Invalid preset argument. Use letters, numbers, hyphen or underscore only.", "red");
        return;
    }
    if (!don_run(arg, dry)) abort("don_ascend: operation stopped or failed");
}
