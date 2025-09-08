-- lobia_pack
-- Pack vorod + /asb + /lobia (top-up baste be hadf-e saghf)

local HORSE_ENTITY = "mobs_mc:horse" -- ya "mcl_mobs:horse" agar version fargh dasht
local horse_refs = {}

-- ===== helpers =====
local function count_item(inv, listname, itemname)
    local n = 0
    for _, st in ipairs(inv:get_list(listname) or {}) do
        if not st:is_empty() and st:get_name() == itemname then
            n = n + st:get_count()
        end
    end
    return n
end

local function topup_item(inv, listname, itemname, target)  -- faqat kambood ro por mikone
    local have = count_item(inv, listname, itemname)
    local need = target - have
    if need > 0 then
        local leftover = inv:add_item(listname, ItemStack(itemname .. " " .. need))
        if not leftover:is_empty() then
            -- yeki-cheshm: inventory por bud, harchi shod add shod
            return need - leftover:get_count(), true
        end
        return need, false
    end
    return 0, false
end

local function ensure_one(inv, listname, itemname)          -- age nadarad, 1 ta bede
    if inv:contains_item(listname, ItemStack(itemname .. " 1")) then
        return false
    end
    local leftover = inv:add_item(listname, ItemStack(itemname .. " 1"))
    return leftover:is_empty()  -- true = ezafe shod
end

-- ===== pack rules (saghf) =====
local CAPS = {
    ["mcl_core:apple"]      = 64,
    ["mcl_bows:arrow"]      = 250,
    ["mcl_torches:torch"]   = 20,
}
local SINGLES = {
    "mcl_bows:bow",
    "mcl_bows:crossbow",
    "mcl_tools:pick_netherite",
    "mcl_tools:axe_netherite",
    "mcl_tools:shovel_netherite",
    "mcl_tools:sword_netherite",
    "mcl_shields:shield",
    "mcl_mobitems:saddle",
}

-- 🎁 Pack bqa (top-up)
local function give_pack(player)
    local inv = player:get_inventory()
    local added_any = false

    -- top-up bar asas CAPS
    for name, cap in pairs(CAPS) do
        local added = select(1, topup_item(inv, "main", name, cap))
        if added > 0 then added_any = true end
    end

    -- items-e teki: faghat age nadarad
    for _, name in ipairs(SINGLES) do
        local ok = ensure_one(inv, "main", name)
        if ok then added_any = true end
    end

    if added_any then
        minetest.chat_send_player(player:get_player_name(), "Pack bqa top-up shod ✅")
    else
        minetest.chat_send_player(player:get_player_name(), "Pack kamboodi nadashti ✅")
    end
end

-- 🐴 Summon ya teleport horse
local function summon_horse(player)
    local pname = player:get_player_name()

    if horse_refs[pname] and horse_refs[pname]:get_luaentity() then
        local ppos = player:get_pos()
        if ppos then
            horse_refs[pname]:set_pos({x=ppos.x+2, y=ppos.y, z=ppos.z+2})
        end
        minetest.chat_send_player(pname, "Asbet hamin ja hast!")
        return
    end

    local pos = player:get_pos()
    if not pos then return end
    pos.x = pos.x + 2
    pos.z = pos.z + 2

    local horse = minetest.add_entity(pos, HORSE_ENTITY)
    if horse then
        local ent = horse:get_luaentity()
        ent.owner = pname
        ent.tamed = true
        ent.child = false
        ent.saddle = true
        horse_refs[pname] = horse
        minetest.chat_send_player(pname, "Asb omad!")
    else
        minetest.chat_send_player(pname, "Asb nist, spawn nashod!")
    end
end

-- 📝 /asb
minetest.register_chatcommand("asb", {
    description = "Asb ro seda kon (faghat 1 ta).",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then summon_horse(player) end
    end,
})

-- 📝 /lobia (restock top-up + anti-spam)
minetest.register_chatcommand("lobia", {
    description = "Pack bqa ro top-up konad (ghaza, tools, bow...).",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return end

        local meta = player:get_meta()
        local now  = os.time()
        local last = meta:get_int("lobia_last_ts") or 0
        local wait = 120  -- saniye

        if now - last < wait then
            local left = wait - (now - last)
            minetest.chat_send_player(name, "Sabr kon "..left.."s baraye /lobia")
            return
        end

        give_pack(player)
        meta:set_int("lobia_last_ts", now)
    end,
})

-- on-join: bejaye add endles, top-up kon
minetest.register_on_joinplayer(function(player)
    give_pack(player)
end)

-- clean refs
minetest.register_on_leaveplayer(function(player)
    horse_refs[player:get_player_name()] = nil
end)

minetest.register_globalstep(function(dtime)
    for pname, ref in pairs(horse_refs) do
        if not (ref and ref:get_luaentity()) then
            horse_refs[pname] = nil
        end
    end
end)











