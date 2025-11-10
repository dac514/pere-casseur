// Rain and Snow shader by Brian Smith (steampunkdemon.itch.io)
// MIT licence

shader_type canvas_item;

uniform float rain_amount = 200.0;
uniform float near_rain_length : hint_range(0.01, 1.0) = 0.2;
uniform float far_rain_length : hint_range(0.01, 1.0) = 0.1;
uniform float near_rain_width : hint_range(0.1, 1.0) = 1.0;
uniform float far_rain_width : hint_range(0.1, 1.0) = 0.5;
uniform float near_rain_transparency : hint_range(0.1, 1.0) = 1.0;
uniform float far_rain_transparency : hint_range(0.1, 1.0) = 0.5;
uniform vec4 rain_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float base_rain_speed : hint_range(0.1, 1.0) = 0.5;
uniform float additional_rain_speed : hint_range(0.1, 1.0) = 0.5;
uniform float slant : hint_range(-1.0, 1.0) = 0.2;

void fragment() {
	// Precompute time offset
	float time = 10000.0 + TIME;

	// Precompute constants used multiple times
	float inv_rain_amount = 1.0 / rain_amount;
	float slanted_uv = UV.x - UV.y * slant;

	// Calculate rain column position
	float remainder = mod(slanted_uv, inv_rain_amount);
	float uv_x = slanted_uv - remainder;

	// Random value per rain column
	float rn = fract(sin(uv_x * rain_amount));

	// Calculate vertical position with random offset
	float uv_y = fract(UV.y + rn);

	// Precompute interpolation ranges (reduces redundant math)
	float length_range = near_rain_length - far_rain_length;
	float width_range = near_rain_width - far_rain_width;
	float transparency_range = near_rain_transparency - far_rain_transparency;

	// Calculate rain drop visibility
	float animated_y = fract(uv_y - time * (base_rain_speed + additional_rain_speed * rn));
	float length_threshold = 1.0 - (far_rain_length + length_range * rn);
	float vertical_mask = step(length_threshold, animated_y);

	// Calculate rain drop width
	float width_threshold = far_rain_width + width_range * rn;
	float horizontal_mask = step(remainder * rain_amount, width_threshold);

	// Calculate transparency
	float alpha = (far_rain_transparency + transparency_range * rn) * vertical_mask * horizontal_mask;

	// Final color blend
	COLOR = mix(COLOR, rain_color, alpha);
}