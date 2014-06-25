//
//  OELDrawAxis.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 02/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OELDrawingTree.h"
#import "OELTextUtility.h"
#import "OELTextShader.h"
#import "OELScreenShader.h"
#import "OELDrawLine.h"
#import "OELAxisUtility.h"
#import "OELPlotData.h"
#import "OELDrawCurve.h"
#import "OELDrawText.h"

@interface OELDrawAxis : NSObject<OELDrawingTreeDelegate>
{
    OELDrawingTree* drawingTree;
    OELTextShader* textShader;
    OELScreenShader* screenShader;
    OELDrawCurve *frame;
    OELAxisUtility *axisUtility;
    
    OELDrawLine* xReferences[11];
    OELDrawLine* yReferences[11];
    
    OELDrawText* text;
    OELDrawText* xUnitLabel;
    OELDrawText* yUnitLabel;
    OELDrawText* xLabels[11];
    OELDrawText* yLabels[11];

    
    
}
@property(nonatomic,readwrite) OELDrawingTree* drawingTree;

-(id)init;
//-(void)dealloc;
-(void)oELDraw;
-(void)updateAxis;

@end
