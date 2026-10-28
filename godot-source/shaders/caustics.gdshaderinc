// Low frequency, world-anchored refracted light; no per-frame random flicker.
float creek_caustics(vec2 p, float t) {
    p += vec2(sin(p.y * .7 + t * .21), cos(p.x * .6 - t * .18)) * .24;
    float a = sin(p.x * 3.3 + p.y * 1.7 + t * .32);
    float b = sin(p.y * 3.7 - p.x * 1.4 - t * .27);
    float c = sin((p.x + p.y) * 2.3 + t * .19);
    float ridge = 1.0 - smoothstep(.035, .22, abs(a + b + c * .55));
    return ridge * (.65 + .35 * sin(p.x * .6 + p.y * .4 + t * .18));
}
