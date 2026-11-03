shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
// Double-sided psx_vertex (materials with cull off: leaves, cloth, paper).
#include "res://scenes/world3d/psx_style.gdshaderinc"
