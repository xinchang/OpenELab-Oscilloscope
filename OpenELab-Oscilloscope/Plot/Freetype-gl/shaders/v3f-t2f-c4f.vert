uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

attribute vec3 vertex;
attribute vec2 tex_coord;
attribute vec4 color;
varying vec4 frontColor;
varying vec2 texCoord;
void main()
{
    texCoord = tex_coord;
    frontColor     = color;
    gl_Position       = projection*(view*(model*vec4(vertex,1.0)));
}
