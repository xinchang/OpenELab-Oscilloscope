//
//  OELPlotView.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 07/03/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELPlotView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>

#import <stdio.h>

#import "freetype-gl.h"
#import "mat4.h"
#import "shader.h"

#import "OELTextShader.h"
#import "OELScreenShader.h"



#define USE_DEPTH_BUFFER 1

@implementation OELPlotView
@synthesize applicationResignedActive;
// You must implement this method
float gl_time;
float fcolor_array[OELPD_DATA_LENGTH*4];

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
		// Get the layer
		eaglLayer = (CAEAGLLayer*) self.layer;
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!context) {
            NSLog(@"Failed to initialize OpenGLES 3.0 context");
            return nil;
        }
		if(![EAGLContext setCurrentContext:context]) {
            NSLog(@"Failed to set current OpenGL context");
			return nil;
		}
		if(![self createFramebuffer]) {
            NSLog(@"Failed to create frame buffer");
			return nil;
		}
        
        [self compileShaders];
//        UIButton* aButton = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 100)];
//        [aButton setTitle:@"HAHA" forState:UIControlStateNormal];
//        [self addSubview:aButton];
        
        drawingTree = [[OELDrawingTree alloc]initWithDelegate:self];
        drawAxis = [[OELDrawAxis alloc]init];
        [[drawingTree children]addObject:[drawAxis drawingTree]];
        
        channel = [[OELChannel alloc]init];
        [[drawingTree children]addObject:[channel drawingTree]];
        
        //gestures
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipe:)];
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongPress:)];

        
        [self addGestureRecognizer:pinchGesture];
        [self addGestureRecognizer:swipeGesture];
        [self addGestureRecognizer:longPressGesture];
        
    }
	gl_time = 0;
	return self;
    

}
- (void)dealloc
{
    for (int i=0; i< OELPD_DATA_CHANNEL; i++) {
        OELPDRelease(data[i]);
    }
    [self destroyFramebuffer];
//    OELPDRelease(data);
}

- (void)compileShaders{
    [[OELScreenShader getSharedShader ]compileAndLoadShader:@"Vertex.glsl" Fragment:@"Fragment.glsl"];
    [[OELTextShader getSharedShader ]compileAndLoadShader:@"v3f-t2f-c4f.vert" Fragment:@"v3f-t2f-c4f.frag"];
    
    float aspect = fabsf(self.frame.size.width / self.frame.size.height);
    [[OELTextShader getSharedShader] setAspect:aspect];
    [[OELScreenShader getSharedShader] setAspect:aspect];
    

}

- (BOOL)createFramebuffer
{
    glGenFramebuffers(1, &viewFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    
	glGenRenderbuffers(1, &viewRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
    
//    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, backingWidth, backingHeight);
	
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if(USE_DEPTH_BUFFER) {
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
    }
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;
    if(status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", status);
        return NO;
    }

    //Generate our MSAA Frame and Render buffers
    glGenFramebuffers(1, &msaaFramebuffer);
    glGenRenderbuffers(1, &msaaRenderBuffer);
    
    //Bind our MSAA buffers
    glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, msaaRenderBuffer);
    
    // Generate the msaaDepthBuffer.
    // 4 will be the number of pixels that the MSAA buffer will use in order to make one pixel on the render buffer.
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_RGBA8_OES, backingWidth, backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, msaaRenderBuffer);

    //Bind the msaa depth buffer.
    glGenRenderbuffers(1, &msaaDepthBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, msaaDepthBuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, 4, GL_DEPTH_COMPONENT16, backingWidth , backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, msaaDepthBuffer);
    
    status = glCheckFramebufferStatus(GL_FRAMEBUFFER) ;
    if(status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", status);
        return NO;
    }
	return YES;
}
- (void)destroyFramebuffer
{
	glDeleteFramebuffers(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffers(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer) {
		glDeleteRenderbuffers(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
}


- (void)render:(CADisplayLink*)displayLink {
	//Clear
    [EAGLContext setCurrentContext:context];
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    glEnable( GL_BLEND );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    glEnable( GL_TEXTURE_2D );


    [drawingTree drawTree];

    
    //MSAA
    // To discard depth render buffer contents whenever is possible
    const GLenum discards[]  = {GL_COLOR_ATTACHMENT0,GL_DEPTH_ATTACHMENT};
    glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE,2,discards);
    
    //Bind both MSAA and View FrameBuffers.
    glBindFramebufferOES(GL_READ_FRAMEBUFFER_APPLE, msaaFramebuffer);
    glBindFramebufferOES(GL_DRAW_FRAMEBUFFER_APPLE, viewFramebuffer);
    
    // Call a resolve to combine both buffers
    glResolveMultisampleFramebufferAPPLE();
    
    // Present final image to screen
    glBindRenderbufferOES(GL_RENDERBUFFER, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
    
}
//- (GLuint)setupTexture:(NSString *)fileName {
//    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
//    if (!spriteImage) {
//        NSLog(@"Failed to load image %@", fileName);
//        exit(1);
//    }
//    
//    size_t width = CGImageGetWidth(spriteImage);
//    size_t height = CGImageGetHeight(spriteImage);
//    
////    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
//    GLubyte * spriteData = (GLubyte *) malloc(width*height*4);
//    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
//                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
//    
//    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
//    
//    CGContextRelease(spriteContext);
//    
//    GLuint texName;
//    glGenTextures(1, &texName);
//    glBindTexture(GL_TEXTURE_2D, texName);
//    
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
//    
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
//    
//    free(spriteData);        
//    return texName;    
//}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


- (void)startAnimation
{
    [self setupDisplayLink];
}

- (void)stopAnimation
{

}



-(void)oELDraw
{
    
}
-(OELDrawingTree*) getOELDrawingTree
{
    return drawingTree;
}

//Handle gestures
-(void)handlePinch:(UIPinchGestureRecognizer*)sender {
    
//    NSLog(@"latscale = %f",mLastScale);
    if (sender.state == UIGestureRecognizerStateBegan) {
        lastXDiv = [channel xDiv];
    }
    
    float f = [sender scale];
    [channel setXDiv:lastXDiv*f ];
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        f=1;
    }
    NSLog(@"Scale: %f", f);
}
-(void)handleSwipe:(UISwipeGestureRecognizer*)sender {
    NSLog(@"Direction : %d", [sender direction]);
}

-(void)handleLongPress:(UILongPressGestureRecognizer*)sender {
    NSLog(@"Long press");
}

@end
