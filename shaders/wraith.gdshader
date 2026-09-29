shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;
// The night-2 wraith's flesh (scripts/world/wraith/wraith_view.gd puts it on the skin, teeth, eyes and throat of
// models/generated/wraith.glb, built by tools/blender/wraith/build.py). Lit and opaque: it stands in the fog with the trees.
// Albedo + normal map baked in Blender (models/generated/tex/wraith_skin*.png), or a flat tint (teeth, eyes).
// presence 0..1 dissolves it in and out through drifting noise with a cold burning edge; below hem_top (metres above
// base_y, its feet) it thins into mist; flicker stutters holes through it with dread; a faint cold rim on the silhouette.

#include "res://shaders/wraith.gdshaderinc"
