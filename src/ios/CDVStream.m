/*
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements. See the NOTICE file
distributed with this work for additional information
regarding copyright ownership. The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied. See the License for the
specific language governing permissions and limitations
under the License.
*/

#import "CDVStream.h"
#import <Cordova/NSArray+Comparisons.h>
#import <Cordova/CDVJSON.h>
#import <objc/runtime.h>

@implementation CDVStream

@synthesize objAVPlayer;
@synthesize avSession;

- (void)create:(CDVInvokedUrlCommand*)command
{
	[self.commandDelegate runInBackground:^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];

}


-(void)setupInfoCenter:(CDVInvokedUrlCommand*)command
{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (void)setInfoCenterInfo:(NSDictionary*) songdata AndDuration:(float) duration
{
    
    NSError *setInfoCenterInfoError;
    [avSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [avSession setActive:YES error:&setInfoCenterInfoError];
    
    if (setInfoCenterInfoError)
    {
        NSLog(@"Error while setting infocenter data: %@", setInfoCenterInfoError);
    }
    else
    {
        NSString *artist = [songdata objectForKey:@"artist"];
        NSString *trackname = [songdata objectForKey:@"trackname"];
        NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@",  [songdata objectForKey:@"image"] ]];
        
        //construct a new dictionary with this data
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        
        if (songInfo)
        {
            UIImage *artworkImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageUrl]];
            MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
            
            [songInfo setObject:trackname forKey:MPMediaItemPropertyTitle];
            [songInfo setObject:artist forKey:MPMediaItemPropertyArtist];
            [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
            
            //this is a live stream so we dont have a good duration number to set
            //Leaving this here as we may play different media types in the future
            //[songInfo setObject:[NSNumber numberWithFloat:duration] forKey:MPMediaItemPropertyPlaybackDuration];
            //[songInfo setObject:[NSNumber numberWithFloat:0.0] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
            //[songInfo setObject:[NSNumber numberWithFloat:1.0] forKey:MPNowPlayingInfoPropertyPlaybackRate];
            
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
        }
    }
}

- (void)startPlayingAudio:(CDVInvokedUrlCommand*)command
{
	[self.commandDelegate runInBackground:^{
    	NSString* resourcePath = [command.arguments objectAtIndex:1];
        NSDictionary* options = [command argumentAtIndex:2 withDefault:nil];
    	NSURL* resourceURL = [NSURL URLWithString:resourcePath];
    	NSLog(@"Now Playing '%@'", resourcePath);
    	if([self objAVPlayer] == nil){
            
    		[self setObjAVPlayer:[[AVPlayer alloc] initWithURL:resourceURL]];
			[[self objAVPlayer] addObserver:self forKeyPath:@"status" options:0 context:nil];
		}else{
		 	[[self objAVPlayer] play];
		}
        
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        
        if ([options objectForKey:@"songdata"] != NULL)
        {
            [self setInfoCenterInfo:[options objectForKey:@"songdata"] AndDuration:0];
        }
        
        return;
    }];
}
- (void) observeValueForKeyPath:(NSString *)keyPath 
                                ofObject:(id)object 
                                change:(NSDictionary  *)change 
                                context:(void *)context {

    if (object == [self objAVPlayer] && [keyPath isEqualToString:@"status"]) {
         NSLog(@"Something: %ld", (long)[self objAVPlayer].status);
        if ([self objAVPlayer].status == AVPlayerStatusReadyToPlay) {
        	//Audio session is set to allow streaming in background
            //AVAudioSession *audioSession = [AVAudioSession sharedInstance];
            //[audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
            if([self hasAudioSession]){
                [self.avSession setCategory:AVAudioSessionCategoryPlayback error:nil];
                NSTimeInterval bufferDuration=0.5;
                [self.avSession setPreferredIOBufferDuration:bufferDuration error:nil];
                [[self objAVPlayer] play];
            }
            
        }
        if ([self objAVPlayer].status == AVPlayerStatusFailed) {
            NSLog(@"Something went wrong: %@", [self objAVPlayer].error);
        }
    }
}

// returns whether or not audioSession is available - creates it if necessary
- (BOOL)hasAudioSession
{
    BOOL bSession = YES;
    
    if (!self.avSession) {
        NSError* error = nil;
        
        self.avSession = [AVAudioSession sharedInstance];
        if (error) {
            // is not fatal if can't get AVAudioSession , just log the error
            NSLog(@"error creating audio session: %@", [[error userInfo] description]);
            self.avSession = nil;
            bSession = NO;
        }
    }
    return bSession;
}

- (void)stopPlayingAudio:(CDVInvokedUrlCommand*)command
{
	[[self objAVPlayer] pause];
}

@end
