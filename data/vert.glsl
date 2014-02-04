#define PROCESSING_LIGHT_SHADER

uniform vec4 ambientMat;
uniform vec4 diffuseMat;

//uniform mat4 modelview;
uniform mat4 transformMatrix;
uniform mat3 normalMatrix;

uniform vec4 lightPosition[8];
uniform vec3 lightDiffuse[8];
uniform vec3 lightAmbient[8];
uniform vec3 lightNormal[8];

attribute vec4 vertex;
attribute vec3 normal;
attribute vec4 ambient;

varying vec4 color;

void main()
{
	vec3 n;
	vec3 lightDir;
	vec4 diffuse;	
	vec4 amb;
	
	float NdotL;
	
	n = normalize(normalMatrix * normal);
	lightDir = -1.0 * normalize(lightNormal[0]);
	NdotL = max(dot(n, lightDir), 0.0);
	
	diffuse = diffuseMat * vec4(lightDiffuse[0], 1.0);

	amb = ambient * ambientMat * vec4(lightAmbient[1], 1.0);
	
	color = NdotL * diffuse + amb;
	
	gl_Position = transformMatrix * vertex;
}

