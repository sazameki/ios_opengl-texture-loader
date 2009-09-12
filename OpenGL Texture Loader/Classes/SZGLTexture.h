//
//  SZGLTexture.h
//  Texture Loading Sample
//
//  Created by numata on 09/08/16.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


@interface SZGLTexture : NSObject {
    GLuint      mTextureName;
    CGSize      mImageSize;
    CGSize      mTextureSize;
}

- (id)initWithName:(NSString *)imageName;

- (CGSize)imageSize;
- (CGPoint)centerPoint;

- (void)drawAtPoint:(CGPoint)pos;
- (void)drawInRect:(CGRect)rect;

- (void)drawAtPoint:(CGPoint)pos alpha:(float)alpha;
- (void)drawInRect:(CGRect)rect alpha:(float)alpha;

- (void)drawAtPoint:(CGPoint)centerPos
         sourceRect:(CGRect)srcRect
           rotation:(float)rotation
             origin:(CGPoint)origin
              scale:(CGSize)scale
              alpha:(float)alpha;

@end
