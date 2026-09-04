/datum/antagonist/cult_leader
	id = ROLE_CULT_LEADER
	display_name = "cult leader"
	antagonist_icon = "cult_head"
	wiki_link = "https://wiki.ss13.co/Cult"

	/// The cult that this cult leader belongs to.
	var/datum/cult/cult
	/// The ability holder of this cult leader, containing their respective abilities.
	var/datum/abilityHolder/cult/ability_holder

	New(datum/mind/new_owner)
		src.cult = new /datum/cult
		src.cult.leader = new_owner
		antagonist_icon = "cult_head_[cult.color_id]"

		. = ..()

	disposing()
		src.cult.leader = null
		. = ..()

	is_compatible_with(datum/mind/mind)
		return ishuman(mind.current)

	give_equipment()
		if (!ishuman(src.owner.current))
			return FALSE

		var/datum/abilityHolder/cult/A = src.owner.current.get_ability_holder(/datum/abilityHolder/cult)
		if (!A)
			src.ability_holder = src.owner.current.add_ability_holder(/datum/abilityHolder/cult)
		else
			src.ability_holder = A

		src.ability_holder.addAbility(/datum/targetable/cult/summon_robe)
		src.ability_holder.addAbility(/datum/targetable/cult/create_circle)
		src.ability_holder.addAbility(/datum/targetable/cult/choose_obsession)

		var/mob/living/carbon/human/H = src.owner.current
		// Add secret cult channel
		src.owner.current.ensure_speech_tree().AddSpeechOutput(SPEECH_OUTPUT_CULTCHAT_CULTLEADER) // Add a subchannel when the cult datum is implemented
		src.owner.current.ensure_listen_tree().AddListenInput(LISTEN_INPUT_CULTCHAT) // Add a subchannel when the cult datum is implemented

	remove_equipment()
		src.ability_holder.removeAbility(/datum/targetable/cult/summon_robe)
		src.owner.current.remove_ability_holder(/datum/abilityHolder/cult)
		// Remove secret cult channel
		src.owner.current.ensure_speech_tree().RemoveSpeechOutput(SPEECH_OUTPUT_CULTCHAT_CULTLEADER) // Add a subchannel when the cult datum is implemented
		src.owner.current.ensure_listen_tree().RemoveListenInput(LISTEN_INPUT_CULTCHAT) // Add a subchannel when the cult datum is implemented

	transfer_to(datum/mind/target, take_gear, source, silent = FALSE)
		var/datum/abilityHolder/cult/ability_source = src.owner.current.get_ability_holder(/datum/abilityHolder/cult)
		var/datum/mind/old_owner = owner
		..()
		cult.leader = target
		var/datum/abilityHolder/cult/ability_target = target.current.get_ability_holder(/datum/abilityHolder/cult)
		target.current.remove_ability_holder(ability_target)
		target.current.add_existing_ability_holder(ability_source)
		old_owner.current.remove_ability_holder(/datum/abilityHolder/cult)




