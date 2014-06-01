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
        UIButton* aButton = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 100)];
        [aButton setTitle:@"HAHA" forState:UIControlStateNormal];
        [self addSubview:aButton];
        
        drawingTree = [[OELDrawingTree alloc]init];
        
        
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

    NSString* vertPath = [[NSBundle mainBundle] pathForResource:@"Vertex"
                                                         ofType:@"glsl"];
    NSString* fragPath = [[NSBundle mainBundle] pathForResource:@"Fragment"
                                                         ofType:@"glsl"];
    lineProgramHandle = shader_load([vertPath cStringUsingEncoding:NSUTF8StringEncoding],
                [fragPath cStringUsingEncoding:NSUTF8StringEncoding]);
    

    vertPath = [[NSBundle mainBundle] pathForResource:@"v3f-t2f-c4f"
                                                         ofType:@"vert"];
    fragPath = [[NSBundle mainBundle] pathForResource:@"v3f-t2f-c4f"
                                                         ofType:@"frag"];
    textProgramHandle = shader_load( [vertPath cStringUsingEncoding:NSUTF8StringEncoding],
                                    [fragPath cStringUsingEncoding:NSUTF8StringEncoding]);
    

}
-(void) switchProgram:(OELP_PROGRAM) program{
    switch(program){
        case LINE_PROGRAM:
            glUseProgram(lineProgramHandle);
            
            positionSlot = glGetAttribLocation(lineProgramHandle, "Position");
            colorSlot = glGetAttribLocation(lineProgramHandle, "SourceColor");
            projectionUniform = glGetUniformLocation(lineProgramHandle, "Projection");
            modelViewUniform = glGetUniformLocation(lineProgramHandle, "Modelview");
            gl_timeUniform = glGetUniformLocation(lineProgramHandle, "time");
            
            glEnableVertexAttribArray(positionSlot);
            glEnableVertexAttribArray(colorSlot);
            break;
    
        case TEXT_PROGRAM:
            
            break;
    }
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

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
}


- (void)render:(CADisplayLink*)displayLink {
	//Clear
    [EAGLContext setCurrentContext:context];
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    glEnable( GL_BLEND );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    glEnable( GL_TEXTURE_2D );
 
    [drawingTree drawTree];
    
//    //choose program
//    [self switchProgram:LINE_PROGRAM];
//    //Init matrix
//    float aspect = fabsf(self.frame.size.width / self.frame.size.height);
//
//    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0f), aspect, 5.0f, 10.0f);
//    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -7);
//    int rotation = 90*gl_time/100;
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(rotation), GLKMathDegreesToRadians(rotation), GLKMathDegreesToRadians(rotation), 1);
//    
//    glUniformMatrix4fv(projectionUniform, 1, 0, projectionMatrix.m);
//    glUniformMatrix4fv(modelViewUniform, 1, 0, modelViewMatrix.m);
//    gl_time += 0.02;
//    glUniform1f(gl_timeUniform, gl_time);
//    
//    //draw the 1st line
//    float f;
//    for (int i=0; i<OELPD_DATA_LENGTH; i++) {
//        f = (float)i/(OELPD_DATA_LENGTH)*4-2;
//        data[0]->vertices[i].point[0] = 2*f;
//        data[0]->vertices[i].point[1] = sinf(f+gl_time);
//        data[0]->vertices[i].point[2] = 0.2;
//        data[0]->vertices[i].color[1] = 0.5*sinf(f+gl_time)+0.5;
//    }
//    int i =0;
//    
//    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer[i]);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(*data[i]->vertices)*data[i]->length, data[i]->vertices, GL_DYNAMIC_DRAW);
//    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
//    glVertexAttribPointer(colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
//
//    
//    glLineWidth(2.0f);
//    glEnable(GL_LINE_SMOOTH);
//    glHint(GL_LINE_SMOOTH, GL_NICEST);
//    glDrawArrays(GL_LINE_STRIP, 0, (int)data[0]->length);
//    
//    //draw the second line
//     i=0;
//    data[1]->vertices[i].point[0] = 0.5;
//    data[1]->vertices[i].point[1] = 0.5;
//    data[1]->vertices[i].point[2] = 0;
//    i=1;
//    data[1]->vertices[i].point[0] = 0.5;
//    data[1]->vertices[i].point[1] = -0.5;
//    data[1]->vertices[i].point[2] = 0;
//    i=2;
//    data[1]->vertices[i].point[0] = -0.5;
//    data[1]->vertices[i].point[1] = -0.5;
//    data[1]->vertices[i].point[2] = 0;
//    i=3;
//    data[1]->vertices[i].point[0] = -0.5;
//    data[1]->vertices[i].point[1] = 0.5;
//    data[1]->vertices[i].point[2] = 0;
//    
//    i =1;
//    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer[i]);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(*data[i]->vertices)*data[i]->length, data[i]->vertices, GL_DYNAMIC_DRAW);
//    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
//    glVertexAttribPointer(colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
//
//    mat4 model, view, projection;
//    mat4_set_identity( &projection );
//    mat4_set_identity( &model );
//    mat4_set_identity( &view );
//   
////
//    projectionMatrix = GLKMatrix4MakeScale(0.1, aspect*0.1, 0.1);
//    modelViewMatrix = GLKMatrix4Identity;
//    glUniformMatrix4fv(projectionUniform, 1, 0, projectionMatrix.m);
//    glUniformMatrix4fv(modelViewUniform, 1, 0, model.data);
//    
//    glDrawArrays(GL_LINE_STRIP, 0, (int)data[i]->length);
//
//   //    glDrawElements(GL_TRIANGLE_STRIP, text_buffer->vertices->size, GL_UNSIGNED_BYTE, 0);
//    
//    [self switchProgram:TEXT_PROGRAM];
//    
//    projectionMatrix = GLKMatrix4MakeScale(0.001, aspect*0.001, 0.001);
//    glUseProgram( textProgramHandle );
//    {
//        glUniform1i( glGetUniformLocation( textProgramHandle, "texture" ),
//                    0 );
//        glUniformMatrix4fv( glGetUniformLocation( textProgramHandle, "model" ),
//                           1, 0, model.data);
//        glUniformMatrix4fv( glGetUniformLocation( textProgramHandle, "view" ),
//                           1, 0, view.data);
//        glUniformMatrix4fv( glGetUniformLocation( textProgramHandle, "projection" ),
//                           1, 0, projectionMatrix.m);
////        @autoreleasepool {
////            OELTextUtility *text = [[OELTextUtility alloc]initWithText:@"Hello" orginX:0 originY:0 font:nil color:nil fontSize:nil];
//            NSString *str = [NSString stringWithFormat:@"ABC %f",gl_time ];
//            text = [[OELTextUtility alloc]initWithText:str orginX:0 originY:0 font:nil color:[UIColor brownColor] fontSize:0];
//            vertex_buffer_render( [text textBuffer], GL_TRIANGLES );
//            str = [NSString stringWithFormat:@"%f XYZ",gl_time ];
//            text = [[OELTextUtility alloc]initWithText:str orginX:20 originY:20 font:nil color:[UIColor brownColor] fontSize:80];
//            vertex_buffer_render( [text textBuffer], GL_TRIANGLES );
////        }
//    }

    
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

@end
