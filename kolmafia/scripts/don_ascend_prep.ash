// Don Ascend preflight + aftercore prep. Imported by don_ascend.ash.
// NEVER run purchases/actions during script import, Relay rendering, or --dry-run.
// Every irreversible stage is sequenced before the existing Valhalla entry.

void dap_info(string msg) { print("[don_ascend prep] " + msg, "blue"); }
boolean dap_stop(string msg) {
    print("[don_ascend prep] ASCENSION CANCELED: " + msg, "red");
    return false;
}

boolean dap_buy_one(coinmaster shop, item currency, item reward, int expected_cost) {
    int old_currency = item_amount(currency);
    int old_reward = item_amount(reward);
    if (old_currency < expected_cost || sell_price(shop, reward) != expected_cost)
        return dap_stop("Coin price/balance mismatch for " + reward + ".");
    if (!buy(shop, 1, reward)) return dap_stop("Coinmaster rejected " + reward + ".");
    if (item_amount(currency) != old_currency - expected_cost ||
        item_amount(reward) != old_reward + 1)
        return dap_stop("Inventory/currency mismatch buying " + reward + "; refusing retries.");
    return true;
}

boolean dap_mrstore() {
    // Shop visit refreshes a non-inventory currency: NEVER use item_amount(credit).
    visit_url("shop.php?whichshop=mrstore2002", false);
    string raw = get_property("availableMrStore2002Credits");
    if (raw == "" || raw.to_int() < 0)
        return dap_stop("Mr. Store 2002 credits have not been verified.");
    int credits = raw.to_int();
    if (credits == 0) return true;
    coinmaster shop = to_coinmaster("Mr. Store 2002");
    item vhs = $item[11270];
    if (shop == $coinmaster[none] || !is_accessible(shop) || sell_price(shop, vhs) != 1)
        return dap_stop("Mr. Store 2002 does not offer expected one-credit Spooky VHS Tape.");
    int before = item_amount(vhs);
    dap_info("Spending " + credits + " Mr. Store 2002 credits on Spooky VHS Tape.");
    if (!buy(shop, credits, vhs)) return dap_stop("Spooky VHS Tape coinmaster purchase failed.");
    visit_url("shop.php?whichshop=mrstore2002", false);
    if (item_amount(vhs) != before + credits ||
        get_property("availableMrStore2002Credits").to_int() != 0)
        return dap_stop("Mr. Store 2002 receipt/balance mismatch. No second attempt.");
    return true;
}

boolean dap_coin_slot_open(item reward) {
    // KoLmafia's recent coinmaster daily purchase counter.
    return get_property("_itemBoughtPerDay" + reward.id).to_int() < 3;
}

boolean dap_interesting_coins() {
    item currency = $item[interesting coin];
    int starting = item_amount(currency);
    if (starting == 0) return true;
    dap_info("Spending " + starting + " Interesting Coins from real inventory.");
    coinmaster shop = to_coinmaster("Spend your Interesting Coins");
    if (shop == $coinmaster[none] || !visit(shop) || !is_accessible(shop))
        return dap_stop("Interesting Coin shop unavailable.");
    // All items below have a verified expected price and at most 3/day.
    // For >7, inexpensive fallbacks permit spending beyond the first six singles.
    for cycle from 1 to 3 {
        foreach reward in $items[liquid asset, intangible asset, toxic asset] {
            if (item_amount(currency) == 0) break;
            if (!dap_coin_slot_open(reward)) continue;
            if (!dap_buy_one(shop, currency, reward, 1)) return false;
        }
    }
    for cycle from 1 to 3 {
        foreach reward in $items[invisible hand, circle of overdraft protection scroll, mint, solvent] {
            int price = reward == $item[solvent] ? 3 : 2;
            if (item_amount(currency) < price || !dap_coin_slot_open(reward)) continue;
            if (!dap_buy_one(shop, currency, reward, price)) return false;
        }
    }
    if (item_amount(currency) != 0)
        return dap_stop("Interesting Coin shop daily limits/stock leave " + item_amount(currency) + " coins. Spend manually or retry another day.");
    return true;
}

int dap_ember_balance() {
    // A fresh visit after invalidating KoLmafia's daily shop-read cache.
    if (available_amount($item[Sept-Ember Censer]) <= 0) return 0;
    set_property("_septEmberBalanceChecked", "false");
    buffer page = visit_url("shop.php?whichshop=september", false);
    if (page == "".to_buffer() || !get_property("_septEmberBalanceChecked").to_boolean()) return -1;
    return get_property("availableSeptEmbers").to_int();
}

boolean dap_sept_embers() {
    int embers = dap_ember_balance();
    if (embers < 0) return dap_stop("Sept-Ember balance could not be verified.");
    if (embers == 0) return true;
    coinmaster shop = to_coinmaster("Sept-Ember Censer");
    if (shop == $coinmaster[none] || !is_accessible(shop))
        return dap_stop("Sept-Ember Censer coinmaster unavailable.");
    item wash = $item[Mmm-brr! brand mouthwash];
    item wheel = $item[wheel of camembert];
    int quantity = embers / 2;
    if (quantity > 0) {
        if (sell_price(shop, wash) != 2) return dap_stop("Unexpected Sept-Ember mouthwash price.");
        int before = item_amount(wash);
        dap_info("Purchasing " + quantity + " mouthwash for " + (2 * quantity) + " embers.");
        if (!buy(shop, quantity, wash)) return dap_stop("Mouthwash purchase failed.");
        int now = dap_ember_balance();
        if (now != embers - 2 * quantity || item_amount(wash) != before + quantity)
            return dap_stop("Mouthwash purchase verification failed; no retry.");
        embers = now;
    }
    if (embers == 1) {
        if (sell_price(shop, wheel) != 1) return dap_stop("Unexpected camembert price.");
        int before = item_amount(wheel);
        if (!buy(shop, 1, wheel)) return dap_stop("Wheel of camembert purchase failed.");
        if (dap_ember_balance() != 0 || item_amount(wheel) != before + 1)
            return dap_stop("Camembert purchase verification failed.");
    }
    if (dap_ember_balance() != 0) return dap_stop("Sept-Embers remain unspent.");
    return true;
}

boolean dap_craft_and_stock() {
    // Use local KoLmafia CLI commands, not redirectedCommand URLs or pwd tokens.
    // create 1 helmet; acquire enough to have at least 3 of each named food.
    string [int] craft = {
        0:"create 1 aerated diving helmet",
        1:"acquire 3 Boris's bread",
        2:"acquire 3 roasted vegetable of Jarlsberg",
        3:"acquire 3 Pete's rich ricotta",
        4:"acquire 3 roasted vegetable focaccia",
        5:"acquire 3 plain calzone",
        6:"acquire 3 baked veggie ricotta casserole"
    };
    // A failed acquire may be due to unavailability or costly ingredients.
    // Fail closed. Already-owned amounts are left intact.
    if (available_amount($item[aerated diving helmet]) == 0) {
        if (!cli_execute(craft[0]) || available_amount($item[aerated diving helmet]) == 0)
            return dap_stop("Could not create an aerated diving helmet.");
    }
    for i from 1 to 6 {
        string raw = craft[i].substring(10); // Strip `acquire 3 `.
        item required = to_item(raw);
        if (required == $item[none]) return dap_stop("Unknown craft item: " + raw);
        if (available_amount(required) < 3) {
            if (!cli_execute(craft[i]) || available_amount(required) < 3)
                return dap_stop("Could not stock 3 " + raw + ".");
        }
    }
    return true;
}

boolean dap_trophies() {
    // First snapshot the available whichtrophy form inputs. Purchase once only.
    string page = visit_url("trophy.php", false);
    if (page == "") return dap_stop("Trophy Hut page unavailable.");
    matcher m = create_matcher("whichtrophy[^>]*value[^0-9]*([0-9]+)", page);
    boolean [string] seen;
    string [int] ids;
    while (m.find()) {
        string id = m.group(1);
        if (seen[id]) continue;
        seen[id] = true;
        ids[count(ids)] = id;
    }
    foreach i, id in ids {
        if (my_meat() < 10000) return dap_stop("Cannot afford trophy #" + id + " (10,000 Meat).");
        string after_buy = visit_url("trophy.php?action=buytrophy&whichtrophy=" + id, true);
        if (!after_buy.contains_text("Your trophy has been installed")) {
            // Some KoL versions don't include this exact text; re-check live form.
            string refresh_page = visit_url("trophy.php", false);
            matcher still = create_matcher("whichtrophy[^>]*value[^0-9]*" + id + "([^0-9]|$)", refresh_page);
            if (still.find()) return dap_stop("Trophy #" + id + " still available after buy; won't retry.");
        }
        dap_info("Trophy Hut purchase attempted/verified for #" + id + ".");
    }
    return true;
}

boolean dap_raffle_and_susguy() {
    // Visiting this optional NPC is low-risk, but do not claim success on empty HTML.
    buffer page = visit_url("tavern.php?place=susguy", false);
    if (page == "".to_buffer()) dap_info("Susguy visit returned an empty page (advisory).");
    int tickets = item_amount($item[raffle ticket]);
    if (tickets == 0) {
        if (!cli_execute("try; raffle 11")) return dap_stop("Raffle 11 command failed.");
        tickets = item_amount($item[raffle ticket]);
    }
    if (tickets == 11) {
        if (!cli_execute("try; raffle 100")) return dap_stop("Raffle 100 command failed.");
    }
    return true;
}

boolean dap_organs_ready() {
    return my_fullness() >= fullness_limit() &&
        my_spleen_use() >= spleen_limit() &&
        my_inebriety() > inebriety_limit();
}

void dap_print_organs() {
    dap_info("Stomach " + my_fullness() + "/" + fullness_limit() +
        ", spleen " + my_spleen_use() + "/" + spleen_limit() +
        ", liver " + my_inebriety() + "/" + inebriety_limit() +
        ", adventures " + my_adventures() + ", PvP " + pvp_attacks_left());
}

boolean dap_burn_adventures(boolean pill_farm) {
    if (my_adventures() == 0) return true;
    int initial = my_adventures();
    if (pill_farm && initial > 5) {
        int pills = available_amount($item[synthetic dog hair pill]) + available_amount($item[distention pill]);
        if (pills < 200) {
            dap_info("Farming pills with dpills; current accessible pills=" + pills + ".");
            if (!cli_execute("outfit wineglass") || !cli_execute("ccs don_default") ||
                !cli_execute("dpills " + my_adventures()))
                return dap_stop("dpills pill-farming command failed.");
            if (my_adventures() >= initial) return dap_stop("dpills failed to spend adventures.");
        }
    }
    if (my_adventures() > 5) {
        int before = my_adventures();
        if (!cli_execute("combo " + before)) return dap_stop("combo bulk turn burn failed.");
        if (my_adventures() >= before) return dap_stop("combo bulk burn made no progress.");
    }
    if (my_adventures() > 0 && my_adventures() <= 5) {
        int before = my_adventures();
        if (!cli_execute("combo watersheep-" + before))
            return dap_stop("combo watersheep-" + before + " failed.");
        if (my_adventures() >= before) return dap_stop("watersheep combo did not spend adventures.");
    }
    return true;
}

boolean dap_organ_cleanup() {
    dap_print_organs();
    if (!dap_organs_ready() || my_adventures() > 0 || pvp_attacks_left() > 0) {
        print("[don_ascend prep] Organ room/adventures/PvP remain; auto-cleanup needs explicit approval.", "red");
        if (!user_confirm("Fill organs and burn adventures now? This can purchase/consume, overdrink, fight and spend PvP attacks."))
            return dap_stop("Cleanup declined. No ascension.");
        if (!cli_execute("outfit maxorgan")) return dap_stop("Cannot equip maxorgan outfit.");
        dap_info("Filling liver " + my_inebriety() + "/" + inebriety_limit() +
            ", spleen " + my_spleen_use() + "/" + spleen_limit() +
            ", stomach " + my_fullness() + "/" + fullness_limit() + ".");
        if (my_fullness() < fullness_limit() || my_spleen_use() < spleen_limit() ||
            my_inebriety() < inebriety_limit()) {
            if (!cli_execute("consume all value 3700")) return dap_stop("consume all value 3700 failed.");
        }
        if (my_inebriety() <= inebriety_limit()) {
            dap_info("Overdrinking bucket of wine in 5 seconds; KoLmafia Stop cancels the run.");
            wait(5);
            if (!cli_execute("overdrink bucket of wine")) return dap_stop("Overdrink command failed.");
        }
        if (!dap_organs_ready()) return dap_stop("Still have organ room or are not overdrunk.");
        if (!dap_burn_adventures(true)) return false;
        // Optional local PvP scripts: only execute when attacks remain.
        if (pvp_attacks_left() > 0) {
            if (!cli_execute("pvp_mab")) return dap_stop("pvp_mab failed to spend PvP attacks.");
            if (pvp_attacks_left() > 0 && !cli_execute("flogger.ash"))
                return dap_stop("flogger failed to spend PvP attacks.");
        }
    }
    // Even 1-2 adventures are not acceptable at the FINAL gate.
    if (my_adventures() > 0 && my_adventures() <= 5) {
        if (!dap_burn_adventures(false)) return false;
    }
    dap_print_organs();
    if (!dap_organs_ready()) return dap_stop("Stomach/spleen not full, or liver not overdrunk.");
    if (my_adventures() != 0) return dap_stop("Your still adventurous: " + my_adventures() + " remaining.");
    if (pvp_attacks_left() != 0) return dap_stop("PvP attacks remain: " + pvp_attacks_left());
    return true;
}

string dap_path_name(int id) {
    if (id == 0) return "No Path";
    foreach p in $paths[] if (p.id == id) return p.name;
    return "PATH ID " + id;
}
string dap_class_name(int id) {
    foreach c in $classes[] if (c.id == id) return c.to_string();
    return "CLASS ID " + id;
}

// prep_list{} / prep_list() is the central sequential action+gate list.
// IMPORTANT: DO NOT call from the Relay editor or --dry-run.
boolean prep_list(string [string] profile) {
    if (!get_property("kingLiberated").to_boolean())
        return dap_stop("The King has not been freed; aftercore preflight is unavailable.");
    if (!dap_mrstore()) return false;
    if (!dap_interesting_coins()) return false;
    if (!dap_sept_embers()) return false;
    if (!dap_craft_and_stock()) return false;
    if (!dap_trophies()) return false;
    if (!dap_raffle_and_susguy()) return false;
    if (!dap_organ_cleanup()) return false;
    // Recheck currency and readiness immediately before allowing Valhalla.
    if (item_amount($item[interesting coin]) != 0) return dap_stop("Interesting Coins remain.");
    if (dap_ember_balance() != 0) return dap_stop("Sept-Ember balance is nonzero or unknown.");
    if (get_property("availableMrStore2002Credits").to_int() != 0)
        return dap_stop("Mr. Store 2002 credits remain.");
    if (!dap_organs_ready() || my_adventures() != 0 || pvp_attacks_left() != 0)
        return dap_stop("Final organ, adventures, or PvP gate not satisfied.");
    print("[don_ascend prep] Ready to Ascend", "olive");
    string type = profile["type"] == "1" ? "Casual" : profile["type"] == "3" ? "Hardcore" : "Normal";
    string gender = profile["gender"] == "1" ? "male" : "female";
    string summary = "ASCENDING INTO " + dap_path_name(profile["path"].to_int()) +
        " ON " + type + " AS " + dap_class_name(profile["class"].to_int()) +
        " " + gender + ", BUYING astral item #" + profile["deli"] +
        " and equipment #" + profile["armory"] +
        ", perm mode #" + profile["perm_mode"] +
        ", Karma reserve " + profile["karma_hold"] + ".";
    print("[don_ascend prep] " + summary, "red");
    if (!user_confirm(summary + "\nApprove the LIVE ascension? NO cancels. After YES you have 30 seconds to use KoLmafia Stop (ESC where supported)."))
        return dap_stop("Final ascension approval declined.");
    print("[don_ascend prep] LIVE ASCENSION IN 30 SECONDS. PRESS KoLmafia STOP TO ABORT (ESC WHERE SUPPORTED).", "red");
    wait(30); // KoLmafia's Stop/ESC must interrupt ASH; explicit approval was required above.
    if (!dap_organs_ready() || my_adventures() != 0 || pvp_attacks_left() != 0)
        return dap_stop("State changed during countdown; not ascending.");
    return true;
}
