varying vec4 color;

void main()
{
  gl_FragColor = color;
  gl_FragColor[3] = 1.0;
  
}