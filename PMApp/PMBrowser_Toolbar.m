//
//  DPToolbarDelegate.m
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

#import "DPToolbarDelegate.h"
#import "DPController.h"
#import "DPNames.h"

NSString* DPToolbarID = @"DPToolbarID";

//Automatic, but must add a tooltip entry
NSString* DPBuildItemID = @"Build";
NSString* DPChecksumItemID = @"Checksum";
NSString* DPCleanItemID = @"Clean";
NSString* DPFetchItemID = @"Fetch";
NSString* DPInstallItemID = @"Install";
NSString* DPPackageItemID = @"Package";

NSString* DPConsoleItemID = @"Console";
NSString* DPReloadItemID = @"Reload";
NSString* DPSearchItemID = @"Search";

@implementation DPToolbarDelegate

- (BOOL) isPortItem:(NSString *)itemID {
    static NSArray *portItems = nil;
    if (nil == portItems) {
        portItems = [NSArray arrayWithObjects:DPBuildItemID, DPChecksumItemID,
            DPCleanItemID, DPFetchItemID, DPInstallItemID, DPPackageItemID, nil];
        [portItems retain];
        }
    return [portItems containsObject:itemID];
}
    
- (id) setController:(DPController *)controller {
    // Create a new toolbar instance, and attach it to window
    _controller = controller;
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:DPToolbarID] autorelease];

    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];

    // We are the delegate
    [toolbar setDelegate: self];
    [window setToolbar: toolbar];
    return toolbar;
}

- (NSToolbarItem *) itemWithID:(NSString *)itemID {
    static NSString *tipFormat = @"%@ Port";
    NSString *tip =  [NSString stringWithFormat:tipFormat, itemID];
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemID] autorelease];
    [toolbarItem setLabel: itemID];
    [toolbarItem setPaletteLabel:itemID];
    [toolbarItem setTarget: _controller];
    [toolbarItem setAction: @selector(executeItem:)]; // default
    [toolbarItem setToolTip:tip];

    NSImage *image = [NSImage imageNamed:itemID];
    if (nil != image) [toolbarItem setImage:image];
    return toolbarItem;
}

/** Delegate methods */

// Required delegate method:  Given an item identifier, this method returns an item
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {

    NSToolbarItem *toolbarItem = [self itemWithID:itemIdent];

    if ([itemIdent isEqual: DPConsoleItemID]) {
        [toolbarItem setToolTip: @"Toggle Console"];
        [toolbarItem setAction: @selector(toggleConsole:)];
    } else if ([itemIdent isEqual: DPReloadItemID]) {
        [toolbarItem setToolTip: @"Reload Ports"];
        [toolbarItem setAction: @selector(reloadPorts:)];
    } else if([itemIdent isEqual: DPSearchItemID]) {
        NSMenu *submenu = nil;
        NSMenuItem *submenuItem = nil, *menuFormRep = nil;

        // Set up the standard properties
        [toolbarItem setToolTip: @"Search"];
        [toolbarItem setAction: @selector(takePatternFrom:)];

        // Use a custom view, a text field, for the search item
        [toolbarItem setView: searchFieldOutlet];
        [toolbarItem setMinSize:NSMakeSize(30, NSHeight([searchFieldOutlet frame]))];
        [toolbarItem setMaxSize:NSMakeSize(400,NSHeight([searchFieldOutlet frame]))];

        // By default, in text  mode, a custom items label will be shown as disabled text, but you 
        // can provide a custom menu of your own by using <item> setMenuFormRepresentation]
        submenu = [[[NSMenu alloc] init] autorelease];
        submenuItem = [[[NSMenuItem alloc] initWithTitle: @"Search Panel"
                                                  action:@selector(searchUsingSearchPanel:)
                                           keyEquivalent: @""] autorelease];
        menuFormRep = [[[NSMenuItem alloc] init] autorelease];

        [submenu addItem: submenuItem];
        [submenuItem setTarget: _controller];
        [menuFormRep setSubmenu: submenu];
        [menuFormRep setTitle: [toolbarItem label]];
        [toolbarItem setMenuFormRepresentation: menuFormRep];
    }
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Returns the ordered list of items to be shown in the toolbar by default
    return [NSArray arrayWithObjects:
        DPFetchItemID, DPBuildItemID, DPInstallItemID, DPCleanItemID,
        NSToolbarSeparatorItemIdentifier, DPConsoleItemID,
        NSToolbarPrintItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier,
        NSToolbarSpaceItemIdentifier, DPSearchItemID,
        nil]; 
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // The set of allowed items is used to construct the customization palette
    return [NSArray arrayWithObjects:
        DPBuildItemID, DPChecksumItemID, DPCleanItemID,
        DPFetchItemID, DPInstallItemID, DPPackageItemID,
        NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        DPConsoleItemID, DPSearchItemID, DPReloadItemID,
        NSToolbarPrintItemIdentifier, NSToolbarShowFontsItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        nil];
    //NSToolbarShowColorsItemIdentifier,
    //NSToolbarShowFontsItemIdentifier,

}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
    if([[addedItem itemIdentifier] isEqual: DPSearchItemID]) {
        activeSearchItem = [addedItem retain];
        [activeSearchItem setTarget: _controller];
        [activeSearchItem setAction: @selector(takePatternFrom:)];
    } else if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
        [addedItem setToolTip: @"Print Ports"];
        [addedItem setTarget:_controller];
    }
}

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
    if (removedItem==activeSearchItem) {
        [activeSearchItem autorelease];
        activeSearchItem = nil;
    }
}

@end
