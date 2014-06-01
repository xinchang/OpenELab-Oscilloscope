//
//  OELTextUtility.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 31/05/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "freetype-gl.h"
#import "text-buffer.h"
#import "mat4.h"
#import "shader.h"

#import "OELDraw.h"

@interface OELTextUtility : NSObject
{
    vec4 color;
    NSString* fontPath;
    NSString* text;
    vertex_buffer_t * textBuffer;
    vec2 origin;
    int fontSize;
    texture_atlas_t * atlas;
    texture_font_t * font;

}
@property(nonatomic,readonly)    vertex_buffer_t * textBuffer;
+(void) addText:(vertex_buffer_t *) buffer font:( texture_font_t * )font text:(wchar_t *)  text color:(vec4 * )color pen:(vec2 *) pen;

-(id) initWithText:(NSString*) t orginX:(float) x originY:(float) y font:(NSString *) fontName color:(UIColor *)c fontSize:(int) size ;
-(void) dealloc;

@end
