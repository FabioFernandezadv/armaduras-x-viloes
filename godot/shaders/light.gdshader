shader_type canvas_item;

uniform vec2 center = vec2(320.0, 270.0);
uniform float radius = 220.0;
uniform float darkness = 0.65;
uniform vec3 fog = vec3(0.0, 0.03, 0.1);

void fragment() {
	vec2 px = SCREEN_UV * vec2(960.0, 540.0);
	float d = distance(px, center);
	float a = smoothstep(radius * 0.28, radius, d) * darkness;
	COLOR = vec4(fog, a);
}
