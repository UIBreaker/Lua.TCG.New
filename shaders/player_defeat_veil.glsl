extern number progress;
extern number elapsed;
extern number impact;
extern vec3 shadow;
extern number darkness;

vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec2 p = uv * 2.0 - 1.0;
    number edge = smoothstep(0.22, 1.28, length(p * vec2(0.90, 0.82)));
    number drift = sin(uv.x * 7.0 + elapsed * 0.28) * 0.025
        + sin(uv.x * 13.0 - elapsed * 0.19) * 0.012;
    number fog = smoothstep(0.40, 1.12, uv.y + drift);
    number alpha = (darkness * 0.70 + edge * 0.23 + fog * 0.12) * progress;
    vec3 tint = mix(shadow, vec3(0.24, 0.035, 0.055), impact * edge);
    return vec4(tint, min(0.95, alpha + impact * edge * 0.20)) * color;
}
