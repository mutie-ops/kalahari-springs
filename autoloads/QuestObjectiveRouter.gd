extends Node
## KALAHARI SPRINGS — Quest Objective Router
## Autoload singleton. Bridges GameState's typed `objective_added` signal to
## quest-start calls, currently against local active_quests/completed_quests
## tracking (see ⚠ NOTE below on Nexus Quest Weaver integration).
##
## ⚠ SCOPE: this file only handles the "objective" signal kind
## (GameState.objective_added). "unlock" (content_unlocked),
## "restoration_goal" (restoration_goal_logged), and "npc_absent"
## (npc_was_absent) still need their own routing — not attempted here.
##
## Generated from Kalahari-Springs_Signal-Manifest_v01.xlsx (objective rows,
## 52 signals / 48 unique payload texts — 3 texts repeat verbatim across two
## or three .dtl files for the same quest, so they collapse to one match arm
## each; see the manifest for the full file list per payload).

# ══════════════════════════════════════════════════════════════
# ⚠ CHANGES FROM THE TEMPLATE — see chat for full explanation:
#
# 1. _ready() connected to the wrong signal. `signal_event` isn't a real
#    signal anywhere in this project, and even fixed to `Dialogic.signal_event`
#    it would be wrong: GameState.gd is deliberately "the one place that knows
#    Dialogic's raw string format" (Signal-Handler-Structure.txt) so that
#    nothing else has to re-parse "kind:payload" strings. This router listens
#    to GameState's own already-typed `objective_added(text: String)` signal
#    instead, which is the one GameState.gd's _on_dialogic_signal() emits for
#    every "objective:..." Dialogic call.
#
# 2. The connected callback name didn't match the function actually defined
#    (_on_objective_added vs. _on_objective_added_signal). Renamed both to
#    _on_objective_added and given it the (text: String) signature GameState's
#    signal actually carries.
#
# 3. active_quests / completed_quests were referenced by start_quest() /
#    complete_quest() but never declared anywhere in the template, so this
#    file would fail to compile as pasted. Declared them below as a stopgap —
#    but see the Nexus Quest Weaver note, this may not be where they belong.
#
# ⚠ NEXUS QUEST WEAVER — WORTH CONFIRMING BEFORE THIS GOES FURTHER:
# I could not find a Godot plugin literally named "QuestWeaver," but I did
# find "Nexus Quest Weaver" on the Godot Asset Library, which looks like a
# strong match for what you described. Its own listing describes a
# *decoupled, event-driven* architecture — "Your game sends signals (Events),
# and Quest Weaver handles the logic" — plus its own built-in save/load and
# state manager. That's a different shape than this file: right now
# start_quest()/complete_quest() just push strings into two local arrays
# that nothing outside this file reads. If that's really the plugin in use,
# it likely wants this router to fire an event/signal INTO Quest Weaver
# rather than maintain its own parallel active/completed lists — worth
# checking the plugin's actual API before wiring the other three signal
# kinds the same way. Flagging rather than guessing, since I can't see the
# plugin's source from here.
# ══════════════════════════════════════════════════════════════

var active_quests: Array[String] = []
var completed_quests: Array[String] = []

func _ready() -> void:
	GameState.objective_added.connect(_on_objective_added)

func _on_objective_added(text: String) -> void:
	match text:

		# ── PROLOGUE ──────────────────────────────
		"No hurry. Nobody is expecting you.":
			start_quest("qst_village_getting_reacquainted_main")
		"Walk the village. The market, the spring, the school, the watering hole.":
			start_quest("qst_village_getting_reacquainted_main")
		"Walk the property and log what needs doing. Fix nothing yet.":
			start_quest("qst_homestead_assessment")
		"Sort foraged items — ripe / not yet / leave it":
			start_quest("qst_lindi_ripe_or_not")

		# ── CHAPTER 1 ──────────────────────────────
		"Take a turn on the fuel and tablets rotation":
			start_quest("qst_watering_hole_fuel_and_tablets_main")
		"Gather water-burden testimony from several households":
			start_quest("qst_charity_roller_case_main")
		"Find the NPC Gogo has pointed toward and learn to build a drip system":
			start_quest("qst_gogo_irrigation_referral")
		"Run water to Mama Zulu and Ezekiel on alternate days":
			start_quest("qst_naledi_alternate_rotation_main")
		"Retrieve tubing and fittings for the drip system":
			# Sub-objective text update — qst_gogo_irrigation_referral is already active (started earlier, by another
			# NPC's file). start_quest()'s guard makes this a harmless no-op, but it is NOT where
			# the quest actually starts. Flag to Ben: does the journal need an update_objective()
			# call here instead, to refresh the displayed objective text mid-quest?
			start_quest("qst_gogo_irrigation_referral")

		# ── CHAPTER 2 ──────────────────────────────
		"Document positive outcomes from the first three rollers and the sharing schedule":
			start_quest("qst_charity_proof_it_works_main")
		"Follow Dumi's leads and source what materials you can":
			start_quest("qst_dumi_outpost_sourcing_main")
		"Collect the tools from Petrus's equipment graveyard and deliver them to Ezekiel's farm":
			start_quest("qst_ezekiel_test_plot")
		"Recruit volunteers before the flight; be ready when the rain trigger fires":
			start_quest("qst_lindi_kumbi_kumbi_one")
		"Deliver the tools to Ezekiel's farm":
			# Sub-objective text update — qst_ezekiel_test_plot is already active (started earlier, by another
			# NPC's file). start_quest()'s guard makes this a harmless no-op, but it is NOT where
			# the quest actually starts. Flag to Ben: does the journal need an update_objective()
			# call here instead, to refresh the displayed objective text mid-quest?
			start_quest("qst_ezekiel_test_plot")

		# ── CHAPTER 3 ──────────────────────────────
		"Help dig out the market":
			start_quest("qst_market_flood_dig")
		"Join the community work-day and help grade the pathways":
			start_quest("qst_amos_pathway_smoothing")
		"Prioritise what to haul given limited container capacity over several days":
			start_quest("qst_lindi_big_haul")
		"Help clear the storage space around the machine; find oil and a spare bobbin":
			start_quest("qst_naledi_treadle_rediscovery")
		"Build a stone catchment to redirect overflow into the garden":
			# ⚠ NOT A QUEST START. Quest & Event Guide (line 255, quest_sipho_gutter_repair)
			# confirms this is flavor text closing out qst_sipho_gutter_repair ("Grandmother's Gutters (Ch. 3)") —
			# "Ends with Hope adding a stone catchment... as a small personal experiment."
			# Deliberately no start_quest() call. Flag to Ben: does this need its own
			# personal-project/flavor tracking, or should it just be dropped from objective routing?
			pass
		"Repair the gutter run, fit a lid to the drum, reposition the drum":
			start_quest("qst_sipho_gutter_repair")

		# ── CHAPTER 4 ──────────────────────────────
		"Collect upkeep-burden accounts from outpost volunteers":
			start_quest("qst_charity_outpost_upgrade_campaign")
		"Approach the sister-in-law at the trade fair before approaching the owner":
			start_quest("qst_dumi_mill_lead")
		"Work Hope's plot under Ezekiel's direction — zai pits, mulch, stone catchment":
			start_quest("qst_ezekiel_repay_hope")
		"Follow two leads — Dumi's contacts and Petrus's stash":
			start_quest("qst_lebo_mill_parts_main")
		"Help Lindi prioritise the glut — fastest to spoil vs. greatest household need":
			start_quest("qst_lindi_glut_triage")
		"Clear access to the tarpaulin at the back of Petrus's yard":
			start_quest("qst_petrus_mill_stash")
		"Help Sipho document the schoolhouse's current shortfall and frame the NGO ask with Charity":
			start_quest("qst_sipho_schoolhouse_case")

		# ── CHAPTER 5 ──────────────────────────────
		"Attend the discussion at the Gathering Tree":
			start_quest("qst_village_borehole_conversation_main")
		"Accompany Ezekiel on a circuit of households — carry tools, make introductions":
			start_quest("qst_ezekiel_rounds_main")
		"Deliver a full container of water to Gogo's homestead as part of Hope's regular rounds":
			start_quest("qst_gogo_quiet_watch")
		"Learn drying and smoke-curing under Lindi's guidance":
			start_quest("qst_lindi_smoke_and_dry")

		# ── CHAPTER 6 ──────────────────────────────
		"Walk the four survey sites with Gogo and Charity":
			start_quest("qst_hydrogeologist_survey_escort")
		"Join the storm-prep effort — embankments and raised pathways":
			start_quest("qst_mkhize_storm_prep")
		"Gather during the flight — processing infrastructure is already in place":
			start_quest("qst_lindi_kumbi_kumbi_two")

		# ── CHAPTER 7 ──────────────────────────────
		"Coordinate the contributions villagers have already prepared":
			start_quest("qst_charity_mill_campaign")
		"Gather and process the second mopane outbreak":
			start_quest("qst_lindi_mopane_efficient")
		"Assist Lebo and Sipho with the solar pump installation":
			start_quest("qst_watering_hole_solar_install")
		"Assist Sipho with household tank installations":
			start_quest("qst_sipho_tanks_rollout_main")

		# ── CHAPTER 8 ──────────────────────────────
		"Be at the borehole site as the work goes on":
			start_quest("qst_borehole_drilling_main")
		"Join the community build at Gogo's rock-outcrop site":
			start_quest("qst_gogo_rock_cistern")
		"Help Lindi set up her stall — organise the preserved goods, arrange the display":
			start_quest("qst_lindi_market_stall")
		"Help position and set up the solar mill at the market":
			start_quest("qst_naledi_solar_mill_placement")
		"Sit with the question — speak with Gogo and Naledi before deciding":
			start_quest("qst_naledi_this_is_home")
		"Help with the opening — borrow and arrange seating, decorate, spread word":
			start_quest("qst_zanele_schoolhouse_opening")

		# ── CHAPTER 9 ──────────────────────────────
		"Obtain the councillor's countersignature and retrieve the archived posting record":
			start_quest("qst_charity_one_last_petition")
		"Help gather the community and prepare the borehole site for the ceremony":
			start_quest("qst_gogo_borehole_blessing")
		"Help clear the pitch, arrange the fabric, and hang the sign":
			start_quest("qst_naledi_stall_reopening")
		"Help Sipho with his last preparations; be with Zanele on Thursday":
			start_quest("qst_zanele_sipho_farewell")
		_:
			push_warning("QuestObjectiveRouter: unrecognised objective text — %s" % text)

func start_quest(quest_id: String) -> void:
	if quest_id not in active_quests and quest_id not in completed_quests:
		active_quests.append(quest_id)
		print("Quest started: ", quest_id)

func complete_quest(quest_id: String) -> void:
	if quest_id in active_quests:
		active_quests.erase(quest_id)
		completed_quests.append(quest_id)
		print("Quest completed: ", quest_id)
