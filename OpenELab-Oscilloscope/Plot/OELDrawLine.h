//
//  OELDrawLine.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 16/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OELDrawingTree.h"
#import "OELPlotData.h"
#import "OELScreenShader.h"
#import "OELShaderUtility.h"
#define OELDL_DATA_LENGTH 2

@interface OELDrawLine :  NSObject<OELDrawingTreeDelegate>
{
    OELPlotData *data;
    OELDrawingTree *drawingTree;
    id<OELShaderUtilityDelegate> shader;
    GLuint bufferIndex;
    
    float lineWidth;
}
@property(nonatomic,readwrite) OELDrawingTree* drawingTree;
@property(nonatomic,readwrite)  float lineWidth;

-(id)init;
-(void)oELDraw;
-(void)setX1:(float) x1 Y1:(float )y1 X2:(float) x2 Y2:(float)y2;
-(void)setX1:(float) x1 Y1:(float )y1 Z1:(float) z1 X2:(float) x2 Y2:(float)y2 Z2:(float)z2;
-(void)setColorRed:(float) r Green:(float)g Blue:(float) b;
-(void)setColor:(UIColor*) c;
-(void)setAlpha: (float)a;
-(void)setZ: (float)z;
@end
