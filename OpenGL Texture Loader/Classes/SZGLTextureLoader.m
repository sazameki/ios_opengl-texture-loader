//
//  SZGLTextureLoader.m
//  Texture Loading Sample
//
//  Created by numata on 09/08/16.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "SZGLTextureLoader.h"

#import <UIKit/UIKit.h>


#pragma mark -
#pragma mark Texture Loading Implementation by Apple

typedef enum {
	kTexture2DPixelFormat_Automatic = 0,
	kTexture2DPixelFormat_RGBA8888,
	kTexture2DPixelFormat_RGBA4444,
	kTexture2DPixelFormat_RGBA5551,
	kTexture2DPixelFormat_RGB565,
	kTexture2DPixelFormat_RGB888,
	kTexture2DPixelFormat_L8,
	kTexture2DPixelFormat_A8,
	kTexture2DPixelFormat_LA88,
} Texture2DPixelFormat;

static GLuint _GLLoadTextureFromData(const void *data, Texture2DPixelFormat pixelFormat, NSUInteger width, NSUInteger height, CGSize contentSize, CGSize *imageSize_, CGSize *textureSize_)
{
    GLuint  _name;
	GLint   saveName;
	
    glGenTextures(1, &_name);
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &saveName);
    glBindTexture(GL_TEXTURE_2D, _name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    switch (pixelFormat) {
        case kTexture2DPixelFormat_RGBA8888:
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
            break;
            
        case kTexture2DPixelFormat_RGBA4444:
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, data);
            break;
            
        case kTexture2DPixelFormat_RGBA5551:
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_SHORT_5_5_5_1, data);
            break;
            
        case kTexture2DPixelFormat_RGB565:
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, data);
            break;
            
        case kTexture2DPixelFormat_RGB888:
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
            break;
            
        case kTexture2DPixelFormat_L8:
            glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, data);
            break;
            
        case kTexture2DPixelFormat_A8:
            glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, width, height, 0, GL_ALPHA, GL_UNSIGNED_BYTE, data);
            break;
            
        case kTexture2DPixelFormat_LA88:
            glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, width, height, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, data);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@""];
            
    }
    glBindTexture(GL_TEXTURE_2D, saveName);
    
    GLenum error = glGetError();
    if (error) {
        NSLog(@"Texture Loader: OpenGL error 0x%04X", error);
        return GL_INVALID_VALUE;
    }
    
    imageSize_->width = width * contentSize.width / (float)width;
    imageSize_->height = height * contentSize.height / (float)height;
    
    textureSize_->width = contentSize.width / (float)width;
    textureSize_->height = contentSize.height / (float)height;
    
    return _name;
}

static GLuint _GLLoadTextureFromCGImage(CGImageRef imageRef, UIImageOrientation orientation, CGSize *imageSize_, CGSize *textureSize_)
{
    NSUInteger				width;
    NSUInteger              height;
    NSUInteger              i;
	CGContextRef			context = nil;
	void*					data = nil;;
	CGColorSpaceRef			colorSpace;
	void*					tempData;
	unsigned char*			inPixel8;
	unsigned int*			inPixel32;
	unsigned char*			outPixel8;
	unsigned short*			outPixel16;
	BOOL					hasAlpha;
	CGImageAlphaInfo		info;
	CGAffineTransform		transform;
	CGSize					imageSize;
	
	if (imageRef == NULL) {
        return GL_INVALID_VALUE;
	}
    
    Texture2DPixelFormat pixelFormat = kTexture2DPixelFormat_Automatic;
    BOOL sizeToFit = NO;
	
	if (pixelFormat == kTexture2DPixelFormat_Automatic) {
		info = CGImageGetAlphaInfo(imageRef);
		hasAlpha = ((info == kCGImageAlphaPremultipliedLast) || (info == kCGImageAlphaPremultipliedFirst) || (info == kCGImageAlphaLast) || (info == kCGImageAlphaFirst) ? YES : NO);
		if (CGImageGetColorSpace(imageRef)) {
			if (CGColorSpaceGetModel(CGImageGetColorSpace(imageRef)) == kCGColorSpaceModelMonochrome) {
				if (hasAlpha) {
					pixelFormat = kTexture2DPixelFormat_LA88;
				}
				else {
					pixelFormat = kTexture2DPixelFormat_L8;
				}
			}
			else {
				if((CGImageGetBitsPerPixel(imageRef) == 16) && !hasAlpha)
                    pixelFormat = kTexture2DPixelFormat_RGBA5551;
				else {
					if(hasAlpha)
                        pixelFormat = kTexture2DPixelFormat_RGBA8888;
					else {
						pixelFormat = kTexture2DPixelFormat_RGB565;
					}
				}
			}		
		}
		else { //NOTE: No colorspace means a mask image
			pixelFormat = kTexture2DPixelFormat_A8;
		}
	}
	
	imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
	switch (orientation) {
		case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
		case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
		case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
		case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
		case UIImageOrientationLeftMirrored: //EXIF = 5
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
		case UIImageOrientationLeft: //EXIF = 6
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
		case UIImageOrientationRightMirrored: //EXIF = 7
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
		case UIImageOrientationRight: //EXIF = 8
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
		default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
	}
	if ((orientation == UIImageOrientationLeftMirrored) || (orientation == UIImageOrientationLeft) ||
        (orientation == UIImageOrientationRightMirrored) || (orientation == UIImageOrientationRight))
    {
        imageSize = CGSizeMake(imageSize.height, imageSize.width);
    }
	
	width = imageSize.width;
	if ((width != 1) && (width & (width - 1))) {
		i = 1;
		while ((sizeToFit ? 2 * i : i) < width) {
            i *= 2;
        }
		width = i;
	}
	height = imageSize.height;
	if ((height != 1) && (height & (height - 1))) {
		i = 1;
		while ((sizeToFit ? 2 * i : i) < height)
            i *= 2;
		height = i;
	}
    
	switch (pixelFormat) {
		case kTexture2DPixelFormat_RGBA8888:
		case kTexture2DPixelFormat_RGBA4444:
            colorSpace = CGColorSpaceCreateDeviceRGB();
            data = malloc(height * width * 4);
            context = CGBitmapContextCreate(data, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
            CGColorSpaceRelease(colorSpace);
            break;
            
		case kTexture2DPixelFormat_RGBA5551:
            colorSpace = CGColorSpaceCreateDeviceRGB();
            data = malloc(height * width * 2);
            context = CGBitmapContextCreate(data, width, height, 5, 2 * width, colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder16Little);
            CGColorSpaceRelease(colorSpace);
            break;
            
		case kTexture2DPixelFormat_RGB888:
		case kTexture2DPixelFormat_RGB565:
            colorSpace = CGColorSpaceCreateDeviceRGB();
            data = malloc(height * width * 4);
            context = CGBitmapContextCreate(data, width, height, 8, 4 * width, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
            CGColorSpaceRelease(colorSpace);
            break;
            
		case kTexture2DPixelFormat_L8:
            colorSpace = CGColorSpaceCreateDeviceGray();
            data = malloc(height * width);
            context = CGBitmapContextCreate(data, width, height, 8, width, colorSpace, kCGImageAlphaNone);
            CGColorSpaceRelease(colorSpace);
            break;
            
		case kTexture2DPixelFormat_A8:
            data = malloc(height * width);
            context = CGBitmapContextCreate(data, width, height, 8, width, NULL, kCGImageAlphaOnly);
            break;
            
		case kTexture2DPixelFormat_LA88:
            colorSpace = CGColorSpaceCreateDeviceRGB();
            data = malloc(height * width * 4);
            context = CGBitmapContextCreate(data, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
            CGColorSpaceRelease(colorSpace);
            break;
            
		default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid pixel format"];
            
	}
	if (context == NULL) {
		NSLog(@"Texture Loader: Failed creating CGBitmapContext.");
		free(data);
		return GL_INVALID_VALUE;
	}
	
	if(sizeToFit)
        CGContextScaleCTM(context, (CGFloat)width / imageSize.width, (CGFloat)height / imageSize.height);
	else {
		CGContextClearRect(context, CGRectMake(0, 0, width, height));
		CGContextTranslateCTM(context, 0, height - imageSize.height);
	}
	if (!CGAffineTransformIsIdentity(transform)) {
        CGContextConcatCTM(context, transform);
    }
	CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)), imageRef);
	
	//Convert "-RRRRRGGGGGBBBBB" to "RRRRRGGGGGBBBBBA"
	if (pixelFormat == kTexture2DPixelFormat_RGBA5551) {
		outPixel16 = (unsigned short*)data;
		for (i = 0; i < width * height; ++i, ++outPixel16) {
            *outPixel16 = *outPixel16 << 1 | 0x0001;
        }
	}
	//Convert "RRRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "RRRRRRRRRGGGGGGGGBBBBBBBB"
	else if (pixelFormat == kTexture2DPixelFormat_RGB888) {
		tempData = malloc(height * width * 3);
		inPixel8 = (unsigned char*)data;
		outPixel8 = (unsigned char*)tempData;
		for(i = 0; i < width * height; ++i) {
			*outPixel8++ = *inPixel8++;
			*outPixel8++ = *inPixel8++;
			*outPixel8++ = *inPixel8++;
			inPixel8++;
		}
		free(data);
		data = tempData;
	}
	//Convert "RRRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "RRRRRGGGGGGBBBBB"
	else if (pixelFormat == kTexture2DPixelFormat_RGB565) {
		tempData = malloc(height * width * 2);
		inPixel32 = (unsigned int*)data;
		outPixel16 = (unsigned short*)tempData;
		for(i = 0; i < width * height; ++i, ++inPixel32) {
            *outPixel16++ = ((((*inPixel32 >> 0) & 0xFF) >> 3) << 11) | ((((*inPixel32 >> 8) & 0xFF) >> 2) << 5) | ((((*inPixel32 >> 16) & 0xFF) >> 3) << 0);
        }
		free(data);
		data = tempData;
	}
	//Convert "RRRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "RRRRRGGGGBBBBAAAA"
	else if(pixelFormat == kTexture2DPixelFormat_RGBA4444) {
		tempData = malloc(height * width * 2);
		inPixel32 = (unsigned int*)data;
		outPixel16 = (unsigned short*)tempData;
		for (i = 0; i < width * height; ++i, ++inPixel32) {
            *outPixel16++ = ((((*inPixel32 >> 0) & 0xFF) >> 4) << 12) | ((((*inPixel32 >> 8) & 0xFF) >> 4) << 8) | ((((*inPixel32 >> 16) & 0xFF) >> 4) << 4) | ((((*inPixel32 >> 24) & 0xFF) >> 4) << 0);
        }
		free(data);
		data = tempData;
	}
	//Convert "RRRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "LLLLLLLLAAAAAAAA"
	else if (pixelFormat == kTexture2DPixelFormat_LA88) {
		tempData = malloc(height * width * 3);
		inPixel8 = (unsigned char*)data;
		outPixel8 = (unsigned char*)tempData;
		for (i = 0; i < width * height; i++) {
			*outPixel8++ = *inPixel8++;
			inPixel8 += 2;
			*outPixel8++ = *inPixel8++;
		}
		free(data);
		data = tempData;
	}
    else if (pixelFormat == kTexture2DPixelFormat_RGBA8888) {
        inPixel8 = (unsigned char *)data;
        unsigned char max = 0;
		for (i = 0; i < width * height; i++) {
            float alpha = (float)*(inPixel8+3) / 0xff;
            if (alpha > 0.0f && alpha < 1.0f) {
                *(inPixel8) = (unsigned char)((float)*(inPixel8) / alpha);
                if (*(inPixel8) > max) {
                    max = *(inPixel8);
                }
                inPixel8++;
                *(inPixel8) = (unsigned char)((float)*(inPixel8) / alpha);
                if (*(inPixel8) > max) {
                    max = *(inPixel8);
                }
                inPixel8++;
                *(inPixel8) = (unsigned char)((float)*(inPixel8) / alpha);
                if (*(inPixel8) > max) {
                    max = *(inPixel8);
                }
                inPixel8 += 2;
            } else {
                inPixel8 += 4;
            }
        }
    }
    
    GLuint ret = _GLLoadTextureFromData(data, pixelFormat, width, height, imageSize, imageSize_, textureSize_);
	
	CGContextRelease(context);
	free(data);
	
	return ret;
}

static GLuint SZGLLoadTextureImpl_Apple(NSString *imagePath, CGSize *imageSize, CGSize *textureSize)
{
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
    
    GLuint ret = _GLLoadTextureFromCGImage([image CGImage], [image imageOrientation], imageSize, textureSize);
    
    [image release];
    
    return ret;
}


#pragma mark -
#pragma mark PVRTC Support

#define PVR_TEXTURE_FLAG_TYPE_MASK	0xff

static char gPVRTexIdentifier[4] = "PVR!";

enum
{
	kPVRTextureFlagTypePVRTC_2 = 24,
	kPVRTextureFlagTypePVRTC_4
};

typedef struct _PVRTexHeader
    {
        uint32_t headerLength;
        uint32_t height;
        uint32_t width;
        uint32_t numMipmaps;
        uint32_t flags;
        uint32_t dataLength;
        uint32_t bpp;
        uint32_t bitmaskRed;
        uint32_t bitmaskGreen;
        uint32_t bitmaskBlue;
        uint32_t bitmaskAlpha;
        uint32_t pvrTag;
        uint32_t numSurfs;
    } PVRTexHeader;

static GLuint SZGLLoadTextureImpl_PVR(NSString *imagePath, CGSize *imageSize, CGSize *textureSize)
{
    NSData *data = [NSData dataWithContentsOfFile:imagePath];
    if (!data) {
        return GL_INVALID_VALUE;
    }
    
    NSMutableArray *dataParts = [[NSMutableArray alloc] initWithCapacity:10];
    
    PVRTexHeader *header = (PVRTexHeader *)[data bytes];
	uint32_t pvrTag = CFSwapInt32LittleToHost(header->pvrTag);
    
    if (gPVRTexIdentifier[0] != ((pvrTag >>  0) & 0xff) ||
		gPVRTexIdentifier[1] != ((pvrTag >>  8) & 0xff) ||
		gPVRTexIdentifier[2] != ((pvrTag >> 16) & 0xff) ||
		gPVRTexIdentifier[3] != ((pvrTag >> 24) & 0xff))
	{
        NSLog(@"PVR Tag Error");
		return GL_INVALID_VALUE;
	}
    
    uint32_t flags = CFSwapInt32LittleToHost(header->flags);
	uint32_t formatFlags = flags & PVR_TEXTURE_FLAG_TYPE_MASK;
    
	if (formatFlags != kPVRTextureFlagTypePVRTC_4 && formatFlags != kPVRTextureFlagTypePVRTC_2) {
        NSLog(@"PVR Texture Format Flag Error");
        return GL_INVALID_VALUE;
    }
    
    GLenum internalFormat = (formatFlags == kPVRTextureFlagTypePVRTC_4)? GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG: GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
    
    uint32_t width = CFSwapInt32LittleToHost(header->width);
    uint32_t height = CFSwapInt32LittleToHost(header->height);
    
    uint32_t the_width = width;
    uint32_t the_height = height;
    
    //BOOL hasAlpha = (CFSwapInt32LittleToHost(header->bitmaskAlpha)? YES: NO);
    
    uint32_t dataLength = CFSwapInt32LittleToHost(header->dataLength);
    uint8_t *bytes = ((uint8_t *)[data bytes]) + sizeof(PVRTexHeader);
    uint32_t dataOffset = 0;
    
    uint32_t bpp = (formatFlags == kPVRTextureFlagTypePVRTC_4)? 4: 2;
    uint32_t blockSize = (formatFlags == kPVRTextureFlagTypePVRTC_4)? 4*4: 8*4;
    
    while (dataOffset < dataLength) {
        uint32_t widthBlocks = width / ((formatFlags == kPVRTextureFlagTypePVRTC_4)? 4: 8);
        uint32_t heightBlocks = height / 4;
        
        // Clamp to minimum number of blocks
        if (widthBlocks < 2) {
            widthBlocks = 2;
        }
        if (heightBlocks < 2) {
            heightBlocks = 2;
        }
        
        uint32_t dataSize = widthBlocks * heightBlocks * ((blockSize  * bpp) / 8);
        
        [dataParts addObject:[NSData dataWithBytes:bytes+dataOffset length:dataSize]];
        
        dataOffset += dataSize;
        
        width = MAX(width >> 1, 1);
        height = MAX(height >> 1, 1);
    }
    
    GLuint ret = GL_INVALID_VALUE;
    {
        int width = the_width;
        int height = the_height;
        
        if ([dataParts count] > 0) {
            GLuint name;
            glEnable(GL_TEXTURE_2D);
            glGenTextures(1, &name);
            glBindTexture(GL_TEXTURE_2D, name);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            GLenum err = GL_NO_ERROR;
            
            for (int i = 0; i < [dataParts count]; i++) {
                NSData *data = [dataParts objectAtIndex:i];
                glCompressedTexImage2D(GL_TEXTURE_2D, i, internalFormat, width, height, 0, [data length], [data bytes]);
                
                err = glGetError();
                if (err != GL_NO_ERROR) {
                    NSLog(@"PVR Decompress Error!!");
                    break;
                }
                
                width = MAX(width >> 1, 1);
                height = MAX(height >> 1, 1);
            }
            
            if (err == GL_NO_ERROR) {
                ret = name;
                
                imageSize->width = the_width;
                imageSize->height = the_height;
                
                textureSize->width = 1.0f;
                textureSize->height = 1.0f;
            }
        }
    }
    
    [dataParts release];
    
    return ret;
}


#pragma mark -
#pragma mark Texture Loading Interface

GLuint SZGLLoadTexture(NSString *imagePath, CGSize *imageSize, CGSize *textureSize)
{
    if ([[imagePath pathExtension] compare:@"pvr" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        return SZGLLoadTextureImpl_PVR(imagePath, imageSize, textureSize);
    }
    
    return SZGLLoadTextureImpl_Apple(imagePath, imageSize, textureSize);
}

