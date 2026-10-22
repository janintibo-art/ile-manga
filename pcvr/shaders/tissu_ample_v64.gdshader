shader_type spatial;
// V64 : les tissus des vêtements amples (jupes, robes, tabliers, capes) : visibles des deux côtés.
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;
#include "res://shaders/tissu_v64.gdshaderinc"
