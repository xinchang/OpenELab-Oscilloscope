//
//  OELDrawCurve.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 23/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELDrawCurve.h"

@implementation OELDrawCurve
@synthesize drawingTree;
@synthesize lineWidth;
@synthesize data;
-(id)init:(int)length{
    if (self = [super init]) {
        drawingTree = [[OELDrawingTree alloc]initWithDelegate:self];
        data = OELPDInit(length);
        for (int i=0; i<length; i++) {
            data->vertices[i].point[0] = 0;
            data->vertices[i].point[1] = 0;
            data->vertices[i].point[2] = 0;
            data->vertices[i].color[3] = 1;
        }
        
        lineWidth =2;
        shader = [OELScreenShader getSharedShader];
        glGenBuffers(1, &bufferIndex);
    }
    return self;
}
-(void)dealloc
{
    glDeleteBuffers(1, &bufferIndex);
    OELPDRelease(data);
    
}
-(void)oELDraw{
    glBindBuffer(GL_ARRAY_BUFFER, bufferIndex);
    glBufferData(GL_ARRAY_BUFFER, sizeof(*(data->vertices))*data->length, data->vertices, GL_DYNAMIC_DRAW);
    glLineWidth(lineWidth);
    [shader setProjections];
    glDrawArrays(GL_LINE_STRIP, 0, data->length);
    glBindBuffer( GL_ARRAY_BUFFER, 0 );
    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, 0 );
}
-(void)setcolorRed:(float) r Green:(float)g Blue:(float) b{
    for (int i=0; i<data->length; i++) {
        data->vertices[i].color[0] = r;
        data->vertices[i].color[1] = g;
        data->vertices[i].color[2] = b;
    }
}

-(void)setAlpha: (float)a{
    for (int i=0; i<data->length; i++) {
        data->vertices[i].color[3] = a;
    }
}
-(void)setZ: (float)z{
    for (int i=0; i<data->length; i++) {
        data->vertices[i].point[2] = z;
    }
}
@end
