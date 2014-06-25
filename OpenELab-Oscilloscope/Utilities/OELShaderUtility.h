//
//  OELShaderUtility.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 02/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mat4.h"
#import <GLKit/GLKit.h>

@protocol OELShaderUtilityDelegate <NSObject>
-(void)setProjections;
@end

@interface OELShaderUtility : NSObject
{
    GLKMatrix4 projectionMatrix;
    GLKMatrix4 modelMatrix;
    GLKMatrix4 viewMatrix;
    
    
    GLuint projectionUniform;
    GLuint modelViewUniform;

    GLuint programHandle;
    
    float aspect;
    
}

@property(nonatomic,readwrite)float aspect;
@property(nonatomic,readwrite)    GLuint projectionUniform;
@property(nonatomic,readwrite)   GLuint modelViewUniform;
@property(nonatomic,readwrite) GLuint programHandle;

-(id)init;
//-(void)setProjections;
//-(void)setProjectionsWithHandle:(GLuint) handle ;
-(void) compileAndLoadShader:(NSString*) vertName Fragment:(NSString*) fragName;

@end
