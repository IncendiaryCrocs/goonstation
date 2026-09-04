/datum/controller/process/check_sacrifices
	setup()
		name = "Cult_Circle_Sacrifice_Check"
		schedule_interval = CULT_SACRIFICE_CHECK_FREQUENCY

	doWork()
		for_by_tcl(circle, /datum/cult_obj_overhead/cult_sacrifice_zone)
			circle.process()

