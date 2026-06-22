shader_type spatial;
// render_mode blend_mix allows transparency calculations
render_mode blend_mix, depth_draw_always;

// The color of the filled portion
instance uniform vec4 fill_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
// The color of the empty/background portion
instance uniform vec4 empty_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);

instance uniform float min_value = 0.0;
instance uniform float max_value = 100.0;
instance uniform float value = 0.0;

// Varying variable to pass local position from vertex function to fragment function
varying float local_position;

void vertex() {
	// Called for every vertex the material is visible on.
	// A default Godot CapsuleMesh spans from -1.0 to +1.0 on its height axis.
	// We remap this range from [-1.0, 1.0] to [0.0, 1.0] to work with percentages.
	// Use VERTEX.y because default meshes extend vertically before you rotate the Node3D.
	local_position = (VERTEX.y + 1.0) / 2.0;
}

void fragment() {
	// Called for every pixel the material is visible on.
	float fill_percentage = (value - min_value) / (max_value - min_value);
	
	// For a sharp line, step() returns 0.0 if local_position < fill_percentage, and 1.0 if greater
	float mask = step(fill_percentage, 1.0 - local_position);
	// Mix the two colors based on the mask
	vec4 final_color = mix(fill_color, empty_color, mask);

	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
