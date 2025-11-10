shader_type spatial;
render_mode unshaded, fog_disabled, ambient_light_disabled, cull_disabled, depth_test_disabled, depth_draw_never;
stencil_mode read, 2, compare_not_equal;

uniform sampler2D screen_texture : hint_screen_texture;

// Dithering parameters similar to canvas_item shader
uniform float brightness : hint_range(0.0, 3.0) = 1.5;
uniform float contrast : hint_range(0.0, 3.0) = 1.2;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.8;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.15;
uniform float grain_size : hint_range(1.0, 10.0) = 3.0;

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

void vertex() {
    // Use default vertex positioning or adapt as needed
    POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 screen_color = texture(screen_texture, uv);

    // Calculate luminance and apply brightness and contrast
    float luminance = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
    luminance = (luminance - 0.5) * contrast + 0.5;
    luminance *= brightness;

    // Grainy noise with two layers
    float grain = animated_noise(uv * grain_size * 3.0, TIME);
    float fine_grain = noise(uv * grain_size * 12.0 + TIME * 2.0);
    luminance += ((grain - 0.5) * 0.6 + (fine_grain - 0.5) * 0.4) * noise_strength * 3.0;

    // Bayer dithering threshold
    float threshold = bayer(FRAGCOORD.xy);
    float dithered = luminance > threshold ? 1.0 : 0.0;

    vec3 color = vec3(dithered);

    // Vignette effect
    vec2 center = uv - vec2(0.5);
    float vignette = 1.0 - dot(center, center) * vignette_strength;
    vignette = smoothstep(0.0, 1.0, vignette);
    color *= vignette;

    ALBEDO = color;
}
