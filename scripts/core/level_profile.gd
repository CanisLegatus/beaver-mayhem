class_name LevelProfile
extends RefCounted
static func for_level(level: int) -> Dictionary:
	var weather := ["temperate","storm","rain","snow","blizzard","fog","rain","snow","storm","blizzard"][clampi(level-1,0,9)] as String
	return {"weather":weather,"night":level == 2 or level == 9,"zombies":level == 2,
		"wet":weather in ["rain","storm"],"snow":weather in ["snow","blizzard"],
		"name":"MOONFALL" if level == 2 else ("FOREST RECKONING" if level == 1 else "WILDERNESS %02d" % level)}
