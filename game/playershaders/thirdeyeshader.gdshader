shader_type canvas_item;

uniform float brightness : hint_range(0.0, 3.0) = 1.5;
uniform float contrast : hint_range(0.0, 3.0) = 1.2;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.8;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.15;
uniform float grain_size : hint_range(1.0, 10.0) = 3.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

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

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 screen_color = texture(SCREEN_TEXTURE, uv);

    // Calculate luminance and apply brightness and contrast
    float luminance = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
    luminance = (luminance - 0.5) * contrast + 0.5;
    luminance *= brightness;

    // Grainy noise with two layers for detail
    float grain = animated_noise(uv * grain_size * 3.0, TIME);
    float fine_grain = noise(uv * grain_size * 12.0 + TIME * 2.0);

    // Combine grain with noise strength (boosted for visibility)
    luminance += ((grain - 0.5) * 0.6 + (fine_grain - 0.5) * 0.4) * noise_strength * 3.0;

    // Apply Bayer dithering threshold
    float threshold = bayer(FRAGCOORD.xy);
    float dithered = luminance > threshold ? 1.0 : 0.0;

    vec3 color = vec3(dithered);

    // Vignette effect for visual focus
    vec2 center = uv - vec2(0.5);
    float vignette = 1.0 - dot(center, center) * vignette_strength;
    vignette = smoothstep(0.0, 1.0, vignette);
    color *= vignette;

    COLOR = vec4(color, 1.0);
}
