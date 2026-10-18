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
    // Cyan/violet thin film stays distinct from Polychrome's six-color prism.
    return mix(vec3(.18,.70,1.0),vec3(.92,.28,.98),.5+.5*sin(6.28318*hue));
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
    number phase = uv.x * 0.82 + uv.y * 0.52 + sin(uv.y*4.0+u_time*u_speed*.4)*.10 + u_tilt.x * 0.65 - u_tilt.y * 0.38
        + u_mouseUV.x * 0.22 - u_mouseUV.y * 0.08 + sin(uv.y * 7.0 + u_time * u_speed) * 0.045;
    vec3 spectrum = spectralPalette(phase + u_time * u_speed * 0.10);

    number interference = 0.5 + 0.5 * sin((uv.x * 0.82 + uv.y * 0.58 + u_mouseUV.y * 0.14
        + u_tilt.x * 0.5) * 58.0 + u_time * u_speed * 3.6);
    number sweep = mod(u_time*u_speed*.22,1.7)-.30;
    number band = exp(-pow(uv.x*.72+uv.y*.44-sweep+u_mouseUV.x*.15,2.0)*85.0);

    vec2 cell = floor(uv * 23.0);
    number sparkleSeed = hashCell(cell);
    number sparkleWave = max(0.0, sin(u_time * u_speed * 4.0 + sparkleSeed * 31.0));
    vec2 speck=fract(uv*23.0)-vec2(.5);
    number glint=exp(-dot(speck,speck)*180.0)
        +exp(-abs(speck.x)*100.0-abs(speck.y)*12.0)*.35
        +exp(-abs(speck.y)*100.0-abs(speck.x)*12.0)*.35;
    number sparkle = step(0.987, sparkleSeed) * glint * pow(sparkleWave, 10.0) * (.4+interaction*.6);
    number blendAmount = (0.045 + 0.22 * interaction + 0.10 * band + 0.055 * interference)
        * u_intensity;
    vec3 film = base.rgb*(.82+spectrum*.65)+spectrum*.09;
    vec3 rgb = mix(base.rgb, film, clamp(blendAmount*2.0, 0.0, 0.72));
    rgb += spectrum * (band * (0.16 + interaction * 0.18) + interference*.055) * u_intensity;
    rgb += vec3(.86,.94,1.0)*sparkle*.55*u_intensity;
    number caustic = pow(.5+.5*sin(phase*25.0+u_time*u_speed*.7),28.0);
    rgb += mix(spectrum,vec3(.85,.96,1.0),.40)*caustic*.22*u_intensity;
    // Horizontal interference ribbons contrast with Foil's single diagonal.
    number ribbons=pow(.5+.5*sin(uv.y*23.0+sin(uv.x*5.0+u_time*u_speed)*1.8-u_time*u_speed*1.3),18.0);
    vec3 ribbonColor=mix(vec3(.25,.83,1.0),vec3(.92,.30,.95),.5+.5*sin(uv.y*12.0+u_time*u_speed*.6));
    rgb+=ribbonColor*ribbons*.23*u_intensity;
    return vec4(clamp(rgb, 0.0, 1.0), base.a);
}
