//
//  ESRenderer.m
//  OpenGL Texture Loader
//
//  Created by numata on 09/09/12.
//  Copyright Satoshi Numata 2009. All rights reserved.
//

#import "ESRenderer.h"


@implementation ESRenderer

// Create an ES 1.1 context
- (id) init
{
	if (self = [super init]) {
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context]) {
            [self release];
            return nil;
        }
		
		// Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
		glGenFramebuffersOES(1, &defaultFramebuffer);
		glGenRenderbuffersOES(1, &colorRenderbuffer);
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
        
        // Set up blending mode
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);        
        
        // Set up a model and textures
        mTestMode = 0;

        mCharaTex = [[SZGLTexture alloc] initWithName:@"chara.png"];
        mBallTex = [[SZGLTexture alloc] initWithName:@"white_ball_opt.png"];
        
        mBoxTex1 = [[SZGLTexture alloc] initWithName:@"white_box.png"];
        mBoxTex2 = [[SZGLTexture alloc] initWithName:@"color_box.png"];
        
        mPVRTexs[0] = [[SZGLTexture alloc] initWithName:@"chara_lin2.pvr"];
        mPVRTexs[1] = [[SZGLTexture alloc] initWithName:@"chara_lin4.pvr"];
        mPVRTexs[2] = [[SZGLTexture alloc] initWithName:@"chara_prc2.pvr"];
        mPVRTexs[3] = [[SZGLTexture alloc] initWithName:@"chara_prc4.pvr"];        
	}
	
	return self;
}

- (void) dealloc
{
    [mCharaTex release];
    [mBallTex release];

    [mBoxTex1 release];
    [mBoxTex2 release];

    [mPVRTexs[0] release];
    [mPVRTexs[1] release];
    [mPVRTexs[2] release];
    [mPVRTexs[3] release];
    
	// Tear down GL
	if (defaultFramebuffer)
	{
		glDeleteFramebuffersOES(1, &defaultFramebuffer);
		defaultFramebuffer = 0;
	}
    
	if (colorRenderbuffer)
	{
		glDeleteRenderbuffersOES(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
	
	// Tear down context
	if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	
	[context release];
	context = nil;
	
	[super dealloc];
}

- (void)drawMain
{
    // Update Model
    mAngle += 0.05f;
    
    // Draw View
    glClearColor(0.39f, 0.58f, 0.93f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (mTestMode == 0) {
        [mBallTex drawAtPoint:CGPointMake((320.0f-[mBallTex imageSize].width)/2, 300.0f) alpha:1.0f];
        for (int i = 0; i < 5; i++) {
            [mCharaTex drawAtPoint:CGPointMake(i*50, 0) alpha:(i+1)/5.0f];
        }
    }
    
    [mCharaTex drawAtPoint:CGPointMake(320.0f/2, 460.0f/2)
                sourceRect:CGRectZero
                  rotation:mAngle
                    origin:[mCharaTex centerPoint]
                     scale:CGSizeMake(1.4f, 1.4f)
                     alpha:1.0f];    
    
    if (mTestMode == 1) {
        [mPVRTexs[0] drawAtPoint:CGPointMake(10, 240)];
        [mPVRTexs[1] drawAtPoint:CGPointMake(170, 240)];
        [mPVRTexs[2] drawAtPoint:CGPointMake(10, 0)];
        [mPVRTexs[3] drawAtPoint:CGPointMake(170, 0)];
    }
    
    if (mTestMode == 2) {
        [mBoxTex1 drawInRect:CGRectMake(10, 10, 128, 128)];
        [mBoxTex2 drawInRect:CGRectMake(10, 10+128+10, 128, 128)];
    }
}

- (void)render
{
    [EAGLContext setCurrentContext:context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(0.0f, 320.0f, 0.0f, 480.0f, -1.0f, 1.0f);
    glMatrixMode(GL_MODELVIEW);
    
    [self drawMain];
	
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer
{	
	// Allocate color buffer backing based on the current layer size
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}

- (void)changeTestMode
{
    mTestMode++;
    if (mTestMode == 3) {
        mTestMode = 0;
    }
}

@end
