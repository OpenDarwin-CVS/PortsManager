//
//  PMStatusController.m
//  PortsManager
//
/*
 Copyright (c) 2003 Apple Computer, Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 3. Neither the name of Apple Computer, Inc. nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#import "PMStatusController.h"
#import "PMStatusView.h"
#import "PMStatusItemView.h"

@implementation PMStatusController


- (id) init
{
    return [super initWithWindowNibName: @"StatusView"];
}


- (void) windowDidLoad
{
    [self reloadData];
}

- (void) reloadData
/*
    Rebuilds the entire status view - inefficient but quick and dirty.   Call after adding/removing new mirrors.
*/
{
#if 0
    int i;
    int mirrorCount = GetNumberOfMirrors();
    int nextUpdate = GetSecondsUntilNextMirrorUpdate();
    NSString *nextUpdateString = @"";
/*
    if (nextUpdate)
    {
        nextUpdateString = [NSString stringWithFormat: @" - Next update in %d seconds", nextUpdate];
    }
*/
	if (mirrorCount == 1)
		[_statusTextField setStringValue: [NSString stringWithFormat: @"1 mirror%@", nextUpdateString]];
	else
		[_statusTextField setStringValue: [NSString stringWithFormat: @"%d mirrors%@", mirrorCount, nextUpdateString]];
    [_statusView removeAllStatusItemViews];
    for (i = 0; i < mirrorCount; i++)
    {
        PMStatusItemView *itemView = [_statusView createNewStatusItemView];
        MirrorInfo mirrorInfo;
        GetMirrorInfo(i, &mirrorInfo);
        [itemView setName: mirrorInfo.name];
        [itemView setTarget: self];
        [itemView setAction: @selector(inspectItem:)];
        switch (mirrorInfo.state)
        {
            default:
            case MIRROR_IDLE:
            {
                [itemView hideProgressIndicator];
                [itemView setStatus: @"Last updated: Wed, Feb 19, 2003, 1:57 AM"];
                break;
            }
            case MIRROR_CHECKING:
            {
				[itemView showProgressIndicator];
				[itemView setProgressIndeterminate: NO];
				[itemView setProgress: 100.0];
				[itemView setStatus: @"Checking for updates"];
                break;
            }
            case MIRROR_UPDATING:
            {
                if (mirrorInfo.progressmax)
                {
                    [itemView showProgressIndicator];
					[itemView setProgressIndeterminate: NO];
                    [itemView setProgress: mirrorInfo.progresscurrent*100.0/mirrorInfo.progressmax];
                    [itemView setStatus: [NSString stringWithFormat: @"Updating %d of %d files", 
                            mirrorInfo.progresscurrent, 
                            mirrorInfo.progressmax]];
                }
                else
                {
                    [itemView showProgressIndicator];
					[itemView setProgressIndeterminate: NO];
                    [itemView setStatus: @"Updating"];
                }
                break;
            }
        }
    }
    [_statusView display];
#endif
}


- (void) updateData
/*
    Updates information for existing mirrors without rebuilding the entire status view.   Call to update progress.
*/
{
}


- (void) doWork
{
#if 0
    DoMirrorWork();
#endif
    [self reloadData];
}


- (IBAction) inspectItem: (id)sender
{
#if 0
    MirrorInfo mirrorInfo;
    int i = [[_statusView subviews] indexOfObject: [sender superview]];
    GetMirrorInfo(i, &mirrorInfo);
    [[NSWorkspace sharedWorkspace] openFile: mirrorInfo.name];
#endif
}


- (IBAction) updateMirrorsNow: (id)sender
{
#if 0
    UpdateMirrorsNow();
    [self reloadData];
    [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector: @selector(doWork) userInfo: nil repeats: YES];
#endif
}


@end
