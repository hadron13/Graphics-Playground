#version 330

uniform vec2 resolution;
uniform float time;


/*-----------------------------------------------

flim - Filmic Color Transform

Input Color Space:   Linear BT.709 I-D65
Output Color Space:  Linear BT.709 I-D65 / sRGB 2.2 (depends on arguments)

Description:
  Experimental port of flim for GLSL/Shadertoy
  matching flim v1.1.0.

Author:
  Bean (beans_please on Shadertoy)

Minified by:
  Ahsen (01000001 on shadertoy)

Original Repo:
  https://github.com/bean-mhm/flim

Original Shader:
  https://www.shadertoy.com/view/dd2yDz

-----------------------------------------------*/


const vec3 pf=vec3(1),pb=vec3(1),pff=vec3(1);
const float pe=4.3,ps=0.,gr=1.05,gg=1.12,gb=1.045,rr=.5,rg=2.,br=.1,rm=1.,gm=1.,bm=1.,lm=-10.,lx=22.,tx=.44,ty=.28,sx=.591,sy=.779,fe=6.,fd=5.,pfe=6.,pfd=27.5,ffs=0.,ms=1.02;

vec3 op(vec3 c,float p){return pow(c,vec3(1./p));}
float fw(float v,float s,float e){return s + mod(v-s,e-s);}
float fr(float v,float s,float e,float r,float f){return r + ((f-r)/(e-s))*(v-s);}
float f0( float v,float s,float e){return clamp((v-s)/(e-s),0.,1.);}
vec3 rh(vec3 r){
    float a,i,h,s,v,d;
    vec3 c;
    a=max(r[0],max(r[1],r[2]));
    i=min(r[0],min(r[1],r[2]));
    d=a-i;
    v=a;
    if (a!=0.){s=d/a;}
    else{s=0.; h=0.;}
    if (s==0.){h=0.;}
    else{c=(vec3(a)-r.xyz)/d;
        if (r.x==a){h=c[2]-c[1];}
        else if (r.y==a){h=2.+ c[0]-c[2];}
        else{h=4.+ c[1]-c[0];}
        h/=6.;
        if (h < 0.){h +=1.;}
    }
    return vec3(h,s,v);
}

vec3 hr(vec3 w){
    float f,p,q,t,h,s,v;
    vec3 g;
    h=w[0];
    s=w[1];
    v=w[2];
    if (s==0.){g=vec3(v,v,v);}
    else{
        if (h==1.){h=0.;}
        h*=6.;
        int i=int(floor(h));
        f=h-float(i);
        g=vec3(f,f,f);
        p=v*(1.-s);
        q=v*(1.-(s*f));
        t=v*(1.-(s*(1.-f)));
        if (i==0){g=vec3(v,t,p);}
        else if (i==1){g=vec3(q,v,p);}
        else if (i==2){g=vec3(p,v,t);}
        else if (i==3){g=vec3(p,q,v);}
        else if (i==4){g=vec3(t,p,v);}
        else{g=vec3(v,p,q);}
    }
    return g;
}

vec3 bs(vec3 c,float h,float s,float v)
{
    vec3 r=rh(c);
    r[0]=fract(r[0] + h + .5);
    r[1]=clamp(r[1]*s,0.,1.);
    r[2]=r[2]*v;
    return hr(r);
}

float fa(vec3 c){return (c.x + c.y + c.z)/3.;}
float fs(vec3 c){return c.x + c.y + c.z;}
float fr(vec3 c){return max(max(c.x,c.y),c.z);}
vec3 uo(vec3 c,float p,float w){
    float m=fa(c);
    float n=f0(m,p/1000.,1.-(w/1000.));
    return c*(n/m);
}

vec3 s(float h){
    h=fw(h*360.,0.,360.);
    vec3 c=vec3(1,0,0);
    c=mix(c,vec3(1,1,0),f0(h,0.,60.));
    c=mix(c,vec3(0,1,0),f0(h,60.,120.));
    c=mix(c,vec3(0,1,1),f0(h,120.,180.));
    c=mix(c,vec3(0,0,1),f0(h,180.,240.));
    c=mix(c,vec3(1,0,1),f0(h,240.,300.));
    c=mix(c,vec3(1,0,0),f0(h,300.,360.));
    return c;
}

float ss(float v,float x,float y,float sx,float sy){
    v=clamp(v,0.,1.);
    x=clamp(x,0.,1.);
    y=clamp(y,0.,1.);
    sx=clamp(sx,0.,1.);
    sy=clamp(sy,0.,1.);
    float s=(sy-y)/(sx-x);
    if (v < x){
        float t=s*x/y;
        return y*pow(v/x,t);
    }
    if (v < sx){
        float i=y-(s*x);
        return s*v + i;
    }
    float sp=-s/(((sx-1.)/pow(1.-sx,2.))*(1.-sy));
    return (1.-pow(1.-(v-sx)/(1.-sx),sp))*(1.-sy)+sy;
}

float dm(float m,float d){
    float o=pow(2.,lm);
    float f=f0(log2(m + o),lm,lx);
    f=ss(f,tx,ty,sx,sy);
    f*=d;
    f=pow(2.,-f);
    return clamp(f,0.,1.);
}

vec3 rl(vec3 c,vec3 st,vec3 dt,float d){
    vec3 sn=st/fs(st);
    vec3 dn=dt/fr(dt );
    float m=dot(c,sn);
    float f=dm(m,d);
    return mix(dn,vec3(1),f);
}

vec3 rd(vec3 c,float e,float d){
    c*=pow(2.,e);
    vec3 r=rl(c,vec3(0,0,1),vec3(1,1,0),d);
    r*=rl(c,vec3(0,1,0),vec3(1,0,1),d);
    r*=rl(c,vec3(1,0,0),vec3(0,1,1),d);
    return r;
}

vec3 ge(float p,float s,float r,float m){
    vec3 o=hr(vec3(fw(p + (r/360.),0.,1.),1./s,1.));
    o/=fs(o);
    o*=m;
    return o;
}

mat3 fm(float rs,float gs,float bs,float rr,float gr,float br,float rm,float gm,float bm){
    mat3 m;
    m[0]=ge(0.,rs,rr,rm);
    m[1]=ge(1./3.,gs,gr,gm);
    m[2]=ge(2./3.,bs,br,bm);
    return m;
}

vec3 np(vec3 c,vec3 b){
    c=rd(c,fe,fd);
    c*=b;
    c=rd(c,pfe,pfd);
    return c;
}

vec3 flim(vec3 c,float e,bool t){
    c=max(c,0.);
    c*=pow(2.,pe + e);
    c=min(c,5000.);
    mat3 x=fm(gr,gg,gb,rr,rg,br,rm,gm,bm);
    mat3 i=inverse(x);
    vec3 b=pb*x;
    const float g=1e7;
    vec3 w=np(vec3(g),b);
    c=mix(c,c*pf,ps);
    c*=x;
    c=np(c,b);
    c*=i;
    c=max(c,0.);
    c/=w;
    vec3 f=np(vec3(0.),b);
    f/=w;
    c=uo(c,fa(f)*1000.,0.);
    c=mix(c,c*pff,ffs);
    c=clamp(c,0.,1.);
    float m=fa(c);
    float mix_fac =(m<.5)? f0(m,.05,.5):f0(m,.95,.5);
    c=mix(c,bs(c,.5,ms,1.),mix_fac);
    c=clamp(c,0.,1.);
    if (t) c=op(c,2.2);
    return c;
}

/*____________________ end ____________________*/

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
    dist = join (dist, sphere(vec3(0.4, 0, 1.5), 0.25, position));
    dist = join(dist, position.y + 0.25);
    return dist;
}

struct material{
    float diffuse;
    float metalness;
    vec3  albedo;
};

vec3 map_color(vec3 position){
    return (position.y < -0.24)?vec3(1.0):vec3(1.00, 0.843, 0.0);
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
    for(int i = 0; i < 32 && t < max_t; i++){
        float dist = map(position + to_light_direction * t);
        if(dist < 0.001){
            return 0.0;
        }
        t += dist;
        res = min( res, 16*dist/t );
    }
    return res;
}



vec3 render(vec3 position){
    vec3 normal = normal(position);

    vec3 obj_color = map_color(position);
    vec3 light_color = vec3(1.0);
    vec3 light_position = vec3(1.0, 1.0, 0);

    vec3 light_direction = normalize(light_position - position);
    vec3 reflect_direction = reflect(-light_direction, normal);  

    float light_distance = length(light_position - position);
    float attenuation = 8.0 / (0.0 + 0.5 * light_distance + 0.1 * light_distance * light_distance); 
    float shadow = shadow(position, light_direction, 0.01, light_distance);

    vec3 ambient  = 0.001  * light_color;
    vec3 diffuse  = 0.01  * max(dot(normal, light_direction), 0) * light_color * shadow ;
    vec3 specular = 0.96  * pow(max(dot(normal, reflect_direction), 0.0), 64) * light_color * shadow;
    vec3 color = (ambient + diffuse + specular) * attenuation * obj_color;
    

    return color;
}

vec3 reflection(vec3 position, vec3 incident, float min_t, float max_t){ 
    float t = min_t;
    vec3 normal = normal(position);
    vec3 ray_direction = reflect(incident, normal);
    for(int i = 0; i < 32 && t < max_t; i++){
        float dist = map(position + ray_direction * t);
        if(dist < 0.001){
            return render(position + ray_direction * t);
        }
        t += dist;
    }
    return vec3(0);
}

void main(){

    vec2 uv = gl_FragCoord.xy/resolution.y - vec2((resolution.x/resolution.y - 1.0)/2.0, 0);
    vec2 centered_uv = (uv - 0.5)*2;

    vec3 ray_position = vec3(0, 0, 0);

        // vec3(-0.5, 0.5, -1.5)
    mat4 view = viewMatrix(ray_position, normalize(vec3(0, 0, -1)), vec3(0, 1.0, 0));
    
    vec3 ray_direction = normalize(vec3(centered_uv, 1.0));
    ray_direction = (view * vec4(ray_direction, 1.0)).xyz;

    vec3 color = vec3(0);

    for(int i = 0; i < 256; i++){
        float dist = map(ray_position);
        ray_position += ray_direction * dist; 

        if(dist < 0.0001){
            color = render(ray_position);
            color += 0.3 * map_color(ray_position) * reflection(ray_position, ray_direction, 0.01, 20.0);
            // color = flim(color, 0.5, true);
            break;
        }
    }

    float gamma = 2.2;
    color = pow(color, vec3(1.0/gamma));

    gl_FragColor = vec4(color, 1.0); 
}

