//
//  UIImage+GIFFromMovie.m
//  wecarepet
//
//  Created by MaHang on 12/11/15.
//  Copyright © 2015 wecarepet. All rights reserved.
//

#import "UIImage+GIFFromMovie.h"
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+animatedGIF.h"

@implementation UIImage (GIFFromMovie)

+(void)AnimatedGIFFromMovieAsset:(AVURLAsset *)movie timeIncrement:(float)increment completion:(GIFFromMovieCompletion)completion{
    
    
    //Instantiate an AVAssetImageGenerator for the target Movie.
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:movie];
    
    //Calculate the frames in the final GIF by the movie's length and the given time increment.
    float movieLength = (float)movie.duration.value /movie.duration.timescale;
    int frameCount = movieLength / increment;
    float tolerance = 0.01f;

    
    //Create a temp gif file as the output destination.
    //By adding all the thumbnails to this file, we could generate the desired gif file holding the data.
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingString:@"temp.gif"];
    CFURLRef fileURL = (__bridge CFURLRef) [NSURL fileURLWithPath:tempFile];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(fileURL, kUTTypeGIF, frameCount,nil);
    
    
    //Set properties for the generator and gif.
    generator.requestedTimeToleranceBefore = CMTimeMakeWithSeconds(tolerance, 600) ;
    generator.requestedTimeToleranceAfter = CMTimeMakeWithSeconds(tolerance, 600);
    generator.appliesPreferredTrackTransform = YES;
    
    NSDictionary *frameProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:increment] forKey:(NSString *)kCGImagePropertyGIFDelayTime] forKey:(NSString *)kCGImagePropertyGIFDictionary];
    NSDictionary *gifProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount] forKey:(NSString *)kCGImagePropertyGIFDictionary];
    
    //Get the size of the target Movie;
    CGSize videoSize = [[[movie tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    
    //Set the out put size of thumbnails. Here we force the output image to be 320 in width
    float imageWidth = 320.0f;
    generator.maximumSize = CGSizeMake( imageWidth , imageWidth/videoSize.width * videoSize.height);
    
    //Perform the converting asynchronously
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        NSError *error = nil;
        
        //Repeatly generate thumbnail of video and put them together
        for (int i = 0 ; i < frameCount; i++) {
            
            //Time for current thumbnail
            CMTime imageTime = CMTimeMakeWithSeconds(i*increment, 600);
            
            //Generate the thumbnail
            CGImageRef image = [generator copyCGImageAtTime:imageTime actualTime:nil error:&error];
            if (error) {
                //Once there is any error during converting, stop and call back.
                completion(nil,error);
                return;
            }
            //Add current thumbnail to the destination
            CGImageDestinationAddImage(destination, image,  (CFDictionaryRef)frameProperties);
        }
        
        //set gif properties (infinite loop)
        CGImageDestinationSetProperties(destination, (CFDictionaryRef)gifProperties);
        
        //Finalize temp file
        CGImageDestinationFinalize(destination);
        
        //Get the gifData and Associate it with the UIImage instance;
        NSData *gifData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:tempFile]];
        UIImage *result = [UIImage animatedImageWithAnimatedGIFData:gifData];
        objc_setAssociatedObject(result, @"gifData",gifData,OBJC_ASSOCIATION_RETAIN);
        
        //Release the temp file
        CFRelease(destination);
        
        //callback
        completion(result,error);
    });

}

-(NSData *)getGifData{
    //return the assocated gif Data
    return objc_getAssociatedObject(self, @"gifData");
    
    //FOR EXAMPLE:
    //If we need the dataUrl of this UIImage
    //[NSString stringWithFormat:@"data:%@;base64,%@", @"image/gif", [[image getGifData] base64EncodedStringWithOptions:0]]
}


@end
