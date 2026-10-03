extern vec2 texel;
extern vec3 ambientTint;
extern vec3 rimTint;
extern float rimStrength;
extern float tintStrength;
extern float eventLight;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec4 c=Texel(image,uv);
    float neighbor=Texel(image,uv+vec2(texel.x*2.0,0.0)).a;
    float rim=max(0.0,c.a-neighbor)*rimStrength;
    c.rgb*=mix(vec3(1.0),ambientTint,tintStrength);
    c.rgb+=rimTint*rim+rimTint*eventLight*0.08;
    return c*color;
}
