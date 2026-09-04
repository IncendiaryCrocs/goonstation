/datum/game_mode/cult
	name = "Cult"
	config_tag = "cult"
	regular = FALSE

	var/list/datum/cult/cults = list()

	var/const/setup_min_teams = 1
#ifdef RP_MODE
	var/const/setup_max_teams = 2
#else
	var/const/setup_max_teams = 3
#endif
	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)

	var/minimum_players = 15 // Minimum ready players for the mode

	var/slow_process = 0			//number of ticks to skip the extra cult process loops
	var/shuttle_called = FALSE

/datum/game_mode/cult/announce()
	boutput(world, "<B>The current game mode is - Cult!</B>")
	boutput(world, "<B>A number of cults are competing for control of the station!</B>")
	boutput(world, "<B>Cult members are antagonists and can kill or be killed!</B>")

#ifdef RP_MODE
#define PLAYERS_PER_CULT_GENERATED 15
#else
#define PLAYERS_PER_CULT_GENERATED 12
#endif
/datum/game_mode/cult/pre_setup()
	var/num_players = src.roundstart_player_count()

#ifndef ME_AND_MY_40_ALT_ACCOUNTS
	if (num_players < minimum_players)
		message_admins("<b>ERROR: Minimum player count of [minimum_players] required for Cult game mode, aborting cult round pre-setup.</b>")
		logTheThing(LOG_GAMEMODE, src, "Failed to start cult mode. [num_players] players were ready but a minimum of [minimum_players] players is required. ")
		return 0
#endif

	var/num_teams = clamp(round((num_players) / PLAYERS_PER_CULT_GENERATED), setup_min_teams, setup_max_teams) //1 cult per 9 players, 15 on RP
	logTheThing(LOG_GAMEMODE, src, "Counted [num_players] available, with [PLAYERS_PER_CULT_GENERATED] per cult that means [num_teams] cults.")

	var/list/leaders_possible = get_possible_enemies(ROLE_CULT_LEADER, num_teams)
	if (num_teams > length(leaders_possible))
		logTheThing(LOG_GAMEMODE, src, "Reducing number of cult from [num_teams] to [length(leaders_possible)] due to lack of available cult leaders.")
		num_teams = length(leaders_possible)

	if (!length(leaders_possible))
		return 0

	var/list/chosen_leader = antagWeighter.choose(pool = leaders_possible, role = ROLE_CULT_LEADER, amount = num_teams, recordChosen = 1)
	src.traitors |= chosen_leader

#ifndef ME_AND_MY_40_ALT_ACCOUNTS
	// check if we can actually run the mode before assigning special roles to minds
	if(length(get_possible_enemies(ROLE_CULT_MEMBER, round(num_teams * 4), force_fill = FALSE) - src.traitors) < round(num_teams * 4 * 0.66)) //must have at least 2/3 full cults or there's no point
		//boutput(world, SPAN_ALERT("<b>ERROR: The readied players are not collectively cultist enough for the selected mode, aborting cult.</b>"))
		return 0
#endif

	for (var/datum/mind/leader in src.traitors)
		leaders_possible.Remove(leader)
		leader.special_role = ROLE_CULT_LEADER

	return 1
#undef PLAYERS_PER_CULT_GENERATED

/datum/game_mode/cult/post_setup()
	for(var/datum/mind/antag_mind in src.traitors)
		if(antag_mind.special_role == ROLE_CULT_LEADER)
			antag_mind.add_antagonist(ROLE_CULT_LEADER, silent=TRUE)

	fill_cults()

	// we delay announcement to make sure everyone gets information about the other members
	for(var/datum/mind/antag_mind in src.traitors)
		antag_mind.get_antagonist(ROLE_CULT_LEADER)?.unsilence()
		antag_mind.get_antagonist(ROLE_CULT_MEMBER)?.unsilence()

	SPAWN(rand(waittime_l, waittime_h))
		send_intercept()

	return 1

/datum/game_mode/cult/proc/fill_cults(list/datum/mind/candidates = null, max_member_count = INFINITY)
	logTheThing(LOG_GAMEMODE, src, "begins using random crew members to fill cult roster.")
	var/num_teams = length(src.cults)
	var/num_people_needed = 0
	if(num_teams == 0)
		logTheThing(LOG_DEBUG, null, "Cult gamemode attempted to fill cults, but there were no cults to fill.")
		message_admins("It's cults, but there are no cults??")
		return
	for(var/datum/cult/cult in src.cults)
		num_people_needed += min(cult.current_max_cult_members, max_member_count) - length(cult.members)
	if(isnull(candidates))
		candidates = get_possible_enemies(ROLE_CULT_MEMBER, num_people_needed, allow_carbon=TRUE, force_fill = FALSE)
	var/num_people_available = min(num_people_needed, length(candidates))
	var/people_added_per_cult = round(num_people_available / num_teams)
	logTheThing(LOG_GAMEMODE, src, "assigning [people_added_per_cult] members each to [length(src.cults)] cults from a pool of [num_people_available] crew members.")
	num_people_available = people_added_per_cult * num_teams
	shuffle_list(candidates)
	var/i = 1
	var/cult_count = 0
	for(var/datum/cult/cult in src.cults)
		cult_count++
		for(var/j in 1 to people_added_per_cult)
			var/datum/mind/candidate = candidates[i++]
			logTheThing(LOG_GAMEMODE, src, "assigned [candidate.ckey] to cult #[cult_count]")
			candidate.add_subordinate_antagonist(ROLE_CULT_MEMBER, master = cult.leader, silent=TRUE)
			traitors |= candidate

/datum/game_mode/cult/send_intercept()
	..(src.traitors)


/datum/game_mode/cult/process()
	..()
	slow_process ++
	if (slow_process < 5)
		return
	else
		slow_process = 0

/datum/cult
	/// The maximum number of cult members per cult.
	var/static/current_max_cult_members = 4
	//Default color?
	var/static/list/color ="#FFFFFF"
	var/static/list/color_list = list("#88CCEE","#117733","#332288","#DDCC77","#CC6677","#AA4499") //(hopefully) colorblind friendly palette
	var/static/list/colors_left = null
	/// The chosen name of this cult.
	var/cult_name = "Cult Name"
	/// The "style" of the cult, which will (one day) effect cult circles and their respective robes
	var/style = "default"
	/// Obsession
	var/datum/cult_obj_overhead/obsession = null
	/// Points
	var/points = CULT_STARTING_POINTS

	/// The ID of the color selected
	var/color_id = 0
	/// The mind of this cult's leader.
	var/datum/mind/leader = null
	/// The minds of cult members associated with this cult. Does not include the cult leader.
	var/list/datum/mind/members = list()


	proc/living_member_count()
		var/result = 0
		for (var/datum/mind/member as anything in members)
			if (!isdead(member.current))
				result++
		return result

	proc/choose_new_leader()
		var/datum/mind/smelly_unfortunate
		for (var/datum/mind/member in members)
			if (isliving(member.current))
				var/mob/living/carbon/candidate = member.current
				if (!candidate.hibernating)
					smelly_unfortunate = member
		if (!smelly_unfortunate)
			logTheThing(LOG_ADMIN, leader.ckey, "The leader of [cult_name] cryo'd/died early with no living members to take the role.")
			message_admins("The leader of [cult_name], [leader.ckey] cryo'd/died early with no living members to take the role.")
			return

		var/datum/mind/bad_leader = leader
		var/datum/antagonist/leaderRole = leader.get_antagonist(ROLE_CULT_LEADER)
		var/datum/antagonist/oldRole = smelly_unfortunate.get_antagonist(ROLE_CULT_MEMBER)
		smelly_unfortunate.current.remove_ability_holder(/datum/abilityHolder/cult)
		oldRole.silent = TRUE // so they dont get a spooky 'you are no longer a cult member' popup!
		smelly_unfortunate.remove_antagonist(ROLE_CULT_MEMBER,ANTAGONIST_REMOVAL_SOURCE_OVERRIDE,FALSE)
		leaderRole.transfer_to(smelly_unfortunate, FALSE, ANTAGONIST_REMOVAL_SOURCE_EXPIRED)
		bad_leader.add_subordinate_antagonist(ROLE_CULT_MEMBER, master = smelly_unfortunate)

	proc/get_dead_memberlist()
		var/list/result = list()
		for (var/datum/mind/member as anything in members)
			if (istype(member.current.loc, /obj/cryotron))
				var/obj/cryotron/cryo = member.current.loc
				var/cryoTime = cryo.stored_mobs[member.current]
				if (TIME - cryoTime > (1 MINUTE))
					result[(member.current?.real_name)] = member
				continue
			if (isdead(member.current))
				result[(member.current?.real_name)] = member
		return result

	proc/select_cult_name() // Not finished & Not Working!
		// add the cult to their displayed name for antag and round end stuff. works hopefully??
		var/datum/antagonist/leader_antag = src.leader.get_antagonist(ROLE_CULT_LEADER)
		leader_antag.display_name = "[src.cult_name] [leader_antag.display_name]"
		return

	proc/announce(text)
		boutput(src.leader.current, SPAN_CULTSAY(text))
		for (var/datum/mind/culter as anything in src.members)
			boutput(culter.current, SPAN_CULTSAY(text))

	proc/award_points(amount, do_announce, text)
		src.points += amount
		if (do_announce == TRUE)
			if (text == null)
				text = "[src.cult_name] has been awarded [amount] points!"
			text += SPAN_ITALIC(" There are now [points] points to spend.")
		src.announce(text)

	New()
		. = ..()
		if (colors_left == null)
			colors_left = new/list(length(color_list))
			for (var/color = 1 to length(color_list))
				colors_left[color] = color

		color_id = pick(colors_left)
		colors_left -= color_id
		color = color_list[color_id]

		if (istype(ticker?.mode, /datum/game_mode/cult))
			var/datum/game_mode/cult/gamemode = ticker.mode
			gamemode.cults += src

		for (var/datum/mind/culter in src.members)
			var/datum/antagonist/antag = culter.get_antagonist(ROLE_CULT_MEMBER)
			antag.display_name = "[src.cult_name] [antag.display_name]"

	disposing()
		..()

/// Important Cult objects that "float" over objects like sacrificial circles and obsessions
/datum/cult_obj_overhead
	var/obj/connected_obj
	var/datum/cult/owner

	New(obj/new_obj, datum/cult/new_cult)
		. = ..()
		START_TRACKING
		owner = new_cult
		connected_obj = new_obj

	disposing()
		..()
		STOP_TRACKING
