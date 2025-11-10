shader_type spatial;
render_mode unshaded,fog_disabled,ambient_light_disabled,cull_disabled,depth_test_disabled,depth_draw_never;
stencil_mode read, 1, compare_equal;
uniform sampler2D screen_texture: hint_screen_texture;

void vertex() {
	// Called for every vertex the material is visible on.
	POSITION = vec4(VERTEX,1.0);

}

void fragment() {
	// Called for every pixel the material is visible on.
	//vec3 screen_rgb = texture(screen_texture, SCREEN_UV).rgb;
	//screen_rgb.r +=0.1;
	//ALBEDO = screen_rgb;
	ALBEDO = vec3(1.0, 1.0, 0.0);

}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}