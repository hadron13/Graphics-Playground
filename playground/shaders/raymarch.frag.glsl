#version 330

uniform vec2 resolution;

void main(){

    vec2 uv = gl_FragCoord.xy/resolution.x;
    vec2 centered_uv = (uv - 1.0)*2.0;


    gl_FragColor = vec4(uv, 0.0, 1.0); 
}

