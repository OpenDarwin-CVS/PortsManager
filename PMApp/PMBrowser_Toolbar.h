//
//  DPToolbarDelegate.h
//  DarwinPorts
//
/*
 Copyright (c) 2002 Apple Computer, Inc.
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

#import <Cocoa/Cocoa.h>

extern NSString* DPToolbarID;

extern NSString* DPBuildItemID;
extern NSString* DPChecksumItemID;
extern NSString* DPCleanItemID;
extern NSString* DPFetchItemID;
extern NSString* DPInstallItemID;
extern NSString* DPPackageItemID;

extern NSString* DPConsoleItemID;
extern NSString* DPReloadItemID;
extern NSString* DPSearchItemID;

@class DPController;

@interface DPToolbarDelegate : NSObject {
    @private
    DPController 		*_controller;
    NSToolbarItem		*activeSearchItem;
    // A reference to the search field in the toolbar, null if it doesn't have one!
    IBOutlet NSTextField	*searchFieldOutlet;
    // "Template" textfield needed to create our toolbar searchfield item.
    IBOutlet NSWindow		*window;
    // "Template" textfield needed to create our toolbar searchfield item.
}

- (BOOL) isPortItem:(NSString *)itemID;

- (id) setController:(DPController *)controller;

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar;
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar;
    

@end
