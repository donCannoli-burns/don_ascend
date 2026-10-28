// don_ascend Relay preset manager. Saves configs only; never enters Valhalla.
import <don_ascend.ash>

void don_ui_option(string value, string label, string current) {
    write("<option value='" + entity_encode(value) + "'");
    if (value == current) write(" selected");
    write(">" + entity_encode(label) + "</option>");
}

void don_ui_field(string label, string key, string [int] options, string [string] profile) {
    string saved = profile[key];
    boolean recognized = false;
    foreach id, title in options if (saved == id.to_string()) recognized = true;
    string custom = recognized ? "" : saved;
    write("<div class='field'><label for='" + key + "_choose'>" + entity_encode(label) + "</label>");
    write("<select name='" + key + "_choose' id='" + key + "_choose'>");
    if (!recognized) don_ui_option("", "Manual ID (shown to right)", "");
    foreach id, title in options don_ui_option(id.to_string(), title + " (#" + id + ")", saved);
    write("</select>");
    write("<input type='text' name='" + key + "_override' value='" + entity_encode(custom) + "' placeholder='Manual numeric ID overrides dropdown' aria-label='Manual " + entity_encode(label) + " ID override'>");
    write("</div>");
}

void don_ui_text(string label, string key, string [string] profile, string help) {
    write("<div class='field'><label for='" + key + "'>" + entity_encode(label) + "</label>");
    write("<input type='text' id='" + key + "' name='" + key + "' value='" + entity_encode(profile[key]) + "' placeholder='" + entity_encode(help) + "'>");
    write("<small>" + entity_encode(help) + "</small></div>");
}

string don_submitted_value(string [string] fields, string key) {
    string override = don_trim(fields[key + "_override"]);
    if (override != "") return override;
    return don_trim(fields[key + "_choose"]);
}

void main() {
    string [string] posted = form_fields();
    string operation = posted["action"];
    string name = don_trim(posted["edit_name"]);
    string status = "";
    boolean error = false;
    if (operation == "load") name = don_trim(posted["load_name"]);
    if (name == "") name = "sea"; // editor suggestion only; never silently saves
    string [string] profile = don_defaults();
    if (don_exists(name)) profile = don_load(name);

    if (operation == "save") {
        if (!don_profile_name_ok(name)) {
            status = "Invalid name: use 1-40 letters, digits, hyphens, underscores; first character must be alphanumeric.";
            error = true;
        } else {
            string [int] numeric_fields = split_string("type,class,gender,path,moon,deli,armory,perm_mode,karma_hold,skip_starter,trade_decline,trade_archive,auto_approve", ",");
            foreach i, key in numeric_fields
                profile[key] = don_submitted_value(posted, key);
            profile["perm_skills"] = don_trim(posted["perm_skills"]);
            profile["post_command"] = don_trim(posted["post_command"]);
            string invalid = don_validate(profile);
            if (invalid != "") { status = "Not saved: " + invalid; error = true; }
            else if (!don_save(name, profile)) { status = "Could not save the data file."; error = true; }
            else status = "Saved profile '" + name + "'. CLI: don_ascend " + name;
        }
    } else if (operation == "load") {
        if (!don_exists(name)) { status = "No saved profile with that name. The editor shows defaults."; error = true; }
        else status = "Loaded '" + name + "' for editing. No ascension was performed.";
    }

    write("<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'><title>don_ascend Presets</title>");
    write("<style>body{margin:14px auto;max-width:1040px;padding:0 16px;font:14px Arial,sans-serif;color:#000;background:#fcfcff}h1{border-bottom:2px solid #000;padding-bottom:9px}fieldset{border:2px solid #000;margin:16px 0;padding:15px;background:#dff7fa}legend{font-weight:bold;font-size:16px;padding:0 8px}.field{display:grid;grid-template-columns:180px minmax(210px,1fr) minmax(170px,1fr);gap:10px;align-items:center;padding:7px 0;border-bottom:1px solid #abd1f3}.field label{font-weight:bold}.field input,.field select,input,select{box-sizing:border-box;max-width:100%;padding:7px;border:1px solid #000;background:#fcfcff}.field small{color:#333}.field:has(small){grid-template-columns:180px minmax(260px,1fr) minmax(170px,1fr)}button{padding:9px 16px;background:#abd1f3;border:2px solid #000;font-weight:bold;cursor:pointer}button:hover{background:#c2e0f9}.msg{border:2px solid #000;padding:12px;background:#c2e0f9}.error{background:#fff0f0}.note{border-left:4px solid #000;padding:12px;background:#fcfcff}code{background:#eee;padding:2px 4px}small{font-size:11px}@media(max-width:700px){.field,.field:has(small){grid-template-columns:1fr}} </style>");
    write("<script>function addSkill(){var s=document.getElementById('skill_picker'), t=document.getElementById('perm_skills'), x=s.value;if(!x)return;var arr=t.value.split(',').map(function(v){return v.trim()}).filter(Boolean);if(arr.indexOf(x)<0)arr.push(x);t.value=arr.join(',');}</script>");
    write("</head><body><h1>don_ascend — Named Valhalla Profiles</h1>");
    write("<p>Configure the choices below, save a named profile, then call it from KoLmafia's CLI. <strong>Saving and loading never ascends.</strong></p>");
    if (status != "") write("<div class='msg" + (error ? " error" : "") + "'>" + entity_encode(status) + "</div>");

    string [int] names = don_names();
    write("<fieldset><legend>Load a saved profile</legend><form method='post' action='" + __FILE__ + "'>");
    write("<select name='load_name' aria-label='Saved profile'>");
    if (count(names) == 0) write("<option value=''>No saved profiles</option>");
    foreach i, preset in names don_ui_option(preset, preset, name);
    write("</select> <button name='action' value='load' type='submit'>Load preset</button></form></fieldset>");
    write("<form method='post' action='" + __FILE__ + "'>");
    write("<fieldset><legend>Profile identity</legend><div class='field'><label for='edit_name'>Preset name</label><input type='text' name='edit_name' id='edit_name' value='" + entity_encode(name) + "' maxlength='40' required pattern='[A-Za-z0-9][A-Za-z0-9_-]*'><small>Examples: sea, sea-pm, cs</small></div></fieldset>");
    write("<fieldset><legend>New life</legend>");
    don_ui_field("Path", "path", don_path_options(), profile);
    don_ui_field("Difficulty / type", "type", don_type_options(), profile);
    don_ui_field("Sex / gender", "gender", don_gender_options(), profile);
    don_ui_field("Class", "class", don_class_options(), profile);
    don_ui_field("Moon sign", "moon", don_moon_options(), profile);
    write("</fieldset><fieldset><legend>Astral purchases</legend>");
    don_ui_field("Astral deli item", "deli", don_deli_options(), profile);
    don_ui_field("Astral armory item", "armory", don_armory_options(), profile);
    write("</fieldset><fieldset><legend>Skill perming</legend>");
    don_ui_field("Perm mode", "perm_mode", don_perm_options(), profile);
    don_ui_field("Reserve Karma", "karma_hold", don_karma_options(), profile);
    write("<div class='field'><label for='skill_picker'>Available skill IDs</label><select id='skill_picker'><option value=''>Choose a skill to add...</option>");
    foreach sk in $skills[] if (sk.id > 0) don_ui_option(sk.id.to_string(), sk.to_string() + " (#" + sk.id + ")", "");
    write("</select><button type='button' onclick='addSkill()'>Add skill to queue</button></div>");
    don_ui_text("Selected skill queue", "perm_skills", profile, "Comma-separated skill IDs, e.g. 3010,5008. Used in selected-skill modes.");
    don_ui_field("Skip starter skills", "skip_starter", don_bool_options(), profile);
    write("</fieldset><fieldset><legend>After leaving Valhalla</legend>");
    don_ui_text("KoLmafia CLI command", "post_command", profile, "Optional single command to run ONLY after a verified new ascension.");
    write("</fieldset><fieldset><legend>Final ascension approval</legend>");
    don_ui_field("Approval mode", "auto_approve", don_approval_options(), profile);
    write("<p class='note'><strong>Auto-on:</strong> YES proceeds immediately, NO cancels, and no response defaults to YES after 30 seconds. <strong>Human-approve on:</strong> requires an explicit YES (no timeout). Both modes include a 5-second final stop window.</p>");
    write("</fieldset><fieldset><legend>Pending trade handling</legend>");
    don_ui_field("Auto-decline trades", "trade_decline", don_bool_options(), profile);
    don_ui_field("Archive trades first", "trade_archive", don_bool_options(), profile);
    write("</fieldset><button name='action' value='save' type='submit'>Save profile (does not ascend)</button></form>");
    write("<div class='note'><p><strong>CLI usage:</strong> <code>don_ascend list</code> · <code>don_ascend show " + entity_encode(name) + "</code> · <code>don_ascend " + entity_encode(name) + " --dry-run</code> · <code>don_ascend " + entity_encode(name) + "</code>.</p>");
    write("<p><strong>LIVE WARNING:</strong> The last command enters and exits Valhalla, possibly spending Karma and buying astral goods. It is not a preview. KoL itself decides whether class/path/sign combinations are legal; inspect your choices before running.</p>");
    write("<p>Manual ID override wins over the dropdown when populated. Unknown astral item IDs are rejected to prevent accidental purchases. For selected skills, only a skill actually offered in the permery can be processed; missing skills stop the run in Valhalla before reincarnation.</p></div>");
    write("</body></html>");
}
