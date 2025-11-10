shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 10.0) = 1.5;

void fragment() {
    // This function grabs a pre-blurred version of the screen texture
    // based on the "level of detail" (LOD), which we control with blur_amount.
    vec3 result = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount).rgb;
    
    // We only set the .rgb (color) and leave the .a (alpha) alone.
    COLOR.rgb = result;
}