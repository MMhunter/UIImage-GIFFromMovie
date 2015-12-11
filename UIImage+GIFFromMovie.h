//
//  UIImage+GIFFromMovie.h
//  wecarepet
//
//  Created by MaHang on 12/11/15.
//  Copyright © 2015 wecarepet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
typedef void(^GIFFromMovieCompletion)(UIImage *image,NSError *error);


@interface UIImage (GIFFromMovie)

+(void) AnimatedGIFFromMovieAsset:(AVURLAsset *) movie timeIncrement:(float) increment completion:(GIFFromMovieCompletion) completion;

-(NSData *) getGifData;

@end
