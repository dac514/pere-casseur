extends Node

signal tier_unlocked(tier_number: int, tier_name: String)
signal tier_progress_updated(tier_number: int, progress: float)
signal stats_updated(info: String)

# Target time for idle play: 24 minutes = 1440 seconds
const IDLE_DURATION: float = 1440.0

# Total gifts to deliver (ie. world population)
const TOTAL_GIFTS: float = 8_200_000_000.0

# Number of tiers (including Tier 0)
const NUM_TIERS: int = 11

const TIER_NAMES: Array[String] = [
	"Solopreneur",
	"Amazon Fulfillment Deal",
	"Scab Post Express",
	"Oil Baron's Pact",
	"Plastic Wonderland",
	"Coal-Powered Christmas",
	"Fast Fashion Frenzy",
	"Military Logistics Contract",
	"Crypto Christmas",
	"SpaceX Sleigh Launch",
	"World Bank Bailout"
]

# Exponential growth factor (calibrated so idle play takes ~24 min)
const GROWTH_FACTOR: float = 0.013

# Delivery rate starts at 1/sec and scales exponentially over time
var base_delivery_rate: float = 1.0
var time_elapsed: float = 0.0

# Collectible multiplier (starts at 1.0)
var collectible_multiplier: float = 1.0

# Track collectibles
var fuel_collected: int = 0
var oil_collected: int = 0
var bribes_collected: int = 0
var mob_hits: int = 0

# Precomputed thresholds
var tier_gift_thresholds: Array[float] = []

# Current tier
var current_tier: int = 0

# Gifts counter, counting down from 8.2 billion
var gifts_counter: float = TOTAL_GIFTS


func _ready() -> void:
	_compute_tier_thresholds()
	# DEBUG: We can skip tiers by adjusting gifts_counter below:
	# gifts_counter = 25


func _process(delta: float) -> void:
	time_elapsed += delta

	# Exponentially increase base delivery rate over time
	base_delivery_rate = exp(GROWTH_FACTOR * time_elapsed)

	# Check for tier unlocks based on gifts delivered
	_check_tier_unlock()


func get_delivery_rate() -> float:
	return base_delivery_rate * collectible_multiplier


func collect_fuel(area: Fuel) -> void:
	fuel_collected += 1
	collectible_multiplier += 0.10  # +10% per fuel
	var stats := "+%s | %.2fx | %s/sec" % [tr("Fuel"), collectible_multiplier, _format_rate(get_delivery_rate())]
	stats_updated.emit(stats)
	area.release(fuel_collected)


func collect_oil(area: Oil) -> void:
	oil_collected += 1
	collectible_multiplier += 0.25  # +25% per oil
	var stats := "+%s | %.2fx | %s/sec" % [tr("Oil"), collectible_multiplier, _format_rate(get_delivery_rate())]
	stats_updated.emit(stats)
	area.release(oil_collected)


func collect_bribe(area: Bribe) -> void:
	bribes_collected += 1
	collectible_multiplier += 0.50  # +50% per bribe
	var stats := "+%s | %.2fx | %s/sec" % [tr("Bribe"), collectible_multiplier, _format_rate(get_delivery_rate())]
	stats_updated.emit(stats)
	area.release(bribes_collected)


func mob_hit() -> void:
	mob_hits += 1
	if collectible_multiplier >= 1.05:
		collectible_multiplier -= 0.05  # -5% per mob hit
	var stats := "-%s | %.2fx | %s/sec" % [tr("Elf"), collectible_multiplier, _format_rate(get_delivery_rate())]
	stats_updated.emit(stats)


func _check_tier_unlock() -> void:
	var total_gifts_delivered := TOTAL_GIFTS - gifts_counter

	var old_tier := current_tier

	# Check which tier we're in based on gifts delivered
	for i in range(NUM_TIERS - 1, -1, -1):
		if total_gifts_delivered >= tier_gift_thresholds[i]:
			current_tier = i
			break

	# Emit tier unlock signal when tier changes
	if current_tier > old_tier:
		tier_unlocked.emit(current_tier, TIER_NAMES[current_tier])
		collectible_multiplier += (current_tier * 10)

	# Always emit progress update (even if tier hasn't changed)
	var progress := get_progress_to_next_tier()
	tier_progress_updated.emit(current_tier, progress * 100.0)


func get_progress_to_next_tier() -> float:
	var total_gifts_delivered := TOTAL_GIFTS - gifts_counter

	if current_tier >= tier_gift_thresholds.size() - 1:
		return 1.0  # Max tier reached

	var current_threshold := tier_gift_thresholds[current_tier]
	var next_threshold := tier_gift_thresholds[current_tier + 1]

	return (total_gifts_delivered - current_threshold) / (next_threshold - current_threshold)


# Delivery rate, Gifts per second
func _format_rate(rate: float) -> String:
	if rate >= 1_000_000:
		return "%.1fM" % (rate / 1_000_000.0)

	if rate >= 1_000:
		return "%.1fK" % (rate / 1_000.0)

	return "%.0f" % rate


func _compute_tier_thresholds() -> void:
	tier_gift_thresholds.clear()

	# Each tier should represent an equal slice of time in idle play
	for i in range(NUM_TIERS):
		var t := (IDLE_DURATION / (NUM_TIERS - 1)) * i
		var delivered := (exp(GROWTH_FACTOR * t) - 1.0) / GROWTH_FACTOR
		var scaled := delivered / ((exp(GROWTH_FACTOR * IDLE_DURATION) - 1.0) / GROWTH_FACTOR) * TOTAL_GIFTS
		tier_gift_thresholds.append(scaled)

	# Adjust the last threshold to be ~TOTAL_GIFTS
	tier_gift_thresholds[-1] = TOTAL_GIFTS - 1.4
