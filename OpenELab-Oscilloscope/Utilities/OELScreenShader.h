//
//  OELScreenShader.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 16/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELShaderUtility.h"

@interface OELScreenShader : OELShaderUtility<OELShaderUtilityDelegate>
{
    GLuint positionSlot;
    GLuint colorSlot;
}
@property(nonatomic,readonly)  GLuint positionSlot;
@property(nonatomic,readonly) GLuint colorSlot;

+(OELScreenShader* ) getSharedShader;
-(void)setProjections;
@end
