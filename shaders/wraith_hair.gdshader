shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;
// The wraith's hair cards: wraith.gdshader, seen from both sides; the strand texture's alpha goes to coverage (MSAA)
// with alpha_cut as the scissor, so the strands stay fine and soft without transparency sorting.

#define HAIR_CARDS
#include "res://shaders/wraith.gdshaderinc"
