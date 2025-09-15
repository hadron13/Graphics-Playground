#version 330

uniform vec2 resolution;
uniform float time;

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
	vec3 f = normalize(center - eye);
	vec3 s = normalize(cross(f, up));
	vec3 u = cross(s, f);
	return mat4(
		vec4(s, 0.0),
		vec4(u, 0.0),
		vec4(-f, 0.0),
		vec4(0.0, 0.0, 0.0, 1)
	);
}

mat4 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat4(
        vec4(c, 0, s, 0),
        vec4(0, 1, 0, 0),
        vec4(-s, 0, c, 0),
        vec4(0, 0, 0, 1)
    );
}

vec3 repeated(vec3 position, vec3 size){
    return position - size*round(position/size);

}

float sphere(vec3 origin, float radius, vec3 position){
    return distance(origin, position) - radius;
}

float box( vec3 origin, vec3 b, vec3 position ){
  vec3 q = abs(position - origin) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float join(float a, float b){
    return min(a, b);
}

float intersection (float a, float b){
    return max(a, b);
}

float difference (float a, float b){
    return max(a, -b);
}

float map(vec3 position){
    // return difference(sphere(vec3(-0.25, 0, 2.0), 0.5, position), sphere(vec3(0.25, 0.0, 1.8), 0.5, position));
    return difference(intersection(box(vec3(0, 0, 1.5), vec3(0.5), position), sphere(vec3(0, 0, 1.5), 0.65, position)), sphere(vec3(0, 0, 1.5), 0.6, position));
}

vec3 normal(vec3 position){
    float d = map(position);
    float eps = 0.000001;
    return normalize(vec3( 
        map(position + vec3(eps, 0, 0)) - map(position - vec3(eps, 0, 0)),
        map(position + vec3(0, eps, 0)) - map(position - vec3(0, eps, 0)),
        map(position + vec3(0, 0, eps)) - map(position - vec3(0, 0, eps))
    ));
}

void main(){

    vec2 uv = gl_FragCoord.xy/resolution.y - vec2((resolution.x/resolution.y - 1.0)/2.0, 0);
    vec2 centered_uv = (uv - 0.5)*2;

    vec3 ray_position = vec3(sin(time), 0, cos(time) + 0.75) * 2.0;
    mat4 view = viewMatrix(ray_position, ray_position + vec3(sin(time), 0, cos(time)), vec3(0, 1.0, 0));
    
    vec3 ray_direction = normalize(vec3(centered_uv, 1.0));
    ray_direction = (view * vec4(ray_direction, 1.0)).xyz;

    vec3 sphere_origin = vec3(0, 0, 2.0);
    vec3 light_direction = normalize(vec3(0.5, 0.0, -1.0));  

    vec3 color = vec3(0);

    for(int i = 0; i < 50; i++){
        float dist = map(ray_position);
        ray_position += ray_direction * dist; 

        if(dist < 0.001){
            vec3 normal = normal(ray_position);
            color = vec3(dot(normal, light_direction));
            // color = vec3(1);
            break;
        }
    }


    gl_FragColor = vec4(color, 1.0); 
}

