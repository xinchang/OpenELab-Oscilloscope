//
//  OELChannel.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 24/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OELTextUtility.h"
#import "OELTextShader.h"
#import "OELScreenShader.h"
#import "OELDrawLine.h"
#import "OELAxisUtility.h"
#import "OELDrawCurve.h"
//#import "OELDrawText.h"

#define OELCHANNEL_MAX_LENGTH 65536
@interface OELChannel : NSObject<OELDrawingTreeDelegate>{
    OELDrawingTree* drawingTree;
    OELTextShader* textShader;
    OELScreenShader* screenShader;
    OELDrawCurve *curve;
    OELAxisUtility *axisUtility;

    BOOL dataUpdated;
    float generatedData[OELCHANNEL_MAX_LENGTH];
    float timeStamp;
    float xDiv;
    float yDiv;
    float xOffset;
    float yOffset;
    
//    OELDrawLine* xReferences[11];
//    OELDrawLine* yReferences[11];

//    OELDrawText* text;
}

@property(nonatomic,readwrite)  OELDrawingTree* drawingTree;
@property(nonatomic,readwrite)  float xDiv;
@property(nonatomic,readwrite)  float yDiv;
@property(nonatomic,readwrite)  float xOffset;
@property(nonatomic,readwrite)  float yOffset;

-(id)init;
-(void)loadData:(float*)pF;
-(void)oELDraw;
-(void)timerUpdated:sender;

@end
