//
//  OELChannel.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 24/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELChannel.h"
@implementation OELChannel
@synthesize xDiv,yDiv,xOffset,yOffset;
@synthesize drawingTree;
-(id)init{
    if((self = [super init])) {
//        int i;
//        axisUtility = [[OELAxisUtility alloc]init];s
        drawingTree = [[OELDrawingTree alloc]initWithDelegate:self];
        textShader = [OELTextShader getSharedShader];
        screenShader = [OELScreenShader getSharedShader];
        xDiv = 0.0002;
        yDiv = 0.5;
        xOffset = -5;
        yOffset = 0;
        curve = [[OELDrawCurve alloc]init:OELCHANNEL_MAX_LENGTH];
        [curve setcolorRed:1 Green:0 Blue:0];
        [curve setLineWidth:1];
        [curve setZ:-0.5];
        [[drawingTree children] addObject:[curve drawingTree]];
        
        dataUpdated = NO;
        //        text = [[OELDrawText alloc]init:@"Hello OEL"];
        //        [text  setOriginX:-100 Y:-10];
        //        [text setColor:[UIColor redColor]];
        //        [text generateTextBuffer];
        //        [[drawingTree children] addObject:[text drawingTree]];
        [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerUpdated:) userInfo:nil repeats:YES];
    }
    return  self;
}

-(void)oELDraw{
    if (dataUpdated) {
        dataUpdated = NO;
        [self loadData:generatedData];
    }
}

-(void)timerUpdated:sender{
    timeStamp += 0.06;
    float dt = 0.06/OELCHANNEL_MAX_LENGTH;
    for (int i = 0; i<OELCHANNEL_MAX_LENGTH; i++) {
        generatedData[i] = yDiv*sinf(62832*dt*i)+yOffset + rand()/10.0/INT32_MAX;
    }
    dataUpdated = YES;
    
}
-(void)loadData:(float*)pF
{
    int i;
    int begin = (1-xOffset)/xDiv;
    begin = MIN(begin, OELCHANNEL_MAX_LENGTH);
    begin = MAX(begin, 0);
    
    int end = (3-xOffset)/xDiv;
    end = MIN(end,OELCHANNEL_MAX_LENGTH);
    end = MAX(end,0);
    
    OELPlotData* data = [curve data];
    for (i = 0; i<end-begin+1; i++) {
        data->vertices[i].point[0] = i*xDiv-1;
        data->vertices[i].point[1] = pF[begin+i]*yDiv;
    }
    data->length = end-begin+1;
}

@end
