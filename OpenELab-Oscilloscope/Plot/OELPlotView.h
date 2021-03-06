//
//  OELPlotView.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 07/03/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "OELPlotData.h"

#import "vertex-buffer.h"
#import "text-buffer.h"
#import "OELTextUtility.h"
#import "OELDrawingTree.h"
#import "OELDrawAxis.h"
#import "OELChannel.h"

#define OELPD_DATA_CHANNEL 2 //Data channel number
#define OELPD_DATA_LENGTH 1024*16 //Data length for one channel


typedef enum{
    LINE_PROGRAM,
    TEXT_PROGRAM
} OELP_PROGRAM;
@interface OELPlotView : UIView<OELDrawingTreeDelegate>
{
@private

    /* The pixel dimensions of the backbuffer */
    GLint backingWidth;
    GLint backingHeight;

    EAGLContext *context;
    CAEAGLLayer *eaglLayer;
    /* OpenGL names for the renderbuffer and framebuffers used to render to this view */
    GLuint viewRenderbuffer, viewFramebuffer;
    
    //Buffer definitions for the MSAA
    GLuint msaaFramebuffer,
    msaaRenderBuffer,
    msaaDepthBuffer;

    /* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
    GLuint depthRenderbuffer;

    /* OpenGL name for the sprite texture */
    // bgTexture is used in the app delegate
    //GLuint bgTexture;

    NSTimer *animationTimer;
    NSTimeInterval animationInterval;
    NSTimeInterval animationStarted;
    
    GLuint positionSlot;
    GLuint colorSlot;
    
    GLuint projectionUniform;
    GLuint modelViewUniform;
    GLuint gl_timeUniform;
    
    GLuint lineProgramHandle;
    GLuint textProgramHandle;
    
    vertex_buffer_t * text_buffer;
    OELTextUtility *text;
    OELDrawAxis *drawAxis;
    
    GLuint vertexBuffer[OELPD_DATA_CHANNEL];
    OELPlotData *data[OELPD_DATA_CHANNEL];
    OELPlotData *data2;
    
    BOOL applicationResignedActive;
    
    OELDrawingTree *drawingTree;
    OELChannel* channel;
    
    float lastXDiv;
}

- (void)startAnimation;
- (void)stopAnimation;

-(void)oELDraw;
-(OELDrawingTree*) getOELDrawingTree;

@property(assign) BOOL applicationResignedActive;

@end
