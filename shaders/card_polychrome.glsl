extern number u_time;
extern number u_intensity;
extern number u_speed;
extern vec2 u_mouseUV;
extern vec2 u_tilt;
extern number u_hoverAmount;
extern number u_selectedAmount;
extern number u_scorePulse;
extern number u_selectPulse;

vec3 flowingPalette(number value) {
    return 0.50 + 0.50 * cos(6.28318 * (value + vec3(0.02, 0.31, 0.64)));
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;
    vec4 base = Texel(texture, uv) * color;
    if (base.a <= 0.003) return vec4(0.0);

    number interaction = clamp(u_hoverAmount * 0.52 + u_selectedAmount * 0.68
        + u_scorePulse * 0.98 + u_selectPulse * 0.28, 0.0, 1.0);
    number flowA = sin(uv.x * 4.0 + uv.y * 3.1 + u_time * u_speed
        + sin(uv.y * 4.4 - u_time * u_speed * 0.63) * 0.7 + u_tilt.x * 2.0);
    number flowB = cos(uv.y * 3.7 - uv.x * 2.3 - u_time * u_speed * 0.78
        + sin(uv.x * 2.8 + u_mouseUV.y * 3.0) * 0.65 + u_tilt.y * 2.0);
    number field = 0.5 + flowA * 0.19 + flowB * 0.17 + (uv.x - uv.y) * 0.08;
    // Broad, moving jewel facets distinguish this material from thin-film holo.
    number facet = floor((uv.x + uv.y * .62 + flowA * .12) * 6.0) / 6.0;
    vec3 palette = flowingPalette(facet + u_mouseUV.x * 0.08 + u_time * u_speed * 0.045);
    number seam = pow(1.0 - abs(sin((uv.x + uv.y * .62 + flowA * .12) * 18.84954)), 18.0);

    number edgeDistance = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    number edgeGlow = 1.0 - smoothstep(0.018, 0.18, edgeDistance);
    number split = 0.001 + interaction * 0.004;
    vec2 warp = vec2(flowA, flowB) * (0.0005 + interaction * 0.0015);
    vec2 redUV = clamp(uv + warp + vec2(split, 0.0), vec2(0.0), vec2(1.0));
    vec2 blueUV = clamp(uv + warp - vec2(split, 0.0), vec2(0.0), vec2(1.0));
    vec3 slightSplit = vec3(Texel(texture, redUV).r, base.g, Texel(texture, blueUV).b);
    vec3 rgb = mix(base.rgb, slightSplit, clamp(interaction * 0.34 * u_intensity, 0.0, 0.16));
    number colorMix = (0.22 + interaction * 0.35) * u_intensity;
    // Light passes through the facets: retain the illustration's tonal contrast.
    vec3 crystal = base.rgb * (.75 + palette*.80) + palette*.055;
    rgb = mix(rgb, crystal, clamp(colorMix*1.9, 0.0, 0.75));
    rgb += palette * edgeGlow * (0.035 + interaction * 0.09) * u_intensity;
    rgb += mix(palette,vec3(1.0),.35) * seam * (.16 + interaction * .14) * u_intensity;
    return vec4(clamp(rgb, 0.0, 1.0), base.a);
}
