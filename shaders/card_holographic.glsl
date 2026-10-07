extern number u_time;
extern number u_intensity;
extern number u_speed;
extern vec2 u_mouseUV;
extern vec2 u_tilt;
extern number u_hoverAmount;
extern number u_selectedAmount;
extern number u_scorePulse;
extern number u_selectPulse;

vec3 spectralPalette(number hue) {
    return 0.5 + 0.5 * cos(6.28318 * (hue + vec3(0.0, 0.34, 0.67)));
}

number hashCell(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 base = Texel(texture, texture_coords) * color;
    if (base.a <= 0.003) return vec4(0.0);

    vec2 uv = texture_coords;
    number interaction = clamp(u_hoverAmount * 0.58 + u_selectedAmount * 0.70
        + u_scorePulse * 1.0 + u_selectPulse * 0.30, 0.0, 1.0);
    number phase = uv.x * 0.82 + uv.y * 0.52 + u_tilt.x * 0.65 - u_tilt.y * 0.38
        + u_mouseUV.x * 0.22 - u_mouseUV.y * 0.08 + sin(uv.y * 7.0 + u_time * u_speed) * 0.045;
    vec3 spectrum = spectralPalette(phase + u_time * u_speed * 0.10);

    number interference = 0.5 + 0.5 * sin((uv.x * 0.82 + uv.y * 0.58 + u_mouseUV.y * 0.14
        + u_tilt.x * 0.5) * 58.0 + u_time * u_speed * 3.6);
    number sweep = mod(u_time*u_speed*.22,1.7)-.30;
    number band = exp(-pow(uv.x*.72+uv.y*.44-sweep+u_mouseUV.x*.15,2.0)*85.0);

    vec2 cell = floor(uv * 23.0);
    number sparkleSeed = hashCell(cell);
    number sparkleWave = max(0.0, sin(u_time * u_speed * 4.0 + sparkleSeed * 31.0));
    number sparkle = step(0.987, sparkleSeed) * pow(sparkleWave, 10.0) * (.4+interaction*.6);
    number blendAmount = (0.045 + 0.22 * interaction + 0.10 * band + 0.055 * interference)
        * u_intensity;
    vec3 rgb = mix(base.rgb, spectrum, clamp(blendAmount, 0.0, 0.40));
    rgb += spectrum * (band * (0.16 + interaction * 0.18) + interference*.055) * u_intensity;
    rgb += vec3(.86,.94,1.0)*sparkle*.55*u_intensity;
    return vec4(clamp(rgb, 0.0, 1.0), base.a);
}
