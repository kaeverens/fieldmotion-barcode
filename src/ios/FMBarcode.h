//
//  FMBarcode.h
//  CordovaFMBarcode
//
//  Created by Christian Töpfner on 13/07/15.
//  Copyright (c) 2015 Christian Töpfner. All rights reserved.
//


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
