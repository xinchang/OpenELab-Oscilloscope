//
//  OELTextShader.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 16/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELTextShader.h"

@implementation OELTextShader
+(OELTextShader* ) getSharedShader{
    static OELTextShader *sharedTextShader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTextShader = [[self alloc] init];
    });
    return sharedTextShader;
}

-(void)setProjections{
        glUseProgram( programHandle);
        glUniformMatrix4fv( glGetUniformLocation( programHandle, "model" ), 1, 0, modelMatrix.m);
        glUniformMatrix4fv( glGetUniformLocation( programHandle, "view" ), 1, 0, viewMatrix.m);
        glUniformMatrix4fv( glGetUniformLocation( programHandle, "projection" ), 1, 0, projectionMatrix.m);

    glUniform1i( glGetUniformLocation( programHandle, "texture" ),0 );
    
}

@end
