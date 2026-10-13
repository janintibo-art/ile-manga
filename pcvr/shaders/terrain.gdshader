shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D sand_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool extra_detail = false;

varying vec3 world_position;
varying float terrain_slope;

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
    vec2 a = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash2(a), hash2(a + vec2(1.0, 0.0)), f.x),
               mix(hash2(a + vec2(0.0, 1.0)), hash2(a + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    terrain_slope = 1.0 - abs(NORMAL.y);
}

void fragment() {
    vec2 uv = world_position.xz * 0.18;
    float macro_variation = (noise2(world_position.xz * 0.065) - 0.5) * 2.7;
    float small_variation = (noise2(world_position.xz * 0.35) - 0.5) * 0.4;
    float height = world_position.y + macro_variation + small_variation;

    float grass_weight = smoothstep(0.0, 1.7, height);
    float rock_weight = smoothstep(4.8, 7.1, height + terrain_slope * 3.2);
    float beach_weight = 1.0 - grass_weight;

    vec3 sand = texture(sand_tex, uv).rgb;
    vec3 grass = texture(grass_tex, uv).rgb;
    vec3 stone = texture(stone_tex, uv).rgb;
    if (extra_detail) {
        vec3 near_grass = texture(grass_tex, uv * 3.1).rgb;
        grass = mix(grass, near_grass, 0.22);
    }
    vec3 ground = mix(sand * vec3(1.02, 0.99, 0.91), grass * vec3(0.94, 1.04, 0.92), grass_weight);
    ground = mix(ground, stone * vec3(0.99, 1.00, 1.04), rock_weight * 0.78);
    // ILE_MANGA_V12_TERRAIN: larges variations douces de teinte (sans changer le relief).
    float broad = noise2(world_position.xz * 0.025);
    ground *= mix(0.91, 1.08, broad);
    ground *= mix(0.94, 1.04, noise2(world_position.xz * 0.18));

    ALBEDO = ground;
    ROUGHNESS = mix(0.98, 0.84, rock_weight);
    METALLIC = 0.0;
    SPECULAR = 0.17 + 0.08 * beach_weight;
}
