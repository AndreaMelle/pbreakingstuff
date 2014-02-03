#define PROCESSING_LIGHT_SHADER

uniform vec4 ambientMat;
uniform vec4 diffuseMat;
uniform vec4 specMat;
uniform float specPow;

uniform mat4 modelview;
uniform mat4 transform;
uniform mat3 normalMatrix;
uniform vec4 lightPosition;

varying vec4 color;

varying vec3 N;
varying vec3 v;
varying vec4 diffuse;
varying vec4 spec;

attribute vec4 vertex;
attribute vec3 normal;

void main()
{
	vec4 diffuse;
	vec4 spec;
	vec4 ambient;

   v = vec3(modelview * vertex);
   N = normalize(normalMatrix * normal);
   gl_Position = transform * vertex;  

   vec3 L = normalize(lightPosition.xyz - v);
   vec3 E = normalize(-v);
   vec3 R = normalize(reflect(-L,N)); 

   ambient = ambientMat;
   diffuse = clamp( diffuseMat * max(dot(N,L), 0.0)  , 0.0, 1.0 ) ;
   spec = clamp ( specMat * pow(max(dot(R,E),0.0),0.3*specPow) , 0.0, 1.0 );

   color = ambient + diffuse; // + spec;

}