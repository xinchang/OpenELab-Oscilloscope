uniform sampler2D texture;
varying lowp vec4 frontColor;
varying lowp vec2 texCoord;
void main()
{
    lowp float  a = texture2D(texture, texCoord).r;
    gl_FragColor = vec4(frontColor.rgb, frontColor.a*a);
}
