//
//  OELDrawCurve.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 23/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OELDrawingTree.h"
#import "OELPlotData.h"
#import "OELScreenShader.h"

@interface OELDrawCurve : NSObject<OELDrawingTreeDelegate>
{
    OELPlotData *data;
    OELDrawingTree *drawingTree;
    id<OELShaderUtilityDelegate> shader;
    GLuint bufferIndex;
    
    float lineWidth;
}
@property(nonatomic,readwrite) OELDrawingTree* drawingTree;
@property(nonatomic,readwrite)  float lineWidth;
@property(atomic,readwrite)  OELPlotData *data;;

-(id)init:(int)length;
-(void)oELDraw;

-(void)setcolorRed:(float) r Green:(float)g Blue:(float) b;
-(void)setAlpha: (float)a;
-(void)setZ: (float)z;
@end

