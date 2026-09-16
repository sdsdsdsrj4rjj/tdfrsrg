#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D Texture;
varying vec2 TEX0;

#pragma parameter FRY "Deep Fry" 1.0 0.0 2.0 0.05
#pragma parameter CONTRAST "Contrast" 1.35 0.5 2.5 0.05
#pragma parameter SATURATION "Saturation" 1.55 0.5 3.0 0.05
#pragma parameter SHARPNESS "Sharpness" 0.35 0.0 1.0 0.05
#pragma parameter HEAT "Orange Heat" 0.20 0.0 0.6 0.02
#pragma parameter CRUNCH "Color Crunch" 0.18 0.0 0.5 0.02
#pragma parameter ABERRATION "Chromatic Aberration" 0.002 0.0 0.01 0.001
#pragma parameter VIGNETTE "Vignette" 0.18 0.0 0.6 0.02
#pragma parameter GRAIN "Fine Grain" 0.035 0.0 0.15 0.005

#pragma parameter PIXEL_NOISE "Pixel Noise" 0.20 0.0 1.0 0.05
#pragma parameter BLOCK_ARTIFACTS "JPEG Block Artifacts" 0.25 0.0 1.0 0.05
#pragma parameter BLOCK_SIZE "Artifact Block Size" 48.0 8.0 96.0 4.0
#pragma parameter BLOCK_COLOR "Block Color Shift" 0.15 0.0 0.5 0.025


float hash(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);

    return fract(p.x * p.y);
}


vec3 saturate_color(vec3 color, float amount)
{
    float gray =
        dot(color, vec3(0.299, 0.587, 0.114));

    return mix(vec3(gray), color, amount);
}


void main()
{
    vec2 uv = TEX0;

    // =========================================
    // CHROMATIC ABERRATION
    // =========================================

    vec2 center = uv - 0.5;
    float dist = length(center);

    vec2 aberration =
        center * ABERRATION * FRY;

    float r =
        texture2D(Texture, uv + aberration).r;

    float g =
        texture2D(Texture, uv).g;

    float b =
        texture2D(Texture, uv - aberration).b;

    vec3 color = vec3(r, g, b);


    // =========================================
    // SHARPENING
    // =========================================

    vec2 px = vec2(
        1.0 / 320.0,
        1.0 / 240.0
    );

    vec3 north =
        texture2D(Texture,
            uv + vec2(0.0, -px.y)).rgb;

    vec3 south =
        texture2D(Texture,
            uv + vec2(0.0, px.y)).rgb;

    vec3 east =
        texture2D(Texture,
            uv + vec2(px.x, 0.0)).rgb;

    vec3 west =
        texture2D(Texture,
            uv + vec2(-px.x, 0.0)).rgb;

    vec3 blur =
        (north + south + east + west) * 0.25;

    color +=
        (color - blur) *
        SHARPNESS *
        FRY;


    // =========================================
    // CONTRAST
    // =========================================

    color =
        (color - 0.5) *
        CONTRAST +
        0.5;


    // =========================================
    // SATURATION
    // =========================================

    color =
        saturate_color(
            color,
            SATURATION
        );


    // =========================================
    // ORANGE HEAT
    // =========================================

    color.r += HEAT * 0.16;
    color.g += HEAT * 0.045;
    color.b -= HEAT * 0.08;

    color.r *=
        1.0 + HEAT * 0.30;

    color.g *=
        1.0 + HEAT * 0.08;

    color.b *=
        1.0 - HEAT * 0.12;


    // =========================================
    // COLOR CRUNCH
    // =========================================

    float levels =
        mix(
            64.0,
            18.0,
            CRUNCH * FRY
        );

    color =
        floor(color * levels + 0.5)
        / levels;


    // =========================================
    // JPEG-ISH BLOCKS
    // =========================================

    vec2 blocks =
        floor(uv * BLOCK_SIZE);

    float blockRandom =
        hash(blocks);

    float blockDamage =
        (blockRandom - 0.5) *
        BLOCK_COLOR *
        BLOCK_ARTIFACTS *
        FRY;

    vec3 blockShift =
        vec3(
            blockDamage * 1.35,
            blockDamage * 0.65,
            -blockDamage * 0.90
        );

    color += blockShift;


    // =========================================
    // CHUNKY PIXEL NOISE
    // =========================================

    vec2 noiseGrid =
        floor(
            uv *
            BLOCK_SIZE *
            1.75
        );

    float pixelNoise =
        hash(noiseGrid);

    float noiseAmount =
        (pixelNoise - 0.5) *
        PIXEL_NOISE *
        0.28 *
        FRY;

    color += noiseAmount;


    // =========================================
    // OCCASIONAL BAD BLOCKS
    // =========================================

    float damageChance =
        step(0.82, blockRandom);

    float damageAmount =
        (blockRandom - 0.82) *
        1.8 *
        BLOCK_ARTIFACTS *
        FRY;

    color +=
        damageChance *
        damageAmount *
        vec3(
            1.0,
            0.72,
            0.45
        );


    // =========================================
    // HIGHLIGHT BLOWOUT
    // =========================================

    vec3 highlights =
        max(color - 0.72, 0.0);

    color +=
        highlights *
        highlights *
        2.2 *
        FRY;


    // =========================================
    // SHADOW CRUSH
    // =========================================

    float luminance =
        dot(
            color,
            vec3(
                0.299,
                0.587,
                0.114
            )
        );

    float shadow =
        1.0 -
        smoothstep(
            0.0,
            0.32,
            luminance
        );

    color *=
        1.0 -
        shadow *
        0.22 *
        FRY;


    // =========================================
    // EXTRA WARMTH
    // =========================================

    color =
        mix(
            color,
            color *
            vec3(
                1.08,
                1.015,
                0.91
            ),
            HEAT
        );


    // =========================================
    // VIGNETTE
    // =========================================

    float vignette =
        smoothstep(
            0.95,
            0.25,
            dist
        );

    color *=
        mix(
            1.0 - VIGNETTE,
            1.0,
            vignette
        );


    // =========================================
    // FINE GRAIN
    // =========================================

    float grain =
        hash(uv * 1000.0);

    color +=
        (grain - 0.5) *
        GRAIN *
        FRY;


    // =========================================
    // OUTPUT
    // =========================================

    color =
        clamp(
            color,
            0.0,
            1.0
        );

    gl_FragColor =
        vec4(color, 1.0);
}
