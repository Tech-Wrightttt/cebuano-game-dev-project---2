shader_type spatial;
render_mode unshaded, fog_disabled, ambient_light_disabled, cull_disabled, depth_test_disabled, depth_draw_never;
stencil_mode read, 1, compare_equal;

uniform sampler2D screen_texture : hint_screen_texture;

// Dithering uniforms from your previous shader
uniform float brightness : hint_range(0.0, 3.0) = 1.5;
uniform float contrast : hint_range(0.0, 3.0) = 1.2;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.8;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.15;
uniform float grain_size : hint_range(1.0, 10.0) = 3.0;

// Highlight effect uniforms
uniform vec4 shine_color : source_color = vec4(1.0);
uniform float shine_speed : hint_range(0, 25) = 1.0;
uniform float shine_width : hint_range(0, 2) = 1.0;
uniform float cycle_interval : hint_range(0, 100) = 1.0;
uniform float angle_fade : hint_range(0, 1) = 1.0;

uniform float x_direction : hint_range(-1, 1) = 0.0;
uniform float y_direction : hint_range(-1, 1) = 0.0;
uniform float z_direction : hint_range(-1, 1) = 1.0;

// Bayer matrix for dithering
float bayer(vec2 p) {
    int x = int(mod(p.x, 4.0));
    int y = int(mod(p.y, 4.0));
    int index = x + y * 4;
    float[16] matrix = float[16](
        0.0/16.0, 8.0/16.0, 2.0/16.0, 10.0/16.0,
        12.0/16.0, 4.0/16.0, 14.0/16.0, 6.0/16.0,
        3.0/16.0, 11.0/16.0, 1.0/16.0, 9.0/16.0,
        15.0/16.0, 7.0/16.0, 13.0/16.0, 5.0/16.0
    );
    return matrix[index];
}

float noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

float animated_noise(vec2 uv, float time) {
    return noise(uv + time * 0.1) * noise(uv * 2.0 + time * 0.05);
}

float sawtooth(float x) {
    return 2.0 * ((x + shine_speed * TIME) / (shine_width + cycle_interval) - floor(0.5 + (x + shine_speed * TIME) / (shine_width + cycle_interval)));
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 screen_rgb = texture(screen_texture, uv).rgb;

	// Calculate luminance and apply brightness and contrast for dithering base
	float luminance = dot(screen_rgb, vec3(0.299, 0.587, 0.114));
	luminance = (luminance - 0.5) * contrast + 0.5;
	luminance *= brightness;

	// Add noise for grain
	float grain = animated_noise(uv * grain_size * 3.0, TIME);
	float fine_grain = noise(uv * grain_size * 12.0 + TIME * 2.0);
	luminance += ((grain - 0.5) * 0.6 + (fine_grain - 0.5) * 0.4) * noise_strength * 3.0;

	// Apply dithering threshold
	float threshold = bayer(FRAGCOORD.xy);
	float dithered = luminance > threshold ? 1.0 : 0.0;
	vec3 color = vec3(dithered);

	// Vignette effect
	vec2 center = uv - vec2(0.5);
	float vignette = 1.0 - dot(center, center) * vignette_strength;
	vignette = smoothstep(0.0, 1.0, vignette);
	color *= vignette;

	// Highlight effect calculation
	vec3 w_vertex = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float projection = dot(w_vertex, normalize(vec3(x_direction, y_direction, z_direction)));
	float frequency = ceil(sawtooth(projection) - sawtooth(projection + shine_width));
	float alpha = clamp((1.0 - dot(NORMAL, VIEW) * angle_fade) * frequency * shine_color.a, 0.0, 1.0);

	// Mix highlight color and dithering color based on highlight alpha
	vec3 final_color = mix(color, shine_color.rgb, alpha);

	ALBEDO = final_color;
	ALPHA = 1.0;
}
