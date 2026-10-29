
shader_type spatial;
render_mode unshaded, cull_front, depth_prepass_alpha;

uniform vec4 outline_color : source_color = vec4(1.0, 0.02, 0.02, 1.0);
// uniform float outline_width : hint_range(0.001, 0.1) = 0.025;
uniform float pulse_speed = 8;
uniform float max_opacity : hint_range(0.0, 1.0) = 0.5;

void vertex() {
  //  VERTEX += NORMAL * outline_width;
}

void fragment() {
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);

    ALBEDO = outline_color.rgb;
    ALPHA = pulse * max_opacity * outline_color.a;
}
