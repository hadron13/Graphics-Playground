#version 330

uniform vec2 resolution;
uniform float time;


float sphere(vec3 origin, float radius, vec3 position){
    return distance(origin, position) - radius;
}


void main(){

    vec2 uv = gl_FragCoord.xy/resolution.y - vec2((resolution.x/resolution.y - 1.0)/2.0, 0);
    vec2 centered_uv = (uv - 0.5)*2;

    
    vec3 ray_position = vec3(0);
    vec3 ray_direction = normalize(vec3(centered_uv, 1.0));
    vec3 sphere_origin = vec3(0, 0, 1.0);
    vec3 light_direction = normalize(vec3(0.5, sin(time), -1.0));  

    vec3 color = vec3(0);

    for(int i = 0; i < 50; i++){
        float dist = sphere(sphere_origin, 0.5, ray_position);
        ray_position += ray_direction * dist; 

        if(dist < 0.001){
            vec3 normal = normalize(vec3(ray_position - sphere_origin));
            color = vec3(dot(normal, light_direction));
            // color = vec3(1);
            break;
        }
    }


    gl_FragColor = vec4(color, 1.0); 
}

