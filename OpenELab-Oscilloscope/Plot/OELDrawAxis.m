//
//  OELDrawAxis.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 02/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELDrawAxis.h"

#import "freetype-gl.h"


#import "OELPlotData.h"
@implementation OELDrawAxis
@synthesize drawingTree;
-(id)init{
    if((self = [super init])) {
        int i;
        axisUtility = [[OELAxisUtility alloc]init];
        drawingTree = [[OELDrawingTree alloc]initWithDelegate:self];
        textShader = [OELTextShader getSharedShader];
        screenShader = [OELScreenShader getSharedShader];
        frame = [[OELDrawCurve alloc]init:5];
        for (i=0; i<11; i++) {
            xReferences[i] = [[OELDrawLine alloc]init];
            yReferences[i] = [[OELDrawLine alloc]init];
            [xReferences[i] setColorRed:1 Green:1 Blue:1];
            [yReferences[i] setColorRed:1 Green:1 Blue:1];
            [xReferences[i] setAlpha:0.3];
            [yReferences[i] setAlpha:0.3];
            [xReferences[i] setZ:0.9];
            [yReferences[i] setZ:0.9];
            [xReferences[i] setLineWidth:0.5];
            [yReferences[i] setLineWidth:0.5];
            
        }
        
        [self updateAxis];
        
        [[drawingTree children] addObject:[frame drawingTree]];
        for (i=0; i<11; i++) {
             [[drawingTree children] addObject:[xReferences[i] drawingTree]];
             [[drawingTree children] addObject:[yReferences[i] drawingTree]];
        }
        

        
//        frame = [[OELDrawCurve alloc]init:8192];
//        [frame setAlpha:0.2];
//        [[drawingTree children] addObject:[frame drawingTree]];
        
        text = [[OELDrawText alloc]init:@"Hello OEL"];
        [text  setOriginX:-100 Y:-10];
        [text setColor:[UIColor redColor]];
        [text generateTextBuffer];
        [[drawingTree children] addObject:[text drawingTree]];
        
    }
    return  self;
}
-(void)oELDraw{
    OELPlotData* data;
    data = [frame data];
    for (int i=0; i<data->length; i++) {
        data->vertices[i].point[0] = -1+i/4096.0;
        data->vertices[i].point[1] = rand()*0.5/INT32_MAX;
    }
    

    [text setColor:[UIColor colorWithRed:rand()*0.9/INT32_MAX green:rand()*0.9/INT32_MAX blue:rand()*0.9/INT32_MAX alpha:1]];
    [text generateTextBuffer];
    
}
-(void)updateAxis{
    int i;
    float left = [axisUtility getLeftAxisCoordinate];
    float right = [axisUtility getRightAxisCoordinate];
    float top = [axisUtility getTopAxisCoordinate];
    float bottom = [axisUtility getBottomtAxisCoordinate];
    
    //Frame bound
    OELPlotData* data = [frame data];
    data->vertices[0].point[0] = left;
    
    data->vertices[0].point[1] = bottom;
    data->vertices[1].point[0] = right;
    data->vertices[1].point[1] = bottom;
    data->vertices[2].point[0] = right;
    data->vertices[2].point[1] = top;
    data->vertices[3].point[0] = left;
    data->vertices[3].point[1] = top;
    data->vertices[4].point[0] = left;
    data->vertices[4].point[1] = bottom;
    
    //Reference lines
    
    
    float* xR = [axisUtility getXAxisReferences];
    float* yR = [axisUtility getYAxisReferences];
    for (i=0; i<11; i++) {
        [xReferences[i] setX1:xR[i] Y1:bottom X2:xR[i] Y2:top];
        [yReferences[i] setX1:left Y1:yR[i] X2:right Y2:yR[i]];
    }

}

@end
