#define CULT_MAX_MEMBERS 7

/// Amount of points the cult starts with
#define CULT_STARTING_POINTS 500
#define CULT_SACRIFICE_CHECK_FREQUENCY 2 SECONDS

/// What can the obsession be?
#define CULT_PERMITTED_OBSESSION_TYPES list(/obj/item, /mob/living/carbon/human, /mob/living/carbon/critter)
/// What CAN'T the obsession be (above happens first tho)
#define CULT_BANNED_OBSESSION_TYPES list()
/// What the cult obsession can be, but makes it not work. Basically deepfries it
#define CULT_FRY_OBSESSION_TYPES list(/obj/item/currency)
