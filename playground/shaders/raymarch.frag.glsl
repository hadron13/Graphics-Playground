#version 330

#define PI 3.14159

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
float join(float a, float b){
    return min(a, b);
}

float intersection (float a, float b){
    return max(a, b);
}

float difference (float a, float b){
    return max(a, -b);
}

vec3 repeated(vec3 position, vec3 spacing){
    return position - spacing * round(position/spacing);
}

float sphere(vec3 origin, float radius, vec3 position){
    return distance(origin, position) - radius;
}

float box( vec3 origin, vec3 b, vec3 position ){
  vec3 q = abs(position - origin) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}



float de(vec3 p){
    p=fract(p)-.5;
    vec3 O=vec3(2.,0,3.);
    for(int j=0;j++<6;){
      p=abs(p);
      p=(p.x < p.y?p.zxy:p.zyx)*3.-O;
      if(p.z < -.5*O.z)
      p.z+=O.z;
    }
    return length(p.xy)/3e3;
}

float map(vec3 position){
    // float dist = de(position);
    float dist = sphere(vec3(-0.3, 0, 2.0), 0.25, position);
    dist = join (dist, sphere(vec3(0.3, 0.05, 1.7), 0.3, position));
    dist = join(dist, position.y + 0.25);
    dist = join(dist, position.x + 1.5);
    dist = join(dist, 1.5 - position.x);
    dist = join(dist, 3.0 - position.z);
    dist = join(dist, 1.2 + position.z);
    return dist;
}

struct material{
    vec3 albedo;
    float roughness;
    float metallic;
};

material map_material (vec3 position){
    if(position.z < -1.1){
        return material(vec3(1.0),  0.0, 0.0);
    }
    if(position.y < -0.24){
        return material(vec3(1.0),  1.0, 0.0);
    }
    if(position.x < -1.49){
        return material(vec3(1.0, 0, 0),  1.0, 0.0);
    }
    if(position.x > 1.49){
        return material(vec3(0, 1.0, 0),  1.0, 0.0);
    }
    if(position.x > 0.0 && position.z < 2.0){
        return material(vec3(1.00, 0.843, 0.0), 0.5, 1.0);
    }
    if(position.z > 2.9){
        return material(vec3(1.0),  0.0, 1.0);
    }

    // return material(vec3(1.00, 0.843, 0.0), 0.2, 1.0);
    return material(vec3(1.0), 0.0, 1.0);
}


vec3 normal(vec3 position){
    float eps = 0.00001;
    return normalize(vec3( 
        map(position + vec3(eps, 0, 0)) - map(position - vec3(eps, 0, 0)),
        map(position + vec3(0, eps, 0)) - map(position - vec3(0, eps, 0)),
        map(position + vec3(0, 0, eps)) - map(position - vec3(0, 0, eps))
    ));
}

float shadow(vec3 position, vec3 to_light_direction, float min_t, float max_t){
    float res = 1.0;
    float t = min_t;
    for(int i = 0; i < 64 && t < max_t; i++){
        float dist = map(position + to_light_direction * t);
        if(dist < 0.001){
            return 0.0;
        }
        t += dist;
        res = min( res, 16*dist/t );
    }
    return res;
}


#define FRESNEL_BALANCE 0.05
float fresnel_factor(vec3 view_direction, vec3 normal) {
    float fresnelDot = 1.0 - max(dot(-view_direction, normal), 0.0);
    return FRESNEL_BALANCE + (1.0 - FRESNEL_BALANCE * pow(fresnelDot, 5.0));
}


vec3 render(in vec3 position, 
            in vec3 view, 
            out vec3 ambient, 
            out vec3 diffuse, 
            out vec3 specular){
    vec3 normal = normal(position);

    vec3 light_color = vec3(1.0);
    vec3 light_position = vec3(sin(time), 1.0, 1.8 + cos(time));

    vec3 light_direction = normalize(light_position - position);
    vec3 reflect_direction = reflect(-light_direction, normal);  
    vec3 halfway_direction = -normalize(-light_direction + view);

    float light_distance = length(light_position - position);
    float attenuation = 0.3 / (0.3 + 0.5 * light_distance + 0.5 * light_distance * light_distance); 
    float shadow = shadow(position, light_direction, 0.01, light_distance);

    material mat = map_material(position);
   
    float shininess = pow(65535.0, 1.0 - mat.roughness);
    
    float spec_normalization = ((shininess + 2.0) * (shininess + 4.0)) / (8.0 * PI * (pow(2.0, -shininess * 0.5) + shininess));
    spec_normalization = max(spec_normalization - 0.3496155267919281, 0.0) * PI;

    float diffuse_factor = max(dot(normal, light_direction), 0)  * shadow ;
    float specular_factor = pow(max(dot(normal, halfway_direction), 0.0), shininess) * diffuse_factor * shadow * spec_normalization;

    ambient  = 0.10  * attenuation * mat.albedo;
    diffuse  = 1.00  * attenuation * diffuse_factor * mat.albedo;
    specular = 1.00  * attenuation * specular_factor * light_color;
    specular *= fresnel_factor(view, normal);

    vec3 color = mix(ambient + diffuse + specular, specular_factor * mat.albedo, mat.metallic);

    // vec3 color = ambient + diffuse + specular * mat.albedo;

    return color;
}

vec3 reflection(in vec3 position, in vec3 incident, float min_t, float max_t, material mat, out vec3 next_position, out vec3 next_direction){ 
    float t = min_t;
    
    vec3 normal = normal(position);
    vec3 ray_direction = reflect(incident, normal);
    next_position = position;
    next_direction = incident;

    vec3 result = vec3(0);



    float deviation = pow(mat.roughness, 0.5) * 1;
        
    ray_direction = reflect(incident, normal);
    vec3 ambient, diffuse, specular;
    for(int i = 0; i < 512 && t < max_t; i++){
        float dist = map(position + ray_direction * t);
        if(dist < 0.0001){
            next_position = position + ray_direction * t; 
            next_direction = ray_direction;
            vec3 reflection = render(next_position, ray_direction, ambient, diffuse, specular);
            
            result += mix(vec3(0), reflection * mat.albedo, mat.metallic);
            break;
        }
        t += dist;
    }
    
    return result;
}


void main(){

    vec2 uv = gl_FragCoord.xy/resolution.y - vec2((resolution.x/resolution.y - 1.0)/2.0, 0);
    vec2 centered_uv = (uv - 0.5)*2;

    vec3 ray_position = vec3(0, 1.0, 0);

        // vec3(-0.5, 0.5, -1.5)
    mat4 view = viewMatrix(ray_position, ray_position + normalize(vec3(0, 0, -1)), vec3(0, 1.0, 0));
    
    vec3 ray_direction = normalize(vec3(centered_uv, 1.0));
    ray_direction = (view * vec4(ray_direction, 1.0)).xyz;

    vec3 color = vec3(0);

    for(int i = 0; i < 256; i++){
        float dist = map(ray_position);
        ray_position += ray_direction * dist; 

        if(dist < 0.0001){
            vec3 ambient, diffuse, specular;
            material mat = map_material(ray_position);
            vec3 obj_color = mat.albedo;
            // vec3 obj_color = map_color(ray_position);

            render(ray_position, ray_direction, ambient, diffuse, specular);
            
            int bounces = 4;
            material bounced_mat = mat;
            for(int i = 0; i < bounces; i++){
                if(bounced_mat.metallic < 0.1){ //todo: swap for roughness later
                    break;
                }
                vec3 next_position, next_direction;

                if(bounced_mat.roughness < 0.1){
                    specular += reflection(ray_position, ray_direction, 0.01, 20.0, bounced_mat, next_position, next_direction);
                }else{
                    vec3 tangent = cross(ray_direction, vec3(0, 1.0, 0));
                    vec3 bitangent = cross(ray_direction, tangent);

                    float e = 0.2;
                    float samples = 16.0;

                    for(int i = 0; i < samples; i++){
                        vec3 perturbed = normalize(ray_direction + tangent * e * sin((i*2.0*PI)/samples) + bitangent * e * cos((i*2.0*PI)/samples) );
                        specular += reflection(ray_position, perturbed, 0.01, 20.0, bounced_mat, next_position, next_direction);
                    }


                    specular /= samples;
                }
                ray_position = next_position;
                ray_direction = next_direction;
                bounced_mat = map_material(ray_position);
            }

            color = mix(ambient + diffuse + specular, specular * mat.albedo, mat.metallic);
            // color = (ambient + diffuse + specular) * obj_color;
            break;
        }
    }

    float gamma = 2.2;
    // color = pow(color, vec3(1.0/gamma));

    gl_FragColor = vec4(color, 1.0); 
}

