/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiIosTrimModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@interface TiIosTrimModule ()
@property (strong, nonatomic) NSURL *outputUrl;
@end

@implementation TiIosTrimModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"0294e87c-39ae-4b0f-ab3d-1dd78937bf04";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.ios.trim";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];

	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably

	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup

-(void)dealloc
{
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

#pragma Public APIs

-(void)trimVideo:(id)args
{
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);

    NSString *inputFile = [args objectForKey:@"input"];
    int quality = [TiUtils intValue:[args objectForKey:@"quality"]];
    NSString *startValue = [args objectForKey:@"startTime"];
    NSString *endValue = [args objectForKey:@"endTime"];
    id success = [args objectForKey:@"success"];
    id error = [args objectForKey:@"error"];
    RELEASE_TO_NIL(successCallback);
    RELEASE_TO_NIL(errorCallback);
    self->successCallback = [success retain];
    self->errorCallback = [error retain];

    // create a url for the input video file
    NSURL *inputUrl;
    if ([inputFile hasPrefix:@"assets-library"]) {
        inputUrl = [NSURL URLWithString:inputFile];
    }
    else {
        inputUrl = [NSURL fileURLWithPath:inputFile];
    }

    // generate a temporary output file
    NSString *tempDir = NSTemporaryDirectory();
    NSString *tmpVideoPath = [tempDir stringByAppendingPathComponent:@"tmpMov.mov"];
    self.outputUrl = [NSURL fileURLWithPath:tmpVideoPath];

    // clear the output file
    [self removeFile:self.outputUrl];

    AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:inputUrl options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:anAsset];

    NSString *presetName = AVAssetExportPresetPassthrough;
    if (quality == 1 && [compatiblePresets containsObject:AVAssetExportPresetLowQuality]) {
        presetName = AVAssetExportPresetLowQuality;
    }
    else if (quality == 2 && [compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        presetName = AVAssetExportPresetMediumQuality;
    }
    else if (quality == 3 && [compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        presetName = AVAssetExportPresetHighestQuality;
    }
    
    // set the start and end times
    CGFloat start = 0;
    CGFloat end = CMTimeGetSeconds(anAsset.duration);
    if (startValue != nil) {
        start = [TiUtils floatValue:startValue];
    }
    if (endValue != nil) {
        end = [TiUtils floatValue:endValue];
    }

    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                          initWithAsset:anAsset presetName:presetName];

    exportSession.outputURL = self.outputUrl;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;

    CMTime startTime = CMTimeMakeWithSeconds(start, 1);
    CMTime stopTime = CMTimeMakeWithSeconds(end, 1);
    CGFloat thumbnailTime = (end - start) / 2;
    CMTimeRange range = CMTimeRangeFromTimeToTime(startTime, stopTime);
    exportSession.timeRange = range;

    [exportSession exportAsynchronouslyWithCompletionHandler:^{

        switch ([exportSession status]) {
            case AVAssetExportSessionStatusCompleted:
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Export Complete %d %@", exportSession.status, exportSession.error);
                    [self generateThumbnail:thumbnailTime];
                });
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                NSLog(@"%@", [exportSession.error description]);

                NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:[exportSession.error description],@"error",nil];
                [self _fireEventToListener:@"error" withObject:event listener:self->errorCallback thisObject:nil];
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Export canceled");
                break;
            default:
                NSLog(@"NONE");
                break;
        }
    }];
}

- (void) removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            NSLog(@"removeItemAtPath %@ error:%@", filePath, error);
        }
    }
}

- (void) generateThumbnail:(CGFloat)thumbnailTime
{
    MPMoviePlayerController *movie = [[MPMoviePlayerController alloc] initWithContentURL:self.outputUrl];
    movie.shouldAutoplay = NO;
    NSNumber *halfDuration = [NSNumber numberWithFloat:thumbnailTime];
    NSArray *times = [NSArray arrayWithObjects:halfDuration, nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThumbnailImageRequestFinishNotification:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:movie];
    
    [movie requestThumbnailImagesAtTimes:times timeOption:MPMovieTimeOptionExact];
}

-(void) handleThumbnailImageRequestFinishNotification:(NSNotification *)note
{
    NSDictionary *userinfo = [note userInfo];
    NSError* value = [userinfo objectForKey:MPMoviePlayerThumbnailErrorKey];
    
    if (value != nil) {
        NSLog(@"Error: %@", [value debugDescription]);
    }
    else
    {
        UIImage *image = [userinfo valueForKey:MPMoviePlayerThumbnailImageKey];
        [self sendSuccessCallbackWithThumbnail:image];
    }
}

-(void) sendSuccessCallbackWithThumbnail:(UIImage *) thumbnail
{
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                           self.outputUrl, @"videoURL",
                           [[[TiBlob alloc] initWithImage:thumbnail] autorelease], @"thumbnail",
                           nil];
    [self _fireEventToListener:@"success" withObject:event listener:self->successCallback thisObject:nil];
}

@end
