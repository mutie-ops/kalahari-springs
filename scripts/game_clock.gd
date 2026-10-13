extends Node
## GameClock — the village clock. hour runs 0.0 to 24.0 (14.5 = 2:30 pm).
## level.gd drives it from the DayTimer. Everything else just reads it.

signal hour_changed(hour: float)    # fires every 10 in-game minutes

var debug_offset: float = 0.0       # nudged by the [ and ] test keys; reset every morning

var hour: float = 9.0:
	set(value):
		hour = fposmod(value, 24.0)
		var tick := floori(hour * 6.0)          # 6 ticks per hour = 10-minute steps
		if tick != _last_tick:
			_last_tick = tick
			hour_changed.emit(float(tick) / 6.0)

var _last_tick: int = 54                        # 9.0 * 6


func is_between(open_hour: float, close_hour: float) -> bool:
	return hour >= open_hour and hour < close_hour


func format_time(h: float) -> String:
	var total_minutes := int(round(h * 60.0)) % (24 * 60)
	var hh := floori(total_minutes / 60.0)
	var mm := total_minutes % 60
	var suffix := "a.m." if hh < 12 else "p.m."
	var h12 := hh % 12
	if h12 == 0:
		h12 = 12
	if mm == 0:
		return "%d %s" % [h12, suffix]
	return "%d:%02d %s" % [h12, mm, suffix]
