//
//  OELTextUtility.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 31/05/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELTextUtility.h"
#import <wchar.h>


@implementation OELTextUtility
@synthesize textBuffer;
// ------------------------------------------------------- typedef & struct ---
typedef struct {
    float x, y, z;    // position
    float s, t;       // texture
    float r, g, b, a; // color
} vertex_t;

typedef struct {
    float x, y, z;
    vec4 color;
} point_t;
// --------------------------------------------------------------- add_text ---
+(void) addText:(vertex_buffer_t *) buffer font:( texture_font_t * )font text:(wchar_t *)  text color:(vec4 * )color pen:(vec2 *) pen
{
    size_t i;
    float r = color->red, g = color->green, b = color->blue, a = color->alpha;
    for( i=0; i<wcslen(text); ++i )
    {
        texture_glyph_t *glyph = texture_font_get_glyph( font, text[i] );
        if( glyph != NULL )
        {
            int kerning = 0;
            if( i > 0)
            {
                kerning = texture_glyph_get_kerning( glyph, text[i-1] );
            }
            pen->x += kerning;
            int x0  = (int)( pen->x + glyph->offset_x );
            int y0  = (int)( pen->y + glyph->offset_y );
            int x1  = (int)( x0 + glyph->width );
            int y1  = (int)( y0 - glyph->height );
            float s0 = glyph->s0;
            float t0 = glyph->t0;
            float s1 = glyph->s1;
            float t1 = glyph->t1;
            GLuint indices[] = {0,1,2,0,2,3};
            vertex_t vertices[] = { { x0,y0,0,  s0,t0,  r,g,b,a },
                { x0,y1,0,  s0,t1,  r,g,b,a },
                { x1,y1,0,  s1,t1,  r,g,b,a },
                { x1,y0,0,  s1,t0,  r,g,b,a } };
            vertex_buffer_push_back( buffer, vertices, 4, indices, 6 );
            pen->x += glyph->advance_x;
        }
    }
}
+(void) updateText:(vertex_buffer_t *) buffer font:( texture_font_t * )font text:(wchar_t *)  text color:(vec4 * )color pen:(vec2) pen
{
    size_t i;
    float r = color->red, g = color->green, b = color->blue, a = color->alpha;
    for( i=0; i<wcslen(text); ++i )
    {
        texture_glyph_t *glyph = texture_font_get_glyph( font, text[i] );
        if( glyph != NULL )
        {
            int kerning = 0;
            if( i > 0)
            {
                kerning = texture_glyph_get_kerning( glyph, text[i-1] );
            }
            pen.x += kerning;
            int x0  = (int)( pen.x + glyph->offset_x );
            int y0  = (int)( pen.y + glyph->offset_y );
            int x1  = (int)( x0 + glyph->width );
            int y1  = (int)( y0 - glyph->height );
            float s0 = glyph->s0;
            float t0 = glyph->t0;
            float s1 = glyph->s1;
            float t1 = glyph->t1;
            GLuint indices[] = {0,1,2,0,2,3};
            vertex_t vertices[] = { { x0,y0,0,  s0,t0,  r,g,b,a },
                { x0,y1,0,  s0,t1,  r,g,b,a },
                { x1,y1,0,  s1,t1,  r,g,b,a },
                { x1,y0,0,  s1,t0,  r,g,b,a } };
            vertex_buffer_push_back( buffer, vertices, 4, indices, 6 );
            pen.x += glyph->advance_x;
        }
    }
}


-(id) initWithText:(NSString*) t orginX:(float) x originY:(float) y font:(NSString *) fontName color:(UIColor *)c fontSize:(int) size
{
    if((self = [super init])) {
        text = t;
        if(fontName)
            fontPath = [[NSBundle mainBundle] pathForResource:fontName ofType:@"ttf"];
        else
            fontPath = [[NSBundle mainBundle] pathForResource:@"Vera" ofType:@"ttf"];
        
        [self setColor:c];
        [self setFontSize:size];
        
        textBuffer  = vertex_buffer_new( "vertex:3f,tex_coord:2f,color:4f" );
        
        origin.x = x;
        origin.y = y;
        atlas = texture_atlas_new( 512, 512, 1);
        font = texture_font_new_from_file( atlas, fontSize, [fontPath cStringUsingEncoding:NSUTF8StringEncoding]);
        
        [self generateTextBuffer];
    }
    return self;
}
-(void) dealloc
{
    vertex_buffer_delete(textBuffer);
    texture_atlas_delete(atlas);
    texture_font_delete(font);
    
}

-(void)generateTextBuffer{
    
    vertex_buffer_clear(textBuffer);
    vec2 temp = origin;
    [OELTextUtility addText:textBuffer font:font text:(wchar_t*)[text cStringUsingEncoding:NSUTF32StringEncoding] color:&color pen:&temp];
}
-(void) setColor:(UIColor*)c{
    if (c) {
        const CGFloat* colorRef = CGColorGetComponents( c.CGColor );
        color.r = colorRef[0];
        color.g = colorRef[1];
        color.b = colorRef[2];
        color.a = colorRef[3];
    }
    else
    {
        color.r = 1;
        color.g = 0;
        color.b = 0;
        color.a = 1;
        
    }
}
-(void)setFontSize:(int)s{
    if (s) {
        fontSize = s;
    }
    else
        fontSize = 50;
}
-(void)setOriginX:(int)x Y:(int)y{
    origin.x=x;
    origin.y=y;
}
@end
