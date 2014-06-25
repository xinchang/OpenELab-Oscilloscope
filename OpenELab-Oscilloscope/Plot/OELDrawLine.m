//
//  OELDrawLine.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 16/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELDrawLine.h"


@implementation OELDrawLine
@synthesize drawingTree;
@synthesize lineWidth;
-(id)init{
    if((self = [super init])) {
        drawingTree = [[OELDrawingTree alloc]initWithDelegate:self];
        data = OELPDInit(2);
        data->vertices[0].point[0] = 0;
        data->vertices[0].point[1] = 0;
        data->vertices[0].point[2] = 0;
        data->vertices[0].color[3] = 1;
        
        data->vertices[1].point[0] = 0;
        data->vertices[1].point[1] = 0;
        data->vertices[1].point[2] = 0;
        data->vertices[1].color[3] = 1;
        
        lineWidth =2;
        shader = [OELScreenShader getSharedShader];
        glGenBuffers(1, &bufferIndex);
        
    }
    return  self;
}
-(void)dealloc
{
    glDeleteBuffers(1, &bufferIndex);
    OELPDRelease(data);

}
-(void)oELDraw{
    
//    [shader setProjections];
    glBindBuffer(GL_ARRAY_BUFFER, bufferIndex);
    glBufferData(GL_ARRAY_BUFFER, sizeof(*(data->vertices))*data->length, data->vertices, GL_DYNAMIC_DRAW);
    
    glLineWidth(lineWidth);
//    glEnable(GL_LINE_SMOOTH);
//    glHint(GL_LINE_SMOOTH, GL_NICEST);
    
    [shader setProjections];
    glDrawArrays(GL_LINE_STRIP, 0, 2);
    
//    glDrawArrays(GL_LINE_STRIP, 0, (int)data->length );
    
    glBindBuffer( GL_ARRAY_BUFFER, 0 );
    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, 0 );
    
}
-(void)setX1:(float) x1 Y1:(float )y1 X2:(float) x2 Y2:(float)y2
{
    data->vertices[0].point[0] = x1;
    data->vertices[0].point[1] = y1;
    
    data->vertices[1].point[0] = x2;
    data->vertices[1].point[1] = y2;
}
-(void)setX1:(float) x1 Y1:(float )y1 Z1:(float) z1 X2:(float) x2 Y2:(float)y2 Z2:(float)z2
{
    data->vertices[0].point[0] = x1;
    data->vertices[0].point[1] = y1;
    data->vertices[0].point[2] = z1;
    
    
    data->vertices[1].point[0] = x2;
    data->vertices[1].point[1] = y2;
    data->vertices[1].point[2] = z2;
    
}
-(void)setColor:(UIColor*) c{
    const CGFloat* colorRef = CGColorGetComponents( c.CGColor );
    [self setColorRed:colorRef[0] Green:colorRef[1] Blue:colorRef[2]];
    [self setAlpha:colorRef[3]];
}

-(void)setColorRed:(float) r Green:(float)g Blue:(float) b
{
    data->vertices[0].color[0] = r;
    data->vertices[0].color[1] = g;
    data->vertices[0].color[2] = b;
    
    
    data->vertices[1].color[0] = r;
    data->vertices[1].color[1] = g;
    data->vertices[1].color[2] = b;
}
-(void)setAlpha: (float)a
{
    data->vertices[0].color[3] = a;
    data->vertices[1].color[3] = a;
}
-(void)setZ: (float)z
{
    data->vertices[0].point[2] = z;
    data->vertices[1].point[2] = z;
}

@end
