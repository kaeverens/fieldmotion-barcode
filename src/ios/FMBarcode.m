/********* FMBarcode.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <AVFoundation/AVFoundation.h>
#import "CameraManager.h"

@interface FMBarcode : CDVPlugin {
    // Member variables go here.
    
}

@property(nonatomic, retain) CameraManager *cameraManager;

- (void)startCamera;
- (void)startCamera:(CDVInvokedUrlCommand*)command;
- (void)stopCamera:(CDVInvokedUrlCommand*)command;

- (void)getJpegImage:(CDVInvokedUrlCommand *)command;
- (void)getVideoFormats:(CDVInvokedUrlCommand *)command;
- (void)setVideoFormat:(CDVInvokedUrlCommand *)command;

- (NSString *)thumbData: (UIImage *)image withinBounds:(CGSize)bounds;
- (NSString *)stripData: (UIImage *)image;

@end

@implementation FMBarcode


- (void)pluginInitialize
{
}

- (void)startCamera {
    if(self.cameraManager != nil) {
        [self.cameraManager stopScanning];
        [self.cameraManager deinitCapture];
        self.cameraManager = nil;
    }
    
    self.cameraManager = [[CameraManager alloc] init];
    [self.cameraManager initCapture];
    
    // start on demand / request :)
    //[self.cameraManager startScanning];
    
//    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
//    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)startCamera:(CDVInvokedUrlCommand*)command
{
    if(self.cameraManager != nil) {
        [self.cameraManager stopScanning];
        [self.cameraManager deinitCapture];
        self.cameraManager = nil;
    }
    
    self.cameraManager = [[CameraManager alloc] init];
    [self.cameraManager initCapture];
    
    // start on demand / request :)
    //[self.cameraManager startScanning];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopCamera:(CDVInvokedUrlCommand*)command
{
    if(self.cameraManager != nil) {
        [self.cameraManager stopScanning];
        [self.cameraManager deinitCapture];
        self.cameraManager = nil;
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getJpegImage:(CDVInvokedUrlCommand *)command
{
    @autoreleasepool {
        NSData* jpgData = NULL;
        
        if(self.cameraManager != nil) {
            jpgData = [self.cameraManager getJpegImage];
        }
        
        NSString *base64String = [NSString alloc];
        
        if (jpgData != NULL) {
            UIImage *image = [UIImage imageWithData:jpgData];
            CGSize thumbBounds = CGSizeMake(320.0, 320.0);
            NSString *stripBase64String;
            NSString *thumbBase64String;
            stripBase64String = [self stripData:image];
            thumbBase64String = [self thumbData:image withinBounds:thumbBounds];
            base64String = [base64String initWithString:@"{\"preview\":\""];
            base64String = [base64String stringByAppendingString:thumbBase64String];
            base64String = [base64String stringByAppendingString:@"\",\"strip\":\""];
            base64String = [base64String stringByAppendingString:stripBase64String];
            base64String = [base64String stringByAppendingString:@"\"}"];
//            NSLog(@"%@", base64String);

        #if !__has_feature(objc_arc)
            [jpgData release];
            [image release];
            [base64String release];
            [stripBase64String release];
            [thumbBase64String release];
        #endif
        }
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsString:base64String];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (NSString *)thumbData: (UIImage *)image withinBounds:(CGSize)bounds {
    @autoreleasepool {

        BOOL transpose = NO;
        CGFloat horizontalRatio = bounds.width / image.size.width;
        CGFloat verticalRatio = bounds.height / image.size.height;
        CGFloat ratio;
        
        ratio = MIN(horizontalRatio, verticalRatio);

        CGRect newRect = CGRectIntegral(CGRectMake(0, 0, image.size.width * ratio, image.size.height * ratio));
        CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
        CGImageRef imageRef = image.CGImage;
        
        // Build a context with inverted dimensions (since we'll rotate the given image into this context)
        CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                    newRect.size.height,
                                                    newRect.size.width,
                                                    CGImageGetBitsPerComponent(imageRef),
                                                    0,
                                                    CGImageGetColorSpace(imageRef),
                                                    CGImageGetBitmapInfo(imageRef));
        
        // Rotate and/or flip the image
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformTranslate(transform, 0, newRect.size.width);
        transform = CGAffineTransformRotate(transform, -M_PI_2);
        CGContextConcatCTM(bitmap, transform);

        // Set the quality level to use when rescaling
        CGContextSetInterpolationQuality(bitmap, kCGInterpolationMedium);
        
        // Draw into the context; this scales the image
        CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, imageRef);
        
        // Get the resized image from the context and a UIImage
        CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
        UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
        
        // Clean up
        CGContextRelease(bitmap);
        CGImageRelease(newImageRef);
        
        return [UIImageJPEGRepresentation(newImage,0.75) base64EncodedStringWithOptions:0];
    }
}

- (NSString *)stripData: (UIImage *)image {
    @autoreleasepool {

        CGImageRef c = image.CGImage;
        CGImageAlphaInfo a = CGImageGetAlphaInfo(c);
        uint width = CGImageGetWidth(c);
        uint height = CGImageGetHeight(c);

        NSAssert(CGImageGetBitsPerPixel(c) == 32 && CGImageGetBitsPerComponent(c) == 8 && a == kCGImageAlphaNoneSkipLast, @"unsupported image type supplied");

        CGContextRef targetImage = CGBitmapContextCreate(NULL, height, 1, 8, 1 * height, CGColorSpaceCreateDeviceGray(), kCGImageAlphaNone);

        UInt32 *sourceData = (UInt32*)[((__bridge_transfer NSData*) CGDataProviderCopyData(CGImageGetDataProvider(c))) bytes];
        UInt32 *sourceDataPtr;

        UInt8 *targetData = CGBitmapContextGetData(targetImage);

        UInt8 r,g,b;
        uint offset;
        
        for (int y = height-1; y >= 0; y--) {
            int x = (int)width/2;
            offset = y * width + x;
            
            if (offset+2 < width * height) {
                sourceDataPtr = &sourceData[y * width + x];
                
                r = sourceDataPtr[0+0];
                g = sourceDataPtr[0+1];
                b = sourceDataPtr[0+2];
                
                targetData[height-1-y] = (r+g+b) / 3;
        }   }

        NSData *imgData = [NSData alloc];
        imgData = [imgData initWithBytes:targetData length:CGImageGetHeight(c)];

        CGContextRelease(targetImage);

        return [imgData base64EncodedStringWithOptions:0];
    }
}


- (NSString *)stringWithFourCharCode:(unsigned int) fourCharCode {
    
    char c0 = fourCharCode >> 24;
    char c1 = (fourCharCode >> 16) & 0xff;
    char c2 = (fourCharCode >> 8) & 0xff;
    char c3 = fourCharCode & 0xff;
    
    return [NSString stringWithFormat:@"%c%c%c%c", c0, c1, c2, c3];
}


- (void)getVideoFormats:(CDVInvokedUrlCommand *)command
{
    // messageAsArray NSArray*
    // messageAsArrayBuffer NSData*
    // messageAsDictionary NSDictionary*
    
    NSMutableArray* formats = [[NSMutableArray alloc] init];;
    
    if(self.cameraManager != nil) {
        for(AVCaptureDeviceFormat *vFormat in [self.cameraManager getVideoFormats] )
        {
            
            FourCharCode desc = CMVideoFormatDescriptionGetCodecType(vFormat.formatDescription);
            CMVideoDimensions size = CMVideoFormatDescriptionGetDimensions(vFormat.formatDescription);
            
            int minRate = 999;
            int maxRate = 0;
            
            for ( AVFrameRateRange *range in vFormat.videoSupportedFrameRateRanges ) {
                
                if ( range.maxFrameRate > maxRate ) {
                    maxRate = range.maxFrameRate;
                }
                
                if ( range.minFrameRate < minRate ) {
                    minRate = range.minFrameRate;
                }
            }
            
            // vFormat.mediaType
            // vFormat.formatDescription (Full Block info)
            
            //NSLog(@">> AVFormats  %@ %@ %@",vFormat.mediaType,vFormat.formatDescription,vFormat.videoSupportedFrameRateRanges);
            
            NSString *fourcc = [self stringWithFourCharCode:desc];
            NSString *formatStr = [NSString stringWithFormat:@"(%@) %dx%d , %d-%dfps", fourcc, size.width, size.height, minRate, maxRate];
            [formats addObject:formatStr];
        }
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                       messageAsArray:formats];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setVideoFormat:(CDVInvokedUrlCommand *)command
{
    
    NSDictionary* options = [command.arguments objectAtIndex:0];
    NSString* vFormat = [options valueForKey:@"videoFormat"];
    
    NSLog(@">> Received AVFormat  %@",vFormat);
    
    if(self.cameraManager != nil) {
        [self.cameraManager setVideoFormat:vFormat.intValue];
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                        messageAsBool:YES];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
