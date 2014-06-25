//
//  OELScreenShader.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 16/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELScreenShader.h"
#import "OELPlotData.h"

@implementation OELScreenShader
@synthesize positionSlot,colorSlot;
+(OELScreenShader* ) getSharedShader{
    
    static OELScreenShader *sharedScreenShader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedScreenShader = [[self alloc] init];
    });
    return sharedScreenShader;
}

-(void)setProjections{
//    [super setProjections];
    
    glUseProgram( programHandle);
    
    projectionUniform = glGetUniformLocation(programHandle, "Projection");
    modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
    glGetUniformLocation(programHandle, "time");
    positionSlot = glGetAttribLocation(programHandle, "Position");
    colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    mat4 model, view, projection;
    mat4_set_identity( &projection );
    mat4_set_identity( &model );
    mat4_set_identity( &view );
    
    //
    projectionMatrix = GLKMatrix4MakeScale(1, aspect, 1);
    glUniformMatrix4fv(projectionUniform, 1, 0, projectionMatrix.m);
    glUniformMatrix4fv(modelViewUniform, 1, 0, model.data);
    glEnableVertexAttribArray(positionSlot);
    glEnableVertexAttribArray(colorSlot);
    

    
}


@end
