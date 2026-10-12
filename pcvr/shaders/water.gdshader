shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D water_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float wave_strength : hint_range(0.0, 1.5) = 0.75;
varying vec3 water_position;

void vertex() {
    // Les sommets sont réellement ondulés ; taille adaptée dans main.gd.
    float swell = sin(VERTEX.x * 0.14 + TIME * 0.8) * 0.09;
    swell += cos(VERTEX.z * 0.12 + TIME * 0.61) * 0.06;
    VERTEX.y += swell * wave_strength;
    water_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 uv = UV * 46.0;
    float t = TIME;
    vec2 ripple = vec2(sin(uv.y * 0.24 + t * 0.8), cos(uv.x * 0.28 - t * 0.64)) * 0.13;
    vec3 base_color = texture(water_tex, uv + ripple + vec2(t * 0.02, t * 0.013)).rgb;
    // Fine mousse stylisée sur la côte, sans alpha coûteux en VR.
    float radius = length(water_position.xz);
    float coast = 63.5 + sin(water_position.x * 0.10) * 2.3 + cos(water_position.z * 0.13) * 1.7;
    float foam = (1.0 - smoothstep(0.5, 4.0, abs(radius - coast))) * 0.32;
    float sparkle = pow(max(sin(uv.x * 0.53 + t * 1.75) * cos(uv.y * 0.46 - t * 1.08), 0.0), 9.0) * 0.1;

    ALBEDO = mix(base_color * vec3(0.65, 0.89, 1.15), vec3(0.13, 0.54, 0.75), 0.46);
    ALBEDO = mix(ALBEDO, vec3(0.81, 0.95, 0.98), foam);
    // ILE_MANGA_V12_WATER: micro variations de surface sobres et peu couteuses.
    float micro = sin(uv.x * 0.82 + t * 0.45) * cos(uv.y * 0.77 - t * 0.51);
    ALBEDO *= mix(0.97, 1.045, 0.5 + 0.5 * micro);
    ROUGHNESS = 0.25 + ripple.x * 0.04;
    METALLIC = 0.08;
    SPECULAR = 0.65;
    EMISSION = vec3(0.16, 0.36, 0.45) * sparkle;
}
