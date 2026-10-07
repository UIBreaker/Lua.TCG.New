extern number u_time;
extern number u_intensity;
extern number u_speed;
extern vec2 u_mouseUV;
extern vec2 u_tilt;
extern number u_hoverAmount;
extern number u_selectedAmount;
extern number u_scorePulse;
extern number u_selectPulse;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 base = Texel(texture, texture_coords) * color;
    if (base.a <= 0.003) return vec4(0.0);

    vec2 uv = texture_coords;
    number response = clamp(u_hoverAmount * 0.58 + u_selectedAmount * 0.72
        + u_scorePulse * 0.98 + u_selectPulse * 0.30, 0.0, 1.0);
    number diagonal = uv.x + uv.y * 0.46 + u_tilt.x * 0.45 - u_tilt.y * 0.28;
    number sweepCenter = mod(u_time * u_speed * 0.27 + u_mouseUV.x * 0.22 + 0.30, 1.52) - 0.22;
    number distanceToBand = abs(diagonal - sweepCenter);
    number band = exp(-distanceToBand * distanceToBand * 180.0);
    number razor = exp(-distanceToBand * distanceToBand * 2400.0);
    number softBand = exp(-distanceToBand * distanceToBand * 5.5) * 0.18;
    number cursorGlint = exp(-length((uv - u_mouseUV) * vec2(1.0, 0.72)) * 23.0)
        * u_hoverAmount * 0.22;
    number grain = sin(dot(uv * vec2(560.0, 360.0), vec2(1.17, 2.31)) + u_time * 0.4) * 0.009;

    vec3 silver = vec3(0.72, 0.86, 1.0);
    vec3 warmMetal = vec3(0.88, 0.94, 1.0);
    vec3 metalTint = mix(silver, warmMetal, clamp(uv.x * 0.42 + u_tilt.y * 0.4, 0.0, 1.0));
    number shine = band * (0.22 + response * 0.44) + softBand * (0.12 + response * 0.18) + cursorGlint;
    number reflection = clamp(band * (0.10 + response * 0.30) * u_intensity, 0.0, 0.42);
    vec3 rgb = mix(base.rgb, mix(base.rgb, metalTint, 0.42), reflection)
        + metalTint * shine * u_intensity * 0.72 + vec3(0.85,0.95,1.0)*razor*u_intensity*0.42 + base.rgb * grain * u_intensity;
    rgb = mix(rgb, base.rgb * vec3(.86,.96,1.08), min(.22,u_intensity*.18));
    return vec4(clamp(rgb, 0.0, 1.0), base.a);
}
