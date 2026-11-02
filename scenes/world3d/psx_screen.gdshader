shader_type canvas_item;
// PS1-style colour (PsxLook3D): the low-res 3D image gets 15-bit colour
// with an optional 4x4 Bayer dither; pixels stay whole (nearest upscale).

uniform float levels = 32.0;
uniform float dither = 0.0;

const float BAYER[16] = float[](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	vec2 cell = floor(UV / TEXTURE_PIXEL_SIZE);
	int i = int(mod(cell.x, 4.0)) + int(mod(cell.y, 4.0)) * 4;
	float d = (BAYER[i] / 16.0 - 0.5) * dither;
	c = floor(c * (levels - 1.0) + 0.5 + d) / (levels - 1.0);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
