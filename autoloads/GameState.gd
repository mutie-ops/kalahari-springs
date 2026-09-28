extends Node
## KALAHARI SPRINGS — GameState
## Autoload singleton. Generated from the dialogue files and routers.
## 342 variables (318 read by dialogue + 24 affinity/latch). Do not hand-edit names — they must match the
## conditions in the 13 router timelines exactly.
##
## ⚠ Variables marked "SET BY GAMEPLAY CODE" are read by dialogue but
## written by quest/objective/world-simulation code. 99 of them.
## They are declared here so Dialogic can resolve the reference; the
## systems that own them still need wiring.

# ══════════════════════════════════════════════════════════════
# CALENDAR — authoritative. Season derives from chapter and is
# deliberately NOT stored: no router reads it. See any router header.
# ══════════════════════════════════════════════════════════════
var chapter: int = 0
var day: int = 0
var days_in_chapter: int = 0
var time_of_day: String = "morning"

# ── CHAPTER ADVANCEMENT ───────────────────────────────────────
# A chapter advances when BOTH are true:
#   1. every through-line quest for the chapter is "complete"
#   2. days_in_chapter >= MIN_DAYS_PER_CHAPTER
# Past the minimum, the chapter extends indefinitely until (1) holds.
# See Chapter-Advancement_v02.md.
const MIN_DAYS_PER_CHAPTER := 10
# ↑ Tune here. Must stay ABOVE 7, or the day-7 thought nudges become
#   unreachable in fast chapters. Also the day the journal's through-
#   line nudges first appear.
# ⚠ Advancement is implemented in advance_chapter(), which performs
#   all three steps (chapter += 1, days_in_chapter = 0,
#   _on_chapter_changed()). It is checked once each morning from
#   start_new_day() — see the CHAPTER ADVANCEMENT section below.

# ══════════════════════════════════════════════════════════════
# HEARTS — AFFINITY POOL (source of truth, persisted)
# ⚠ Hearts are NOT awarded directly. Affinity points accrue and convert
# at POINTS_PER_HEART. See Hearts-Implementation-Guide_v01.md.
# ══════════════════════════════════════════════════════════════
const POINTS_PER_HEART      := 100
const DAILY_PRESENCE_POINTS := 5    # first interaction per NPC per in-game day
const PRESENCE_CEILING      := 5    # ⚠ presence alone can never exceed Hearts 5
const MAX_HEARTS            := 10

var amos_affinity: int = 0
var charity_affinity: int = 0
var dumi_affinity: int = 0
var ezekiel_affinity: int = 0
var gogo_affinity: int = 0
var lebo_affinity: int = 0
var lindi_affinity: int = 0
var mama_zulu_affinity: int = 0
var naledi_affinity: int = 0
var petrus_affinity: int = 0
var sipho_affinity: int = 0
var zanele_affinity: int = 0

# Daily presence latch — keyed on GameState.day, NEVER a wall-clock timer.
var amos_last_affinity_day: int = -1
var charity_last_affinity_day: int = -1
var dumi_last_affinity_day: int = -1
var ezekiel_last_affinity_day: int = -1
var gogo_last_affinity_day: int = -1
var lebo_last_affinity_day: int = -1
var lindi_last_affinity_day: int = -1
var mama_zulu_last_affinity_day: int = -1
var naledi_last_affinity_day: int = -1
var petrus_last_affinity_day: int = -1
var sipho_last_affinity_day: int = -1
var zanele_last_affinity_day: int = -1

# ══════════════════════════════════════════════════════════════
# HEARTS — RAW, DERIVED from affinity. Read by router Sections 1-4
# (quest and scene ACCESS). Cached so Dialogic can resolve the name.
# ⚠ Do not write these directly. Write affinity; call _refresh_hearts().
# ══════════════════════════════════════════════════════════════
var amos_hearts: int = 0
var charity_hearts: int = 0
var dumi_hearts: int = 0
var ezekiel_hearts: int = 0
var gogo_hearts: int = 0
var lebo_hearts: int = 0
var lindi_hearts: int = 0
var mama_zulu_hearts: int = 0
var naledi_hearts: int = 0
var petrus_hearts: int = 0
var sipho_hearts: int = 0
var zanele_hearts: int = 0

# ── HEARTS FLOOR ──────────────────────────────────────────────
# Read by router Sections 5-6 ONLY (ambient/seasonal tone).
# Derived at read time, never persisted. See
# Hearts-Floor-Convention_v01.md for the rationale and test cases.
const HEARTS_FLOOR := [0, 0, 1, 2, 3, 3, 4, 4, 5, 5]  # indexed by chapter
const NPCS := ["amos", "charity", "dumi", "ezekiel", "gogo", "lebo", "lindi", "mama_zulu", "naledi", "petrus", "sipho", "zanele"]

var amos_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()
var charity_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()
var dumi_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()
var ezekiel_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()
var gogo_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()
var lebo_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()
var lindi_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()
var mama_zulu_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()
var naledi_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()
var petrus_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()
var sipho_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()
var zanele_hearts_ambient: int = 0  # derived — see _refresh_hearts_ambient()

func hearts(npc: String) -> int:
	return get("%s_hearts" % npc)

func hearts_ambient(npc: String) -> int:
	return max(hearts(npc), HEARTS_FLOOR[chapter])

func _refresh_hearts_ambient(npc: String) -> void:
	## Derived, never persisted. Read by router Sections 5-6 ONLY.
	set("%s_hearts_ambient" % npc, hearts_ambient(npc))

func _on_chapter_changed() -> void:
	# Called by advance_chapter(). ⚠ If chapters are ever changed any
	# other way, this must still be called, or the Hearts floor never
	# rises and the feature silently does nothing.
	for npc in NPCS:
		_refresh_hearts_ambient(npc)


# ── AFFINITY API ──────────────────────────────────────────────
# See Hearts-Implementation-Guide_v01.md for rationale and test cases.

func _refresh_hearts(npc: String) -> void:
	var pts: int = get("%s_affinity" % npc)
	set("%s_hearts" % npc, min(MAX_HEARTS, pts / POINTS_PER_HEART))
	_refresh_hearts_ambient(npc)

func add_affinity(npc: String, points: int) -> void:
	if points <= 0:
		return
	var key := "%s_affinity" % npc
	set(key, min(get(key) + points, MAX_HEARTS * POINTS_PER_HEART))
	_refresh_hearts(npc)

func award_hearts(npc: String, n: int) -> void:
	## Call when a dialogue block containing [Hearts +n] completes.
	add_affinity(npc, n * POINTS_PER_HEART)

func try_daily_presence(npc: String) -> void:
	## Call on the FIRST interaction with an NPC each in-game day.
	## ⚠ THE CEILING GUARD IS LOAD-BEARING. Without it, a player who
	## never quests with an NPC still reaches their gated content by
	## walking past them daily. With it, two low-quest NPCs (Gogo and
	## Mama Zulu) can still reach their own late scenes, which they
	## cannot on written awards alone.
	if hearts(npc) >= PRESENCE_CEILING:
		return
	var key := "%s_last_affinity_day" % npc
	if get(key) == day:
		return
	set(key, day)
	add_affinity(npc, DAILY_PRESENCE_POINTS)

# ══════════════════════════════════════════════════════════════
# DIALOGIC SIGNAL HANDLER
# ⚠ THIS WAS MISSING. Every [signal arg="..."] line across all 448
# dialogue .dtl files and 13 router .dtl files emits
# Dialogic.signal_event — but nothing was listening. Without this
# block, every hearts award, every objective, every unlock and every
# progress counter fires into the void.
#
# Argument format is always "kind:payload", one colon separating the
# two. For "hearts" and "increment" the payload itself has a second
# colon ("hearts:sipho:1", "increment:roster_met_count:1"); for
# everything else the payload is free text and is guaranteed NOT to
# contain a colon (verified against all 209 signals actually emitted
# across the project before writing this).
# ══════════════════════════════════════════════════════════════

## Custom, typed signals other systems can connect to. GameState is the
## translation layer between Dialogic's one generic signal_event and
## the rest of the codebase — nothing outside this file should need to
## know Dialogic's argument-string format at all.
signal objective_added(text: String)
signal content_unlocked(text: String)
signal restoration_goal_logged(text: String)
signal npc_was_absent()

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)

func _on_dialogic_signal(argument: String) -> void:
	var parts := argument.split(":", true, 1)  # max 1 split -> [kind, payload]
	if parts.size() < 2:
		push_warning("GameState: malformed signal argument (no ':') — %s" % argument)
		return
	var kind: String = parts[0]
	var payload: String = parts[1]

	match kind:
		"hearts":
			var hp := payload.split(":", true, 1)
			if hp.size() == 2 and hp[1].is_valid_int():
				award_hearts(hp[0], int(hp[1]))
			else:
				push_warning("GameState: malformed hearts signal — %s" % argument)

		"increment":
			var ip := payload.split(":", true, 1)
			if ip.size() == 2 and ip[1].is_valid_int():
				var var_name: String = ip[0]
				if var_name in self:
					set(var_name, get(var_name) + int(ip[1]))
				else:
					push_warning("GameState: increment target does not exist — %s" % var_name)
			else:
				push_warning("GameState: malformed increment signal — %s" % argument)

		"objective":
			objective_added.emit(payload)

		"unlock":
			content_unlocked.emit(payload)

		"restoration_goal":
			restoration_goal_logged.emit(payload)

		"npc_absent":
			npc_was_absent.emit()

		_:
			push_warning("GameState: unrecognised signal kind — %s" % kind)

# ══════════════════════════════════════════════════════════════
# CHAPTER ADVANCEMENT — see Chapter-Advancement_v02.md
# A chapter advances when BOTH hold:
#   1. every through-line quest for the chapter is "complete"
#   2. days_in_chapter >= MIN_DAYS_PER_CHAPTER
# Past the minimum, the chapter simply extends until (1) holds.
#
# ⚠ WHEN THE CHECK RUNS: once, each morning, from start_new_day().
# Deliberately NOT mid-day or at the end of a dialogue timeline:
#   · the chapter changes at a natural seam (Hope wakes, the journal
#     opens) — consistent with transitions being "seamless to the user"
#   · no router condition shifts under a conversation that is still
#     running — the timeline that completes a gate quest may have
#     later lines evaluated against the chapter it started in
#   · one deterministic place to debug
# A player who completes the gate quest at noon on day 12 wakes into
# the new chapter the next morning.
# ══════════════════════════════════════════════════════════════

## Through-line quest flags per chapter — mirrors Quest-And-Event-Guide
## v07. ⚠ Keep in sync with the guide's "Through-line:" fields. If a
## quest is reclassified there, change it here too.
const THROUGH_LINE := {
	0: ["quest_homestead_assessment", "quest_spring_basin_first_run"],
	1: ["quest_charity_roller_case_main"],
	2: ["quest_charity_proof_it_works_main"],
	3: ["quest_sipho_gutter_repair"],
	4: ["quest_sipho_schoolhouse_case"],
	5: ["quest_village_borehole_conversation_main"],
	6: ["quest_hydrogeologist_survey_escort"],
	7: ["quest_sipho_tanks_rollout_main"],
	8: ["quest_hope_job_offer", "quest_borehole_drilling_main"],
	# 9 (Epilogue) — terminal; nothing to advance into.
}
const FINAL_CHAPTER := 9

## Emitted after every advance. The journal, the scheduler, and any
## seasonal visual change connect here — GameState does not reach out
## to them.
signal chapter_advanced(new_chapter: int)
## Emitted each morning, after the day counters tick and after any
## chapter advance. The journal opens on this.
signal day_started(day: int, chapter: int)

func through_line_complete(ch: int) -> bool:
	## True when every through-line quest for chapter `ch` is complete.
	for flag in THROUGH_LINE.get(ch, []):
		if get(flag) != "complete":
			return false
	return true

func incomplete_through_line(ch: int) -> Array:
	## The through-line quest flags still open in chapter `ch`. The
	## journal uses this: "inactive" ones get a nudge (from day 10),
	## "active" ones appear as ordinary tasks.
	var open := []
	for flag in THROUGH_LINE.get(ch, []):
		if get(flag) != "complete":
			open.append(flag)
	return open

func can_advance_chapter() -> bool:
	if chapter >= FINAL_CHAPTER:
		return false
	if days_in_chapter < MIN_DAYS_PER_CHAPTER:
		return false
	return through_line_complete(chapter)

func advance_chapter() -> void:
	## Performs the advance. UNCONDITIONAL — callers check first via
	## can_advance_chapter(). Kept separate so it can be called directly
	## when testing or debugging a specific chapter.
	## ⚠ All three steps, always, in this order:
	chapter += 1
	days_in_chapter = 0       # re-arms the day-7 nudges, day-10 minimum
							  # and day-14 forgiveness doors for the new
							  # chapter; without it they fire at once
	_on_chapter_changed()     # raises the Hearts floor; without it the
							  # floor silently never rises
	chapter_advanced.emit(chapter)

func try_advance_chapter() -> bool:
	if can_advance_chapter():
		advance_chapter()
		return true
	return false

func start_new_day() -> void:
	## ⚠ THE ONLY PLACE days advance and chapters change. Called once
	## per in-game morning by whatever system handles Hope waking (the
	## scheduler / sleep system — a follow-up task). Nothing else should
	## increment day or days_in_chapter.
	day += 1
	days_in_chapter += 1
	try_advance_chapter()
	day_started.emit(day, chapter)

# ══════════════════════════════════════════════════════════════
# QUEST FLAGS — "inactive" / "active" / "complete"
# ⚠ Parent quests keep the _main suffix. Do not strip it.
# ══════════════════════════════════════════════════════════════
var quest_amos_pathway_smoothing: String = "inactive"
var quest_borehole_drilling_main: String = "inactive"  # ⚠ THROUGH-LINE (Ch. 8). Set by village_borehole_drilling_intro (Ch. 7) and village_borehole_first_water (Ch. 8). Was undeclared until v07 — the quest had no dialogue, so no scan ever found it.
var quest_charity_mill_campaign: String = "inactive"
var quest_charity_one_last_petition: String = "inactive"
var quest_charity_outpost_upgrade_campaign: String = "inactive"
var quest_charity_proof_it_works_main: String = "inactive"
var quest_charity_roller_case_main: String = "inactive"
var quest_dumi_mill_lead: String = "inactive"
var quest_dumi_outpost_sourcing_main: String = "inactive"
var quest_ezekiel_repay_hope: String = "inactive"
var quest_ezekiel_rounds_main: String = "inactive"
var quest_ezekiel_test_plot: String = "inactive"
var quest_gogo_borehole_blessing: String = "inactive"
var quest_gogo_irrigation_referral: String = "inactive"
var quest_gogo_quiet_watch: String = "inactive"
var quest_gogo_reunion: String = "inactive"
var quest_gogo_rock_cistern: String = "inactive"
var quest_homestead_assessment: String = "inactive"
var quest_hope_job_offer: String = "inactive"  # ⚠ SET BY GAMEPLAY CODE
var quest_hydrogeologist_survey_escort: String = "inactive"
var quest_lebo_mill_parts_main: String = "inactive"
var quest_lindi_big_haul: String = "inactive"
var quest_lindi_correspondence_course: String = "inactive"
var quest_lindi_glut_triage: String = "inactive"
var quest_lindi_kumbi_kumbi_one: String = "inactive"
var quest_lindi_kumbi_kumbi_two: String = "inactive"
var quest_lindi_market_stall: String = "inactive"
var quest_lindi_mopane_efficient: String = "inactive"
var quest_lindi_ripe_or_not: String = "inactive"
var quest_lindi_smoke_and_dry: String = "inactive"
var quest_market_flood_dig: String = "inactive"
var quest_mkhize_roller_pen: String = "inactive"  # ⚠ SET BY GAMEPLAY CODE
var quest_mkhize_storm_prep: String = "inactive"
var quest_naledi_alternate_rotation_main: String = "inactive"
var quest_naledi_solar_mill_placement: String = "inactive"
var quest_naledi_stall_reopening: String = "inactive"
var quest_naledi_this_is_home: String = "inactive"
var quest_naledi_treadle_rediscovery: String = "inactive"
var quest_petrus_mill_stash: String = "inactive"
var quest_sipho_gutter_repair: String = "inactive"
var quest_sipho_schoolhouse_case: String = "inactive"
var quest_sipho_tanks_rollout_main: String = "inactive"
var quest_spring_basin_first_run: String = "inactive"  # ⚠ SET BY GAMEPLAY CODE
var quest_village_borehole_conversation_main: String = "inactive"
var quest_village_getting_reacquainted_main: String = "inactive"
var quest_watering_hole_fuel_and_tablets_main: String = "inactive"
var quest_watering_hole_outpost_build_main: String = "inactive"  # ⚠ SET BY GAMEPLAY CODE
var quest_watering_hole_solar_install: String = "inactive"
var quest_zanele_schoolhouse_opening: String = "inactive"
var quest_zanele_sipho_farewell: String = "inactive"

# ══════════════════════════════════════════════════════════════
# ⚙ MILESTONE EVENTS — same value vocabulary as quests, but NOT
# quests: no journal entry, no objective, no player-gated
# completion. See Content-Type-Convention_v01.md.
#
# ⚠ A COMPLETION VARIABLE EXISTS FOR ALL FOUR, BY DESIGN — even the
# two that nothing currently gates on. Rationale: a uniform rule
# ("every milestone event has one") is easier for engineers to hold
# than a split rule, and costs two unused booleans. But WHAT SETS
# THEM differs materially between the two kinds below, and that
# distinction is load-bearing. Read before wiring.
#
# ── KIND A: WORLD-STATE EVENTS ────────────────────────────────
# Set to "complete" BY THE SYSTEM SCHEDULER when the event's
# scheduled days elapse. The player is not required to witness
# anything. Nothing downstream currently gates on these — dialogue
# that follows them may simply ASSUME they occurred, per the
# scheduling-is-certain principle.
# ⚠ Neither is through-line (reclassified in Quest & Event Guide v07).
# Milestone events are not player-actionable, so they cannot hold a
# chapter gate. Rule: chapter advancement ALWAYS depends on something
# the player can do. These still fire on schedule; they just don't
# block advancement.
var evt_borehole_platform_pour: String = "inactive"
# ↑ Ch. 7 · world-state · 3 in-game days · Amos runs the pour.
var evt_outpost_foundation: String = "inactive"
# ↑ Ch. 4 · world-state · 3–4 in-game days · Amos runs the build.

# ── KIND B: DISCOVERY EVENTS ──────────────────────────────────
# ⚠ SET WHEN THE PLAYER SEES THE SCENE — not when the event occurs.
# These are NOT "did it happen" flags; they are "has Hope found it
# yet" flags, and they are read by village_router as ONE-TIME
# LATCHES:
#     elif ... {GameState.evt_homestead_roof_repair} != "complete" ...
# Without the latch, Hope re-discovers the repaired roof on EVERY
# entry to the homestead. The .dtl block sets the flag itself on
# exit — do not also set it from the scheduler, or the scene is
# consumed before the player ever reaches it.
# Neither is through-line; both are optional discoveries.
var evt_homestead_door_repair: String = "inactive"
# ↑ Ch. 6 · discovery · Lebo repairs it off-screen, unasked.
var evt_homestead_roof_repair: String = "inactive"
# ↑ Ch. 4 · discovery · Lebo repairs it off-screen, unasked.

# ══════════════════════════════════════════════════════════════
# ROUTER SYSTEM — the village_router handoff and Sunday state.
# ══════════════════════════════════════════════════════════════
var interaction_location: String = ""
var interaction_npc: String = ""
var interaction_object: String = ""  # ⚠ NEW — added for village_homestead_assessment_progress.
# Distinguishes door/garden/drum, which all share "homestead_exterior"
# as their interaction_location and cannot be told apart by location
# alone. Set by the interaction handler when Hope interacts with a
# specific tagged object (screen_door / garden_bed / water_drum),
# as distinct from a location ENTER or an NPC TALK.
var interaction_type: String = ""
var sunday_dressing_shown: bool = false
var sunday_pending: bool = false
var village_beat_matched: bool = false

# ══════════════════════════════════════════════════════════════
# ROUTER LATCHES — stop blocks repeating. Each is set by the
# timeline it guards. Seasonal latches init to -1 so chapter 0
# still fires.
# ══════════════════════════════════════════════════════════════
var amos_seasonal_last_chapter: int = -1
var charity_seasonal_last_chapter: int = -1
var dumi_seasonal_last_chapter: int = -1
var ezekiel_ambient_34_toggle: int = 0
var ezekiel_seasonal_last_chapter: int = -1
var ezekiel_visit_variant_index: int = 0
var gogo_q3_ambient_last_day: int = -99
var gogo_seasonal_last_chapter: int = -1
var lebo_seasonal_last_chapter: int = -1
var lindi_seasonal_last_chapter: int = -1
var mama_zulu_seasonal_last_chapter: int = -1
var naledi_seasonal_last_chapter: int = -1
var petrus_seasonal_last_chapter: int = -1
var sipho_install_variant_index: int = 0
var sipho_seasonal_last_chapter: int = -1
var zanele_ambient_12_toggle: int = 0
var zanele_seasonal_last_chapter: int = -1

# ══════════════════════════════════════════════════════════════
# COUNTERS & PROGRESS
# ══════════════════════════════════════════════════════════════
var borehole_checkins_heard: int = 0
var ezekiel_deliveries: int = 0  # ⚠ SET BY GAMEPLAY CODE
var gogo_water_deliveries: int = 0  # ⚠ SET BY GAMEPLAY CODE
var grading_progress: float = 0.0  # ⚠ SET BY GAMEPLAY CODE
var gutter_repair_progress: float = 0.0  # ⚠ SET BY GAMEPLAY CODE
var haul_progress: float = 0.0  # ⚠ SET BY GAMEPLAY CODE
var homestead_rooms_assessed: int = 0
var household_tanks_installed: int = 0  # ⚠ SET BY GAMEPLAY CODE
var households_visited: int = 0  # ⚠ SET BY GAMEPLAY CODE
var mama_zulu_deliveries: int = 0  # ⚠ SET BY GAMEPLAY CODE
var market_dig_progress: float = 0.0  # ⚠ SET BY GAMEPLAY CODE
var outcomes_documented: int = 0  # ⚠ SET BY GAMEPLAY CODE
var outpost_leads_followed: int = 0  # ⚠ SET BY GAMEPLAY CODE
var petrus_stash_visited: int = 0
var rock_cistern_progress: float = 0.0  # ⚠ SET BY GAMEPLAY CODE
var roller_fleet_count: int = 0  # ⚠ SET BY GAMEPLAY CODE
var roster_met_count: int = 0
var rotation_runs_completed: int = 0  # ⚠ SET BY GAMEPLAY CODE
var schoolhouse_case_documented: int = 0  # ⚠ SET BY GAMEPLAY CODE
var solar_install_progress: float = 0.0  # ⚠ SET BY GAMEPLAY CODE
var solar_mill_installed: int = 0  # ⚠ SET BY GAMEPLAY CODE
var stall_setup_progress: float = 0.0  # ⚠ SET BY GAMEPLAY CODE
var storm_prep_progress: float = 0.0  # ⚠ SET BY GAMEPLAY CODE
var survey_sites_visited: int = 0
var testimonies_gathered: int = 0  # ⚠ SET BY GAMEPLAY CODE
var upkeep_accounts_collected: int = 0  # ⚠ SET BY GAMEPLAY CODE

# ══════════════════════════════════════════════════════════════
# WORLD FLAGS
# ══════════════════════════════════════════════════════════════
var amos_arc_complete: bool = false
var amos_build_finished: bool = false
var amos_build_started: bool = false
var amos_build_tested: bool = false
var amos_diagnosis_seen: bool = false
var amos_road_crew_seen: bool = false
var amos_sketches_seen: bool = false
var borehole_blessing_complete: bool = false
var borehole_blessing_site_ready: bool = false  # ⚠ SET BY GAMEPLAY CODE
var borehole_complete: bool = false  # ⚠ SET BY GAMEPLAY CODE
var borehole_drilling_begun: bool = false  # ⚠ SET BY GAMEPLAY CODE
var borehole_ngo_contact_found: bool = false
var borehole_survey_done: bool = false
var charity_home_access: bool = false
var charity_home_realisation: bool = false
var charity_location: String = ""  # ⚠ SET BY GAMEPLAY CODE — assumes an NPC schedule system reporting her current canonical location tag (e.g. "charity_outpost", "charity_homestead"). See Charity-Mokoena_Router_v01.md LOCATION NOTE.
var charity_paperwork_complete: bool = false  # ⚠ SET BY GAMEPLAY CODE
var charity_petition_approved: bool = false  # ⚠ SET BY GAMEPLAY CODE
var charity_petition_filed: bool = false
var charity_prologue_doubt_seen: bool = false
var drying_racks_built: bool = false
var dumi_arc_complete: bool = false
var dumi_coop_drafting: bool = false
var dumi_economy_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var dumi_favor_seen: bool = false
var dumi_introduced: bool = false
var dumi_ledger_seen: bool = false
var dumi_mill_lead_started: bool = false  # ⚠ SET BY GAMEPLAY CODE
var dumi_refused_deal: bool = false
var dumi_school_worry_seen: bool = false
var dumi_sunday_seen: bool = false
var dumi_sunday_test: bool = false
var ezekiel_advice_a_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var ezekiel_advice_b_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var ezekiel_arc_complete: bool = false
var ezekiel_bad_winter_seen: bool = false
var ezekiel_letter_seen: bool = false
var ezekiel_reciprocity_established: bool = false
var ezekiel_taught_students: bool = false
var ezekiel_trusted: bool = false
var first_major_rain: bool = false  # ⚠ SET BY GAMEPLAY CODE
var first_rains_arrived: bool = false  # ⚠ SET BY GAMEPLAY CODE
var flood_event_active: bool = false  # ⚠ SET BY GAMEPLAY CODE
var fuel_tablets_rotation_staffed: bool = false
var glut_processed: bool = false  # ⚠ SET BY GAMEPLAY CODE
var gogo_borehole_check_in_reached: bool = false
var gogo_borehole_endorsement_given: bool = false
var gogo_confirmed_grandmother_boxes: bool = false
var gogo_folklore_story_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var gogo_grandmother_memory_shared: bool = false
var gogo_homestead_visits: bool = false  # ⚠ SET BY GAMEPLAY CODE
var gogo_location: String = ""  # ⚠ SET BY GAMEPLAY CODE — assumes an NPC schedule system reporting her current canonical location tag (e.g. "gogo_homestead"). See Gogo-Thandiwe_Router_v01.md LOCATION NOTE.
var gogo_mama_zulu_visit_complete: bool = false
var gogo_reunion_complete: bool = false  # ⚠ SET BY GAMEPLAY CODE
var gogo_scholarship_foresight_flag: bool = false
var gogo_sipho_mother_hint_given: bool = false
var gogo_this_is_home_scene_complete: bool = false
var grandmothers_boxes_found: bool = false
var grandmothers_boxes_used_gutter: bool = false
var grandmothers_boxes_used_mill: bool = false
var gutter_joint_reached: bool = false  # ⚠ SET BY GAMEPLAY CODE
var homestead_door_flagged: bool = false
var homestead_drum_flagged: bool = false
var homestead_garden_flagged: bool = false
var homestead_interior_entered: bool = false  # ⚠ SET BY GAMEPLAY CODE
var homestead_roof_flagged: bool = false
var hope_decides_to_stay: bool = false  # ⚠ SET BY GAMEPLAY CODE
var hope_doubts_raised: bool = false
var hope_irrigation_built: bool = false  # ⚠ SET BY GAMEPLAY CODE
var hope_plot_improved: bool = false  # ⚠ SET BY GAMEPLAY CODE
var hope_raised_roller_shortage: bool = false
var hope_staying_confirmed: bool = false
var hope_staying_decision_pending: bool = false  # ⚠ SET BY GAMEPLAY CODE
var hydrogeologist_arrived: bool = false  # ⚠ SET BY GAMEPLAY CODE
var illness_reported: bool = false  # ⚠ SET BY GAMEPLAY CODE
var irrigation_parts_taken: bool = false  # ⚠ SET BY GAMEPLAY CODE
var kumbi_flight_active: bool = false  # ⚠ SET BY GAMEPLAY CODE
var kumbi_harvest_one_complete: bool = false
var kumbi_window_approaching: bool = false  # ⚠ SET BY GAMEPLAY CODE
var leadership_talk_established: bool = false
var lebo_arc_complete: bool = false
var lebo_fixed_inn_roof: bool = false
var lebo_pathway_patch_laid: bool = false
var lebo_radio_introduced: bool = false
var lindi_big_haul_complete: bool = false
var lindi_epilogue_scene_complete: bool = false
var lindi_larder_established: bool = false
var lindi_location: String = ""  # ⚠ SET BY GAMEPLAY CODE — assumes an NPC schedule system reporting her current canonical location tag (e.g. "naledi_homestead"). See Lindiwe-Dube_Router_v01.md LOCATION NOTE.
var lindi_mama_zulu_mentorship: bool = false
var lindi_reputation_established: bool = false
var lindi_semester_admitted: bool = false
var lindi_stall_open: bool = false
var lindi_stall_setup: bool = false  # ⚠ SET BY GAMEPLAY CODE
var mama_zulu_accepted_payment: bool = false
var mama_zulu_debt_written_off: bool = false
var mama_zulu_ezekiel_confidant: bool = false
var mama_zulu_knowledge_a_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var mama_zulu_knowledge_b_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var mama_zulu_legacy_complete: bool = false
var mama_zulu_lindi_reciprocity: bool = false
var mama_zulu_noticed_treadle: bool = false
var mama_zulu_reciprocity_established: bool = false
var mama_zulu_roof_finished: bool = false
var mama_zulu_tally_seen: bool = false
var mama_zulu_trusted: bool = false
var marula_glut_active: bool = false  # ⚠ SET BY GAMEPLAY CODE
var met_amos: bool = false  # ⚠ SET BY GAMEPLAY CODE — village_getting_reacquainted_encounter
var met_charity: bool = false  # ⚠ SET BY GAMEPLAY CODE
var met_dumi: bool = false  # ⚠ SET BY GAMEPLAY CODE — village_getting_reacquainted_encounter
var met_ezekiel: bool = false  # ⚠ SET BY GAMEPLAY CODE — village_getting_reacquainted_encounter
var met_lebo: bool = false  # ⚠ SET BY GAMEPLAY CODE — village_getting_reacquainted_encounter
var met_lindi: bool = false  # ⚠ SET BY GAMEPLAY CODE — village_getting_reacquainted_encounter
var met_mama_zulu: bool = false  # ⚠ SET BY GAMEPLAY CODE — village_getting_reacquainted_encounter
var met_naledi: bool = false  # ⚠ SET BY GAMEPLAY CODE — village_getting_reacquainted_encounter
var met_petrus: bool = false  # ⚠ SET BY GAMEPLAY CODE — village_getting_reacquainted_encounter
var met_sipho: bool = false  # ⚠ SET BY GAMEPLAY CODE — village_getting_reacquainted_encounter
var met_zanele: bool = false  # ⚠ SET BY GAMEPLAY CODE — village_getting_reacquainted_encounter
var mill_case_assembled: bool = false  # ⚠ SET BY GAMEPLAY CODE
var mill_collar_missing: bool = false
var mill_crankshaft_recovered: bool = false  # ⚠ SET BY GAMEPLAY CODE
var mill_frustration_established: bool = false
var mill_plate_recovered: bool = false  # ⚠ SET BY GAMEPLAY CODE
var mill_repaired: bool = false  # ⚠ SET BY GAMEPLAY CODE
var mkhize_brothers_epilogue_complete: bool = false
var mkhize_workshop_active: bool = false
var mopane_processed: bool = false  # ⚠ SET BY GAMEPLAY CODE
var mopane_second_outbreak: bool = false  # ⚠ SET BY GAMEPLAY CODE
var mulch_stage: bool = false  # ⚠ SET BY GAMEPLAY CODE
var naledi_blessing_cloth_ready: bool = false
var naledi_committee_chair: bool = false
var naledi_disputes_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var naledi_firepit_ch6_complete: bool = false
var naledi_headwoman: bool = false
var naledi_lindi_stall_granted: bool = false
var naledi_pen_schedule_posted: bool = false
var naledi_schedule_posted: bool = false
var naledi_stitching_seen: bool = false
var naledi_treadle_running: bool = false
var naledi_visits_post_ch2: bool = false  # ⚠ SET BY GAMEPLAY CODE
var ngo_tank_donation_received: bool = false  # ⚠ SET BY GAMEPLAY CODE
var nudge_sipho_gutter_seen: bool = false
var nudge_sipho_schoolhouse_seen: bool = false
var opening_prep_complete: bool = false  # ⚠ SET BY GAMEPLAY CODE
var outpost_blockwork_complete: bool = false  # ⚠ SET BY GAMEPLAY CODE
var outpost_materials_list_made: bool = false  # ⚠ SET BY GAMEPLAY CODE
var outpost_materials_partial: bool = false
var outpost_operational: bool = false  # ⚠ SET BY GAMEPLAY CODE
var outpost_upkeep_complaints: bool = false  # ⚠ SET BY GAMEPLAY CODE
var pen_frame_complete: bool = false  # ⚠ SET BY GAMEPLAY CODE
var petrus_animal_scare_seen: bool = false
var petrus_arc_complete: bool = false
var petrus_deadpan_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var petrus_herd_growing: bool = false
var petrus_lent_ezekiel_tools: bool = false
var petrus_location: String = ""  # ⚠ SET BY GAMEPLAY CODE — assumes an NPC schedule system reporting his current canonical location tag (e.g. "petrus_stash"). See Petrus-Sithole_Router_v01.md LOCATION NOTE.
var petrus_mill_lead_started: bool = false  # ⚠ SET BY GAMEPLAY CODE
var petrus_sideways_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var petrus_stash_open: bool = false
var petrus_traded_mangle: bool = false
var preservation_learned: bool = false  # ⚠ SET BY GAMEPLAY CODE
var preservation_methods_known: bool = false
var radio_works: bool = false
var ripe_sorting_complete: bool = false  # ⚠ SET BY GAMEPLAY CODE
var rock_outcrop_site_confirmed: bool = false
var roller_pen_built: bool = false  # ⚠ SET BY GAMEPLAY CODE
var roller_petition_submitted: bool = false
var roller_schedule_running: bool = false  # ⚠ SET BY GAMEPLAY CODE
var school_attendance_surge: bool = false  # ⚠ SET BY GAMEPLAY CODE
var school_construction_complete: bool = false  # ⚠ SET BY GAMEPLAY CODE
var schoolhouse_case_submitted: bool = false  # ⚠ SET BY GAMEPLAY CODE
var schoolhouse_opening_complete: bool = false  # ⚠ SET BY GAMEPLAY CODE
var schoolhouse_system_built: bool = false
var schoolhouse_system_delivered: bool = false  # ⚠ SET BY GAMEPLAY CODE
var schoolhouse_system_proven: bool = false
var sipho_cost_scene_seen: bool = false
var sipho_departed: bool = false
var sipho_lamplight_scene_seen: bool = false
var sipho_location: String = ""  # ⚠ SET BY GAMEPLAY CODE — assumes an NPC schedule system reporting his current canonical location tag (e.g. "homestead", "meetinghouse", "school", "gogo_homestead"). See Sipho-Nkosi_Router_v02.md LOCATION NOTE.
var sipho_q1_complete_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var sipho_roller_calc_shared: bool = false
var sipho_scholarship_received: bool = false
var sipho_schoolhouse_excitement_flag: bool = false
var sipho_teaching_assistant: bool = false
var solar_equipment_delivered: bool = false  # ⚠ SET BY GAMEPLAY CODE
var solar_mill_delivered: bool = false  # ⚠ SET BY GAMEPLAY CODE
var test_plot_planted: bool = false  # ⚠ SET BUT DELIBERATELY NEVER READ.
# Set by ezekiel_q2_complete when Hope delivers Petrus's tools. Nothing
# gates on it by design: qst_ezekiel_test_plot is optional, and gating
# ezekiel_scene_plot_succeeds on this flag silently orphaned four
# downstream items (that scene, ezekiel_scene_students_visit,
# ezekiel_ambient_05, all of qst_ezekiel_repay_hope) plus Zanele's Ch. 3
# guest-teacher scene. Ezekiel plants the plot either way — if Hope
# didn't carry the tools, he got them another way and the game never
# explains it. Retained as a record of whether Hope actually helped, in
# case a later system wants it. Do NOT re-add it as a gate.
var test_plot_succeeded: bool = false
var test_plot_tools_delivered: bool = false  # ⚠ SET BY GAMEPLAY CODE
var treadle_parts_found: bool = false  # ⚠ SET BY GAMEPLAY CODE
var water_committee_formed: bool = false  # ⚠ SET BY GAMEPLAY CODE
var zai_pits_stage: bool = false  # ⚠ SET BY GAMEPLAY CODE
var zanele_arc_complete: bool = false
var zanele_case_support_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var zanele_device_seen: bool = false  # ⚠ SET BY GAMEPLAY CODE
var zanele_guest_teachers: bool = false
var zanele_head_teacher: bool = false
var zanele_mama_zulu_food: bool = false
var zanele_needs_building: bool = false
var zanele_nomination_revealed: bool = false
var zanele_nomination_weight: bool = false
