//
//  OELTextShader.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 16/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELShaderUtility.h"

@interface OELTextShader : OELShaderUtility<OELShaderUtilityDelegate>


+(OELTextShader* ) getSharedShader;
-(void)setProjections;
@end
