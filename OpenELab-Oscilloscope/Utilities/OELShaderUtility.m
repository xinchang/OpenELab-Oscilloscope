//
//  OELShaderUtility.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 02/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELShaderUtility.h"
#import "shader.h"

@implementation OELShaderUtility
@synthesize aspect;
@synthesize projectionUniform, modelViewUniform;
@synthesize programHandle;



-(id)init{
    if (self = [super init]) {
        aspect = 1/0.75;
        projectionMatrix = GLKMatrix4MakeScale(0.001, aspect*0.001, 0.001);
        modelMatrix = GLKMatrix4Identity;
        viewMatrix = GLKMatrix4Identity;
    }
    return self;
}

-(void) compileAndLoadShader:(NSString*) vertName Fragment:(NSString*) fragName
{
    NSString* name = [[vertName componentsSeparatedByString:@"."] firstObject];
    NSString* ext = [[vertName componentsSeparatedByString:@"."] lastObject];
    NSString* vertPath = [[NSBundle mainBundle] pathForResource:name ofType:ext];
    name = [[fragName componentsSeparatedByString:@"."] firstObject];
    ext = [[fragName componentsSeparatedByString:@"."] lastObject];
    NSString* fragPath = [[NSBundle mainBundle] pathForResource:name ofType:ext];
    programHandle = shader_load( [vertPath cStringUsingEncoding:NSUTF8StringEncoding], [fragPath cStringUsingEncoding:NSUTF8StringEncoding]);

}


@end
