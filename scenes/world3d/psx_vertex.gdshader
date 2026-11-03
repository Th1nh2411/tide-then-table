shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
// PS1-style surface (PsxLook3D) + the village grade (StylePass3D); body in
// psx_style.gdshaderinc. psx_vertex_2s is the same, double-sided.
#include "res://scenes/world3d/psx_style.gdshaderinc"
