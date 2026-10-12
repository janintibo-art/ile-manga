shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D sand_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 uv = world_position.xz * 0.16;
    vec3 sand = texture(sand_tex, uv).rgb;
    vec3 grass = texture(grass_tex, uv).rgb;
    vec3 stone = texture(stone_tex, uv).rgb;
    float variation = sin(world_position.x * 0.32) * cos(world_position.z * 0.24) * 0.35;
    float meadow = smoothstep(0.3, 1.8, world_position.y + variation);
    float rock = smoothstep(5.0, 7.2, world_position.y + variation);
    ALBEDO = mix(mix(sand, grass, meadow), stone, rock * 0.72);
    ROUGHNESS = 0.95;
    METALLIC = 0.0;
}
