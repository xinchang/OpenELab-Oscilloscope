//
//  OELDrawText.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 24/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OELDrawingTree.h"
#import "OELPlotData.h"
#import "OELTextShader.h"
#import "OELTextUtility.h"
@interface OELDrawText : OELTextUtility<OELDrawingTreeDelegate>
{

    OELDrawingTree *drawingTree;
    id<OELShaderUtilityDelegate> shader;
    
}
@property(nonatomic,readwrite) OELDrawingTree* drawingTree;
@property(nonatomic,readwrite)    NSString* str;

-(id)init:(NSString*) s;

@end

