attribute vec4 Position; //
attribute vec4 SourceColor; //

varying vec4 DestinationColor; //

uniform mat4 Projection;
uniform mat4 Modelview;
uniform float time;

void main(void) { //
    vec4 v = vec4(Position);
    DestinationColor = SourceColor; //
//    v.y += sin(time*v.y*0.5);
    gl_Position = Projection*Modelview*v; //
}