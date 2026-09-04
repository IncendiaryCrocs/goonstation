/datum/cult_obj_overhead/obsession
	var/datum/cult_obj_overhead/cult_sacrifice_zone/sac_zone
	New(obj/new_obj, datum/cult/new_cult)
		..()
		src.sac_zone = new(new_obj, new_cult)
		owner.obsession = src
		owner.announce("Your cult leader has picked [new_obj] to be your item of worship!")

