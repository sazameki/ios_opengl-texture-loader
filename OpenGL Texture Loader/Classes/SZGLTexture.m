//
//  SZGLTexture.m
//  Texture Loading Sample
//
//  Created by numata on 09/08/16.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "SZGLTexture.h"
#import "SZGLTextureLoader.h"


@implementation SZGLTexture

- (id)initWithName:(NSString *)imageName
{
    self = [super init];
    if (self) {
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
        if (imagePath) {
            mTextureName = SZGLLoadTexture(imagePath, &mImageSize, &mTextureSize);
            if (mTextureName == GL_INVALID_VALUE) {
                NSLog(@"Failed to load %@", imagePath);
                [self release];
                return nil;
            }
        } else {
            NSLog(@"Image file does not exist: %@", imageName);
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    if (mTextureName != GL_INVALID_VALUE) {
        glDeleteTextures(1, &mTextureName);
    }
    [super dealloc];
}

- (CGSize)imageSize
{
    return mImageSize;
}

- (CGPoint)centerPoint
{
    return CGPointMake(mImageSize.width / 2, mImageSize.height / 2);
}

- (void)drawAtPoint:(CGPoint)pos
{
    [self drawAtPoint:pos alpha:1.0f];
}

- (void)drawAtPoint:(CGPoint)pos
              alpha:(float)alpha
{
    [self drawInRect:CGRectMake(pos.x, pos.y, mImageSize.width, mImageSize.height) alpha:alpha];
}

- (void)drawInRect:(CGRect)rect
{
    [self drawInRect:rect alpha:1.0f];
}

- (void)drawInRect:(CGRect)rect
             alpha:(float)alpha
{
    CGSize scale = CGSizeMake(rect.size.width / mImageSize.width, rect.size.height / mImageSize.height);
    [self drawAtPoint:rect.origin
           sourceRect:CGRectZero
             rotation:0.0f
               origin:CGPointZero
                scale:scale
                alpha:alpha];
}

typedef struct {
    GLshort vertex_x, vertex_y;
    GLfloat texCoord_x, texCoord_y;
} GLTextureDrawData;

- (void)drawAtPoint:(CGPoint)centerPos
         sourceRect:(CGRect)srcRect
           rotation:(float)rotation
             origin:(CGPoint)origin
              scale:(CGSize)scale
              alpha:(float)alpha
{
    GLTextureDrawData drawData[6];

    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, mTextureName);

    CGRect theSrcRect = srcRect;
    if (srcRect.size.width == 0.0f && srcRect.size.height == 0.0f) {
        theSrcRect.origin.x = 0.0f;
        theSrcRect.origin.y = 0.0f;
        theSrcRect.size.width = mImageSize.width;
        theSrcRect.size.height = mImageSize.height;
    }
    theSrcRect.origin.y = mImageSize.height - theSrcRect.origin.y;

    float texX = (theSrcRect.origin.x / mImageSize.width) * mTextureSize.width;
    float texY = (theSrcRect.origin.y / mImageSize.height) * mTextureSize.height;
    float texWidth = (theSrcRect.size.width / mImageSize.width) * mTextureSize.width;
    float texHeight = (theSrcRect.size.height / mImageSize.height) * mTextureSize.height * -1;
    
    float p1_x = 0.0f;
    float p2_x = theSrcRect.size.width;
    float p3_x = 0.0f;
    float p4_x = theSrcRect.size.width;
    
    float p1_y = theSrcRect.size.height;
    float p2_y = theSrcRect.size.height;
    float p3_y = 0.0f;
    float p4_y = 0.0f;
    
    // Translate the 4 coord points according to the origin
    if (origin.x != 0.0f) {
        p1_x -= origin.x;
        p2_x -= origin.x;
        p3_x -= origin.x;
        p4_x -= origin.x;
    }
    if (origin.y != 0.0f) {
        p1_y -= origin.y;
        p2_y -= origin.y;
        p3_y -= origin.y;
        p4_y -= origin.y;
    }
    
    // Scale the 4 coord points
    if (scale.width != 1.0f) {
        p1_x *= scale.width;
        p2_x *= scale.width;
        p3_x *= scale.width;
        p4_x *= scale.width;
    }
    if (scale.height != 1.0f) {
        p1_y *= scale.height;
        p2_y *= scale.height;
        p3_y *= scale.height;
        p4_y *= scale.height;
    }
    
    // Rotate the 4 coord points
    if (rotation != 0.0f) {
        float cos_value = cosf(rotation);
        float sin_value = sinf(rotation);
        float p1_x2 = p1_x * cos_value - p1_y * sin_value;
        float p2_x2 = p2_x * cos_value - p2_y * sin_value;
        float p3_x2 = p3_x * cos_value - p3_y * sin_value;
        float p4_x2 = p4_x * cos_value - p4_y * sin_value;
        
        float p1_y2 = p1_x * sin_value + p1_y * cos_value;
        float p2_y2 = p2_x * sin_value + p2_y * cos_value;
        float p3_y2 = p3_x * sin_value + p3_y * cos_value;
        float p4_y2 = p4_x * sin_value + p4_y * cos_value;
        
        p1_x = p1_x2;
        p2_x = p2_x2;
        p3_x = p3_x2;
        p4_x = p4_x2;
        
        p1_y = p1_y2;
        p2_y = p2_y2;
        p3_y = p3_y2;
        p4_y = p4_y2;
    }
    
    // Translate the center point to the appropriate location
    p1_x += centerPos.x;
    p2_x += centerPos.x;
    p3_x += centerPos.x;
    p4_x += centerPos.x;
    
    p1_y += centerPos.y;
    p2_y += centerPos.y;
    p3_y += centerPos.y;
    p4_y += centerPos.y;

    drawData[0].vertex_x = (GLfloat)p1_x;       drawData[0].vertex_y = (GLfloat)p1_y;
    drawData[1].vertex_x = (GLfloat)p2_x;       drawData[1].vertex_y = (GLfloat)p2_y;
    drawData[2].vertex_x = (GLfloat)p3_x;       drawData[2].vertex_y = (GLfloat)p3_y;
    drawData[3].vertex_x = (GLfloat)p2_x;       drawData[3].vertex_y = (GLfloat)p2_y;
    drawData[4].vertex_x = (GLfloat)p3_x;       drawData[4].vertex_y = (GLfloat)p3_y;
    drawData[5].vertex_x = (GLfloat)p4_x;       drawData[5].vertex_y = (GLfloat)p4_y;

    float tx_1 = texX;
    float tx_2 = texX + texWidth;
    float ty_1 = texY;
    float ty_2 = texY + texHeight;
    
    drawData[0].texCoord_x = tx_1;      drawData[0].texCoord_y = ty_2;
    drawData[1].texCoord_x = tx_2;      drawData[1].texCoord_y = ty_2;
    drawData[2].texCoord_x = tx_1;      drawData[2].texCoord_y = ty_1;
    drawData[3].texCoord_x = tx_2;      drawData[3].texCoord_y = ty_2;
    drawData[4].texCoord_x = tx_1;      drawData[4].texCoord_y = ty_1;
    drawData[5].texCoord_x = tx_2;      drawData[5].texCoord_y = ty_1;

    glVertexPointer(2, GL_SHORT, sizeof(GLTextureDrawData), drawData);
	glTexCoordPointer(2, GL_FLOAT, sizeof(GLTextureDrawData), ((GLshort *)drawData)+2);
    
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glDisableClientState(GL_COLOR_ARRAY);

    glColor4f(1.0f, 1.0f, 1.0f, alpha);

    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end

