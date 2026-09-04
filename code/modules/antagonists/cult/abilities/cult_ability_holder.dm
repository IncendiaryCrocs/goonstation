/atom/movable/screen/ability/topBar/cult
	clicked(params)
		var/datum/targetable/cult/spell = owner
		var/datum/abilityHolder/holder = owner.holder

		if (!istype(spell))
			return
		if (!spell.holder)
			return

		if(params["shift"] && params["ctrl"])
			if(owner.waiting_for_hotkey)
				holder.cancel_action_binding()
				return
			else
				owner.waiting_for_hotkey = 1
				src.UpdateIcon()
				boutput(usr, SPAN_NOTICE("Please press a number to bind this ability to..."))
				return

		if (!isturf(owner.holder.owner.loc))
			boutput(owner.holder.owner, SPAN_ALERT("You can't use this spell here."))
			return
		if (spell.targeted && usr.targeting_ability == owner)
			usr.targeting_ability = null
			usr.update_cursor()
			return
		if (spell.targeted)
			if (world.time < spell.last_cast)
				return
			owner.holder.owner.targeting_ability = owner
			owner.holder.owner.update_cursor()
		else
			SPAWN(0)
				spell.handleCast()
		return

/* 	/		/		/		/		/		/		Ability Holder		/		/		/		/		/		/		/		/		*/

/datum/abilityHolder/cult
	usesPoints = 0
	regenRate = 0
	tabName = "cult"
	// notEnoughPointsMessage = SPAN_ALERT("You need more blood to use this ability.")
	points = 0
	pointName = "points"
	var/stealthed = 0
	var/const/MAX_POINTS = 100

	New()
		..()


	disposing()
		..()

	onLife(var/mult = 1)
		if(..()) return

/datum/targetable/cult
	icon = 'icons/mob/cult_ui.dmi' //placeholder
	icon_state = "default" //placeholder
	cooldown = 0
	last_cast = 0
	pointCost = 0
	preferred_holder_type = /datum/abilityHolder/cult
	var/when_stunned = 0 // 0: Never | 1: Ignore mob.stunned and mob.weakened | 2: Ignore all incapacitation vars
	var/not_when_handcuffed = 0
	var/unlock_message = null
	var/can_cast_anytime = 0		//while alive

	New()
		var/atom/movable/screen/ability/topBar/cult/B = new /atom/movable/screen/ability/topBar/cult(null)
		B.icon = src.icon
		B.icon_state = src.icon_state
		B.owner = src
		B.name = src.name
		B.desc = src.desc
		src.object = B
		return

	onAttach(var/datum/abilityHolder/H)
		..()
		if (src.unlock_message && src.holder && src.holder.owner)
			boutput(src.holder.owner, SPAN_NOTICE("<h3>[src.unlock_message]</h3>"))
		return

	updateObject()
		..()
		if (!src.object)
			src.object = new /atom/movable/screen/ability/topBar/cult()
			object.icon = src.icon
			object.owner = src
		if (src.last_cast > world.time)
			var/pttxt = ""
			if (pointCost)
				pttxt = " \[[pointCost]\]"
			object.name = "[src.name][pttxt] ([round((src.last_cast-world.time)/10)])"
			object.icon_state = src.icon_state + "_cd"
		else
			var/pttxt = ""
			if (pointCost)
				pttxt = " \[[pointCost]\]"
			object.name = "[src.name][pttxt]"
			object.icon_state = src.icon_state
		return

	castcheck()
		if (!holder)
			return 0

		var/mob/living/M = holder.owner

		if (!M)
			return 0

		if (!(iscarbon(M) || ismobcritter(M)))
			boutput(M, SPAN_ALERT("You cannot use any powers in your current form."))
			return 0

		if (can_cast_anytime && !isdead(M))
			return 1
		if (!can_act(M, 0))
			boutput(M, SPAN_ALERT("You can't use this ability while incapacitated!"))
			return 0

		if (src.not_when_handcuffed && M.restrained())
			boutput(M, SPAN_ALERT("You can't use this ability when restrained!"))
			return 0

		return 1

	cast(atom/target)
		. = ..()
		actions.interrupt(holder.owner, INTERRUPT_ACT)
		return

/// Creates a cult rune. Decorative, if not part of a cult, otherwise subscribes it to sacrifice checking.
/datum/targetable/cult/create_circle
	name = "Create rune"
	desc = "Draw a dastardly rune with your own blood!"
	icon_state = "circle"
	do_logs = FALSE
	interrupt_action_bars = FALSE
	cooldown = 10

	cast()
		..()
		// Create decorative circle
		if (!holder)
			return 1
		var/mob/living/carbon/human/M = holder.owner
		if (!M)
			return 1
		var/obj/decal/cultcircle/circle = new()
		var/datum/cult/cult = null
		var/turf/placement = get_turf(M) // It's a 3x3, but offset handled by circle
		circle.set_loc(placement)
		boutput(M, SPAN_ALERT("You slice your arm and draw a terrible, malevolent rune!"))
		take_bleeding_damage(M, null, 20, D_SLASHING)

		// If we have a cult
		if (iscultist(M))
			if (iscultleader(M))
				var/datum/antagonist/cult_leader/antagonist_role = M.mind.get_antagonist(ROLE_CULT_LEADER)
				cult = antagonist_role.cult
			else
				var/datum/antagonist/subordinate/cult_member/antagonist_role = M.mind.get_antagonist(ROLE_CULT_MEMBER)
				cult = antagonist_role.cult

			var/datum/cult_obj_overhead/cult_sacrifice_zone/new_sac_zone = new(circle, cult)
			boutput(M, "All hail " + SPAN_ALERT(cult.cult_name) + "!")
		holder.removeAbility(/datum/targetable/cult/create_circle)

/datum/targetable/cult/summon_robe
	name = "Summon robe"
	desc = "Summons your robe."
	icon_state = "cloak"
	do_logs = FALSE
	interrupt_action_bars = FALSE
	var/obj/item/clothing/suit/antagcult/ability_cloak

	cast(mob/target)
		..()
		if (!holder)
			return 1

		var/mob/living/carbon/human/M = holder.owner

		if (!M)
			return 1

		if (!istype(M))
			return 1

		if (!ishuman(M))
			boutput(M, SPAN_ALERT("You can't equip a cloak if you're not a humanoid, doofus!"))
			return 1

		if (M.getStatusDuration("stunned") > 0 || M.getStatusDuration("knockdown") || M.getStatusDuration("unconscious") > 0 || !isalive(M) || M.restrained())
			boutput(M, SPAN_ALERT("Not when you're incapacitated or restrained."))
			return 1

		if (QDELETED(src.ability_cloak)) // If no cloak exists, create a new one
			ability_cloak = new()
			ability_cloak.is_summon = TRUE

		var/obj/in_uniform = M.get_slot(SLOT_WEAR_SUIT)
		if (in_uniform == ability_cloak) // The cloak is equipped, so unequip it.
			M.drop_from_slot(in_uniform, null, TRUE)
			in_uniform.set_loc(null) // This happens here and in suit/antagcult (just to be safe, technically not needed here...)
			boutput(M, SPAN_ALERT("Your robes vanish."))
		else // Cloak not equipped, so swap it out.
			//M.autoequip_slot(ability_cloak, SLOT_WEAR_SUIT)
			//boutput(M, SPAN_ALERT("You cloak yourself, use the ability again or take off the cloak to remove it."))
			SETUP_GENERIC_ACTIONBAR(M, M, 0.3 SECONDS, /datum/targetable/cult/summon_robe/proc/completed_cloaking, list(M, ability_cloak), src.icon, src.icon_state, null, null)

	proc/completed_cloaking(var/mob/living/carbon/human/M, var/obj/item/clothing/suit/antagcult/ability_cloak)
		if (!M)
			return 1
		M.autoequip_slot(ability_cloak, SLOT_WEAR_SUIT)
		boutput(M, SPAN_ALERT("You cloak yourself, use the ability again or take off the cloak to remove it."))

