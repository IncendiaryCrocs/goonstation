/datum/potential_sacrifice_info
	var/mob/living/carbon/human/human
	var/human_name = "Somebody" // incase human becomes null, remember the name
	var/has_mind = FALSE
	var/base_points = 500
	var/ever_living = FALSE
	var/ever_awake = FALSE
	proc/calc_points()
		. = src.base_points
		if (!src.ever_living)
			. -= 300
		else if (!src.ever_awake)
			. -= 100
		return .

/datum/cult_obj_overhead/cult_sacrifice_zone
	var/list/datum/potential_sacrifice_info/tracking_sacrifices
	var/obj/decal/cultcircle/rune
	var/turf/centre_turf
	var/is_rune = FALSE
	var/tracking_range = 0

	proc/sacrifice_human(datum/potential_sacrifice_info/sacrifice)
		if (!can_sacrifice_human(sacrifice.human))
			return

		if (is_rune)
			rune.activate()

		if (sacrifice.has_mind == FALSE)
			owner.award_points(1, TRUE, "[sacrifice.human_name] was sacrificed, but doesn't have a consciousness strong enough to appease [owner.cult_name].")
		else
			var/points_awarded = sacrifice.calc_points()
			owner.award_points(points_awarded, TRUE, "[sacrifice.human_name] has been sacrificed for [points_awarded] points!")
		if (sacrifice.human)
			sacrifice.human.bioHolder.AddEffect("husk")
			sacrifice.human.bioHolder.mobAppearance.flavor_text = "A dessicated husk."
			sacrifice.human.disfigured = TRUE
			sacrifice.human.UpdateName()
		connected_obj.visible_message(SPAN_ALERT("[connected_obj] pulses and groans erratically, glowing with an evil aura!"))
		src.tracking_sacrifices.Remove(sacrifice)
		qdel(sacrifice)

	proc/can_sacrifice_human(mob/living/carbon/human/human, do_check_list)
		if (!human)
			return FALSE
		if (!ishuman(human)) // They've gotta be a human
			return FALSE
		if (human.get_ability_holder(/datum/abilityHolder/cult) != null) // Can't sacrifice your cultist friends
			return FALSE
		if (human.bioHolder.HasEffect("husk")) // They've already been juiced!
			return FALSE
		if (do_check_list == TRUE) // Check if they haven't already had info made on them (if you want to)
			for (var/datum/potential_sacrifice_info/sacrifice as anything in tracking_sacrifices)
				if (sacrifice.human == human)
					return FALSE
		return TRUE

	proc/check_is_player(mob/target)
		if (target.mind == null)
			return FALSE
		return target.mind.ckey != null

	proc/check_human(datum/potential_sacrifice_info/sacrifice)
		// Check if they have died
		if (!sacrifice.human) // They no longer exist (counts as a death)
			sacrifice_human(sacrifice)
			return

		if (isdead(sacrifice.human)) // They have died, sacrifice
			sacrifice_human(sacrifice)
			return
		else
			sacrifice.ever_living = TRUE

		if (get_dist(centre_turf, get_turf(sacrifice.human)) > 2) // They left the circle
			tracking_sacrifices.Remove(sacrifice)
			qdel(sacrifice)
			return

		if (sacrifice.human.sleeping == FALSE && sacrifice.human.incrit == FALSE)
			sacrifice.ever_awake = TRUE

	proc/update_range()
		src.tracking_range = round(max(connected_obj.bound_width, connected_obj.bound_height) / 64, 1)
		if (!is_rune) // If it's a sacrificial circle, don't give any extra.
			src.tracking_range += 3

	proc/process()
		if (is_rune)
			rune.deactivate()

		connected_obj.desc = "Tracking deaths in [tracking_range]"
		centre_turf = get_turf(connected_obj) // Object size will mean this might have to change (configured for circles)
		var/list/within_circle = range(src.tracking_range, centre_turf)
		// Find new humans that might turn up as cult meat soon
		for (var/mob/living/carbon/human/human in within_circle) // lack of as intentional
			if (src.can_sacrifice_human(human) == TRUE)
				var/datum/potential_sacrifice_info/new_sac = new()
				new_sac.human = human
				new_sac.human_name = human.name
				new_sac.has_mind = src.check_is_player(new_sac.human)
				src.tracking_sacrifices.Add(new_sac) // Add this potential sacrifice

		// Run through all potential sacs
		for (var/datum/potential_sacrifice_info/potential_sac as anything in src.tracking_sacrifices)
			src.check_human(potential_sac)

	New(obj/new_obj, datum/cult/new_cult)
		tracking_sacrifices = list()
		START_TRACKING // Tracked by processes
		..()
		is_rune = istype(new_obj, /obj/decal/cultcircle)
		if (is_rune)
			rune = new_obj
			rune.subscribe_to_cult(owner)
		src.update_range()
