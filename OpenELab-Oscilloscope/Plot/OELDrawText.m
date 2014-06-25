//
//  OELDrawText.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 24/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELDrawText.h"

@implementation OELDrawText
@synthesize drawingTree;
@synthesize str;

-(id)init:(NSString*) s{
    if (self = [super initWithText:s orginX:0 originY:0 font:nil color:[UIColor blackColor] fontSize:50]) {
        drawingTree = [[OELDrawingTree alloc]initWithDelegate:self];
        shader = [OELTextShader getSharedShader];
    
    }
    return self;
}


-(void)oELDraw{
    [shader setProjections];
    vertex_buffer_render( textBuffer, GL_TRIANGLES );
}




@end
