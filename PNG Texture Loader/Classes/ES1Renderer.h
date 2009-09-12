//
//  ES1Renderer.h
//  PNG Texture Loader
//
//  Created by numata on 09/09/12.
//  Copyright Satoshi Numata 2009. All rights reserved.
//

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#import "SZGLTexture.h"


@interface ES1Renderer : NSObject
{
@private
	EAGLContext *context;
	
	// The pixel dimensions of the CAEAGLLayer
	GLint backingWidth;
	GLint backingHeight;
	
	// The OpenGL names for the framebuffer and renderbuffer used to render to this view
	GLuint defaultFramebuffer, colorRenderbuffer;

    float         mAngle;    
    SZGLTexture   *mCharaTex;
    SZGLTexture   *mBallTex;

    //SZGLTexture     *mTestTex;
}

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;

@end

