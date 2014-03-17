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
        //initalise plot data
        for (int i=0; i< OELPD_DATA_CHANNEL; i++) {
            data[i] = OELPDInit(OELPD_DATA_LENGTH);
        }
        for (int i= 0; i<OELPD_DATA_LENGTH*4; i++) {
            fcolor_array[i]=1.0;
        }
        
        [self compileShaders];
		[self setupVBOs];
}
	gl_time = 0;
	return self;
    

}
- (void)dealloc
{
    for (int i=0; i< OELPD_DATA_CHANNEL; i++) {
        OELPDRelease(data[i]);
    }
//    OELPDRelease(data);
}
- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
    
}
- (void)compileShaders {
    
    GLuint vertexShader = [self compileShader:@"Vertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"Fragment"
                                       withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    //Check errors
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    positionSlot = glGetAttribLocation(programHandle, "Position");
    colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    projectionUniform = glGetUniformLocation(programHandle, "Projection");
    modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
    gl_timeUniform = glGetUniformLocation(programHandle, "time");
    
    glEnableVertexAttribArray(positionSlot);
    glEnableVertexAttribArray(colorSlot);

}
- (void)setupVBOs {
    
    
    int i;
    for (int j=0; j<OELPD_DATA_CHANNEL; j++) {
        
        for (i=0; i<OELPD_DATA_LENGTH; i++) {
            data[j]->vertices[i].color[0] = 1.0;
            data[j]->vertices[i].color[1] = 1.0;
            data[j]->vertices[i].color[2] = 1.0;
            data[j]->vertices[i].color[3] = 1.0;
            
        }
    }
    for (i=0; i<OELPD_DATA_CHANNEL; i++) {
        glGenBuffers(1, vertexBuffer+i);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer[i]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(*data[i]->vertices)*data[i]->length, data[i]->vertices, GL_DYNAMIC_DRAW);
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
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
- (void)setupView
{
	
	
}

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
}


float fcolor;
float tempf;
- (void)render:(CADisplayLink*)displayLink {
	//Clear
    [EAGLContext setCurrentContext:context];
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    
    //Init matrix
    float aspect = fabsf(self.frame.size.width / self.frame.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0f), aspect, 5.0f, 10.0f);
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -7);
    int rotation = 90*gl_time/100;
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(rotation), GLKMathDegreesToRadians(rotation), GLKMathDegreesToRadians(rotation), 1);
    
    glUniformMatrix4fv(projectionUniform, 1, 0, projectionMatrix.m);
    glUniformMatrix4fv(modelViewUniform, 1, 0, modelViewMatrix.m);
    gl_time += 0.02;
    glUniform1f(gl_timeUniform, gl_time);
    
    //draw the 1st line
    float f;
    for (int i=0; i<OELPD_DATA_LENGTH; i++) {
        f = (float)i/(OELPD_DATA_LENGTH)*4-2;
        data[0]->vertices[i].point[0] = 2*f;
        data[0]->vertices[i].point[1] = sinf(f+gl_time);
        data[0]->vertices[i].point[2] = 0.2;
        data[0]->vertices[i].color[1] = 0.5*sinf(f+gl_time)+0.5;
    }
    int i =0;
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer[i]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(*data[i]->vertices)*data[i]->length, data[i]->vertices, GL_DYNAMIC_DRAW);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));

    
    glLineWidth(2.0f);
    glEnable(GL_LINE_SMOOTH);
    glHint(GL_LINE_SMOOTH, GL_NICEST);
    glDrawArrays(GL_LINE_STRIP, 0, data[0]->length);
    
    //draw the second line
     i=0;
    data[1]->vertices[i].point[0] = 0.5;
    data[1]->vertices[i].point[1] = 0.5;
    data[1]->vertices[i].point[2] = 0;
    i=1;
    data[1]->vertices[i].point[0] = 0.5;
    data[1]->vertices[i].point[1] = -0.5;
    data[1]->vertices[i].point[2] = 0;
    i=2;
    data[1]->vertices[i].point[0] = -0.5;
    data[1]->vertices[i].point[1] = -0.5;
    data[1]->vertices[i].point[2] = 0;
    i=3;
    data[1]->vertices[i].point[0] = -0.5;
    data[1]->vertices[i].point[1] = 0.5;
    data[1]->vertices[i].point[2] = 0;
    
    i =1;
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer[i]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(*data[i]->vertices)*data[i]->length, data[i]->vertices, GL_DYNAMIC_DRAW);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));

    projectionMatrix = GLKMatrix4MakeScale(1, aspect, 1);
    modelViewMatrix = GLKMatrix4Identity;
    glUniformMatrix4fv(projectionUniform, 1, 0, projectionMatrix.m);
    glUniformMatrix4fv(modelViewUniform, 1, 0, modelViewMatrix.m);
    
    glDrawArrays(GL_LINE_STRIP, 0, data[i]->length);
    
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
- (GLuint)setupTexture:(NSString *)fileName {
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
//    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    GLubyte * spriteData = (GLubyte *) malloc(width*height*4);
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);        
    return texName;    
}

- (void)startAnimation
{
//	animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
//	animationStarted = [NSDate timeIntervalSinceReferenceDate];
    [self setupDisplayLink];
}

- (void)stopAnimation
{
	[animationTimer invalidate];
	animationTimer = nil;
}

- (void)setAnimationInterval:(NSTimeInterval)interval
{
	animationInterval = interval;
	
	if(animationTimer) {
		[self stopAnimation];
		[self startAnimation];
	}
}
@end
