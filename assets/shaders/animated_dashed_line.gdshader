shader_type canvas_item;

// Shader for animated dashed lines with moving dots
// The dashes travel along the line from start to end

uniform float time_scale : hint_range(0.1, 5.0) = 1.0;
uniform float dash_length : hint_range(2.0, 20.0) = 8.0;
uniform float gap_length : hint_range(2.0, 20.0) = 8.0;

void fragment() {
	// Get the distance along the line using the built-in LINE distance
	// In Godot 4, we can use UV.y to determine distance from the line
	float dist_from_line = abs(UV.y - 0.5) * 2.0; // Distance in normalized space

	// Only draw if close to the line center
	if (dist_from_line > 0.1) {
		COLOR.a = 0.0;
		return;
	}

	// Animate the pattern along the line using UV.x (distance along line)
	float pattern_pos = UV.x - TIME * time_scale;
	float dash_cycle = mod(pattern_pos, dash_length + gap_length);

	// Draw dash if within dash_length, otherwise it's a gap
	if (dash_cycle < dash_length) {
		COLOR = vec4(1.0, 1.0, 1.0, 0.5);
	} else {
		COLOR.a = 0.0;
	}
}
