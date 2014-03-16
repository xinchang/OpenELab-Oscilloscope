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
//
        //initalise plot data
        for (int i=0; i< OELPD_DATA_CHANNEL; i++) {
            data[i] = OELPDInit(OELPD_DATA_LENGTH);
        }
        for (int i= 0; i<OELPD_DATA_LENGTH*4; i++) {
            fcolor_array[i]=1.0;
        }
        
        [self compileShaders];
		[self setupVBOs];
        
		[self setupView];
//		[self drawView];
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
    for (i=0; i<OELPD_DATA_LENGTH; i++) {
        data[0]->vertices[i].color[0] = 1.0;
        data[0]->vertices[i].color[1] = 1.0;
        data[0]->vertices[i].color[2] = 1.0;
        data[0]->vertices[i].color[3] = 1.0;
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
	
//	// Sets up matrices and transforms for OpenGL ES
//	glViewport(0, 0, backingWidth, backingHeight);
//	glMatrixMode(GL_PROJECTION);
//	glLoadIdentity();
//	glOrthof(0, backingWidth, 0, backingHeight, -1.0f, 1.0f);
//	glMatrixMode(GL_MODELVIEW);
	
	// Clears the view with black
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
//	glEnableClientState(GL_VERTEX_ARRAY);
	///glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
//    glDisable(GL_DITHER);
////    glDisable(GL_ALPHA_TEST);
//    glDisable(GL_BLEND);
//    glDisable(GL_STENCIL_TEST);
////    glDisable(GL_FOG);
//    glDisable(GL_TEXTURE_2D);
//    glDisable(GL_DEPTH_TEST);
    // Disable other state variables as appropriate.

	
}

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
}


float fcolor;
float tempf;
- (void)render:(CADisplayLink*)displayLink {
	
    [EAGLContext setCurrentContext:context];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    

    
    float aspect = fabsf(self.frame.size.width / self.frame.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0f), aspect, 5.0f, 10.0f);
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -7);
    int rotation = 90*gl_time/100;
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(rotation), GLKMathDegreesToRadians(rotation), GLKMathDegreesToRadians(rotation), 1);
    
    glUniformMatrix4fv(projectionUniform, 1, 0, projectionMatrix.m);
    glUniformMatrix4fv(modelViewUniform, 1, 0, modelViewMatrix.m);
    gl_time += 0.2;
    glUniform1f(gl_timeUniform, gl_time);
    
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
    
    
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
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

-(void)drawView
{
    // the NSTimer seems to fire one final time even though it's been invalidated
    // so just make sure and not draw if we're resigning active
    if (self.applicationResignedActive) return;

    // Make sure that you are drawing to the current context
	[EAGLContext setCurrentContext:context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
    
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
//
//
//- (void)drawOscilloscope
//{
//    
//    
//	// Clear the view
//	glClear(GL_COLOR_BUFFER_BIT);
//    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
//    glEnable(GL_BLEND);
//    
//    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//    glEnable(GL_DEPTH_TEST);
//    
////    CC3GLMatrix *projection = [CC3GLMatrix matrix];
//    float h = 4.0f * self.frame.size.height / self.frame.size.width;
////    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:10];
////    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
//
////	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
//	
////	glColor4f(1., 1., 1., 1.);
//	
////	glPushMatrix();
//	
////	glTranslatef(0., 480., 0.);
////	glRotatef(-90., 0., 0., 1.);
//	
//	
////	glEnable(GL_TEXTURE_2D);
////	glEnableClientState(GL_VERTEX_ARRAY);
////	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
//	
//	{
//		// Draw our background oscilloscope screen
//		const GLfloat vertices[] = {
//			0., 0.,
//			512., 0.,
//			0.,  512.,
//			512.,  512.,
//		};
//		const GLshort texCoords[] = {
//			0, 0,
//			1, 0,
//			0, 1,
//			1, 1,
//		};
//		
//		
////		glBindTexture(GL_TEXTURE_2D, bgTexture);
//		
////		glVertexPointer(2, GL_FLOAT, 0, vertices);
////		glTexCoordPointer(2, GL_SHORT, 0, texCoords);
//		
//		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//	}
//	
//	{
//		// Draw our buttons
//		const GLfloat vertices[] = {
//			0., 0.,
//			112, 0.,
//			0.,  64,
//			112,  64,
//		};
//		const GLshort texCoords[] = {
//			0, 0,
//			1, 0,
//			0, 1,
//			1, 1,
//		};
//		
////		glPushMatrix();
//		
////		glVertexPointer(2, GL_FLOAT, 0, vertices);
////		glTexCoordPointer(2, GL_SHORT, 0, texCoords);
//        
////		glTranslatef(5, 0, 0);
////		glBindTexture(GL_TEXTURE_2D, sonoTexture);
////		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
////		glTranslatef(99, 0, 0);
////		glBindTexture(GL_TEXTURE_2D, mute ? muteOnTexture : muteOffTexture);
//		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
////		glTranslatef(99, 0, 0);
////		glBindTexture(GL_TEXTURE_2D, (displayMode == aurioTouchDisplayModeOscilloscopeFFT) ? fftOnTexture : fftOffTexture);
//		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//		
////		glPopMatrix();
//		
//	}
//	
//	
//    int drawBufferLen = 1024;
//	GLfloat *oscilLine_ptr;
//	GLfloat max = drawBufferLen;
//	SInt8 *drawBuffer_ptr;
//
//    
//	// Alloc an array for our oscilloscope line vertices
////	if (resetOscilLine) {
//	GLfloat* oscilLine = (GLfloat*)malloc(drawBufferLen * 2 * sizeof(GLfloat));
//    //oscilLine = (GLfloat*)realloc(oscilLine, drawBufferLen * 2 * sizeof(GLfloat));
////		resetOscilLine = NO;
////	}
//	
////	glPushMatrix();
//	
//	// Translate to the left side and vertical center of the screen, and scale so that the screen coordinates
//	// go from 0 to 1 along the X, and -1 to 1 along the Y
////	glTranslatef(17., 182., 0.);
////	glScalef(448., 116., 1.);
//	
//	// Set up some GL state for our oscilloscope lines
//	glDisable(GL_TEXTURE_2D);
////	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
////	glDisableClientState(GL_COLOR_ARRAY);
////	glDisable(GL_LINE_SMOOTH);
//	glLineWidth(2.);
//	
//    int kNumDrawBuffers = 12;
//	int drawBuffer_i;
//    SInt8 *drawBuffers[kNumDrawBuffers];
//    
//	// Draw a line for each stored line in our buffer (the lines are stored and fade over time)
//	for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
//	{
//		if (!drawBuffers[drawBuffer_i]) continue;
//		
//		oscilLine_ptr = oscilLine;
//		drawBuffer_ptr = drawBuffers[drawBuffer_i];
//		
//		GLfloat i;
//		// Fill our vertex array with points
//		for (i=0.; i<max; i=i+1.)
//		{
//			*oscilLine_ptr++ = i/max;
//            Float32 f = sin(i/max*2*3.14);//(Float32)(*drawBuffer_ptr++) / 128.;
//			*oscilLine_ptr++ =f;
//		}
//		
//		// If we're drawing the newest line, draw it in solid green. Otherwise, draw it in a faded green.
////		if (drawBuffer_i == 0)
////			glColor4f(0., 1., 0., 1.);
////		else
////			glColor4f(0., 1., 0., (.24 * (1. - ((GLfloat)drawBuffer_i / (GLfloat)kNumDrawBuffers))));
//		
//		// Set up vertex pointer,
////		glVertexPointer(2, GL_FLOAT, 0, oscilLine);
//		
//		// and draw the line.
//		glDrawArrays(GL_LINE_STRIP, 0, drawBufferLen);
//		
//	}
//	
////	glPopMatrix();
//    
////	glPopMatrix();
//    
//    free(oscilLine);
//    
//}

@end
