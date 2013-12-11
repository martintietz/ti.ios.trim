/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiModule.h"
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVFoundation.h>

@interface TiIosTrimModule : TiModule
{
	KrollCallback *successCallback;
    KrollCallback *errorCallback;
}

@end
