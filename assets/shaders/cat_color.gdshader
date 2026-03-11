shader_type canvas_item;

// Base color multiplied over non-outline pixels (white = no tint, like default modulate)
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Replacement color for outline pixels
uniform vec4 outline_color : source_color = vec4(0.169, 0.133, 0.165, 1.0); // #2B222A

// Original outline pixel colour in the sprite sheet (#2B222A)
const vec3 OUTLINE_SOURCE = vec3(0.169, 0.133, 0.165);
// Tight threshold — pixel art uses exact colours, so 0.05 avoids false positives
const float OUTLINE_THRESHOLD = 0.05;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.01) {
		COLOR = vec4(0.0);
	} else {
		float dist = length(tex.rgb - OUTLINE_SOURCE);
		if (dist < OUTLINE_THRESHOLD) {
			// Outline pixel: replace with chosen outline colour, preserve sprite alpha
			COLOR = vec4(outline_color.rgb, tex.a * outline_color.a);
		} else {
			// Non-outline pixel: multiply tint (same as modulate)
			COLOR = tex * base_color;
		}
	}
}
