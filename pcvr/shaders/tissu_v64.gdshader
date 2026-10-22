shader_type spatial;
// V64 : les tissus des habitants (vêtements « coques » posés sur le corps).
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
#define SUR_CORPS
#include "res://shaders/tissu_v64.gdshaderinc"
