/*
 * PMBrowser.m
 * PortsManager
 *
 * Copyright (c) 2002-2003, Apple Computer, Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PMApp.h"
#import "PMBrowser.h"
#import "PMConsole.h"

@implementation PMBrowser
/*
    Controller for the GUI in a single browser window
*/

/** Initialization */


- (id) init
{
    return [self initWithWindowNibName: @"Browser"];
}


- (void) windowDidLoad
{

    // set up our toolbar
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: @"DPToolbarIdentifier"] autorelease];
    [toolbar setDelegate: self];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [[self window] setToolbar: toolbar];
    
    _app = [NSApp delegate];

    [[NSNotificationCenter defaultCenter] addObserver: self
        selector: @selector(portProgressNotification:)
        name: DPPortProgressNotification
        object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(portRefreshNotification:)
                                                 name: DPPortRefreshNotification
                                               object: nil];
    // display
    _searchString = @"";
    _sortedColumn = [[_outlineView tableColumnWithIdentifier: @"name"] retain];
    [_outlineView setIndicatorImage: [NSImage imageNamed: @"NSAscendingSortIndicator"] inTableColumn: _sortedColumn];

    // do this after a delay so that our window comes up quickly
    [self performSelector: @selector(reloadTableViews) withObject: nil afterDelay: 0.0];
    
    [super windowDidLoad];
    
}


- (void) dealloc 
{
    [_portNamesArray release];    
    [super dealloc];
}


static int comparePortNamesByIdentifier(id portA, id portB, void *identifier) 
{
    id valueA = [[(PMApp *)[NSApp delegate] portForName: portA] objectForKey: identifier];
    id valueB = [[(PMApp *)[NSApp delegate] portForName: portB] objectForKey: identifier];
    return [[valueA description] caseInsensitiveCompare: [valueB description]];
}


static int reverseComparePortNamesByIdentifier(id portA, id portB, void *identifier) 
{
    return comparePortNamesByIdentifier(portB, portA, identifier);
}


- (void) reloadStatus
{
    NSString *countString = nil;
    NSString *statusString = @"";
    NSNumber *percentComplete = [[_app currentOperation] objectForKey: @"percentComplete"];
    if ([_portNamesArray count] == [[_app ports] count])
    {
        countString = [NSString stringWithFormat: @"%d ports", [_portNamesArray count]];
    }
    else
    {
        countString = [NSString stringWithFormat: @"%d of %d ports", [_portNamesArray count], [[_app ports] count]];
    }

    if (percentComplete && ([percentComplete floatValue] < 100.0))
    {
        statusString = [NSString stringWithFormat: @"%@ %@",
            [[_app currentOperation] objectForKey: @"target"],
            [[_app currentOperation] objectForKey: @"portName"]];
        [_progressIndicator startAnimation: self];
        [_progressIndicator setDoubleValue: [[[_app currentOperation] objectForKey: @"percentComplete"] doubleValue]];
    }
    else
    {
        [_progressIndicator setDoubleValue: 1.0];
        [_progressIndicator stopAnimation: self];
    }

    [_statusTextField setStringValue: 
        [NSString stringWithFormat: @"%@%@%@", 
            countString,
            ([statusString length] ? @" - " : @""),
            statusString]];        
}


- (void) reloadTextView
{

    [_textView setString: @""];

    if ([_outlineView selectedRow] != -1)
    {
        NSTextStorage *textStorage = [_textView textStorage];
        NSDictionary *port = [_app portForName: [_outlineView itemAtRow: [_outlineView selectedRow]]];
        NSArray *keys = [NSMutableArray arrayWithObjects: 
            DPDescriptionKey, DPVersionKey, DPLongDescriptionKey, DPCategoriesKey, 
            DPMaintainersKey, DPPortDirKey, DPPortURLKey, nil];
        NSMutableDictionary *keyAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSFont systemFontOfSize: [NSFont smallSystemFontSize]], NSFontAttributeName,
            nil];
        NSMutableDictionary *valueAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSFont systemFontOfSize: [NSFont smallSystemFontSize]], NSFontAttributeName,
            nil];
        NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSFont boldSystemFontOfSize: [NSFont systemFontSize]], NSFontAttributeName,
            nil];
        NSMutableParagraphStyle *firstLineParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        NSMutableParagraphStyle *otherLinesParagraphStyle;
        float headIndent = 0.0;
        NSEnumerator *enm;
        NSString *key;
        
        // figure out the max width of our property labels
        enm = [keys objectEnumerator];
        while (key = [enm nextObject])
        {
            if ([port objectForKey: key])
            {
                NSString *localizedKey = NSLocalizedString(key, nil); 
                NSAttributedString *attributedKey = [[[NSAttributedString alloc] 
                    initWithString: [NSString stringWithFormat: @"  %@:", localizedKey] 
                    attributes: keyAttributes] autorelease];
                headIndent = MAX(headIndent, [attributedKey size].width);        
            }
        }
        [firstLineParagraphStyle setTabStops: [NSArray arrayWithObjects: 
            [[[NSTextTab alloc] initWithType: NSLeftTabStopType location: headIndent+8] autorelease], 
            nil]];
        [firstLineParagraphStyle setHeadIndent: headIndent+8];
        otherLinesParagraphStyle = [[firstLineParagraphStyle mutableCopy] autorelease];
        [otherLinesParagraphStyle setFirstLineHeadIndent: headIndent+8];

        // display our title
        if ([port objectForKey: DPNameKey])
        {
            NSString *localizedTitle = NSLocalizedString([port objectForKey: DPNameKey], nil);
            NSAttributedString *aString = [[[NSAttributedString alloc] 
                initWithString: [NSString stringWithFormat: @"%@:\n", localizedTitle]
                attributes: titleAttributes] autorelease];
            [textStorage beginEditing];
            [textStorage appendAttributedString: aString];
            [textStorage appendAttributedString: [[[NSMutableAttributedString alloc] initWithString: @"\n"] autorelease]];
        }
        
        // display our property keys and values
        enm = [keys objectEnumerator];
        while (key = [enm nextObject])
        {
            id value = [port objectForKey: key];
            if ([value isKindOfClass: [NSMutableArray class]])
            {
                value = ([value count] ? [value componentsJoinedByString: @"\n"] : nil);                
            }
            if (value)
            {
                NSRange range = NSMakeRange([textStorage length], 0);
                NSAttributedString *attributedKey = [[[NSAttributedString alloc] 
                    initWithString: [NSString stringWithFormat: @"  %@:", NSLocalizedString(key, nil)] 
                    attributes: keyAttributes] autorelease];
                NSAttributedString *attributedValue = [[[NSAttributedString alloc]
                    initWithString: [NSString stringWithFormat: @"\t%@\n", value]
                    attributes: valueAttributes] autorelease];            
                [textStorage appendAttributedString: attributedKey];
                range.length = [textStorage length]-range.location;
                [textStorage addAttribute: NSParagraphStyleAttributeName value: firstLineParagraphStyle range: range]; 
                range.location = [textStorage length];
                [textStorage appendAttributedString: attributedValue];
                range.length = [textStorage length]-range.location;
                [textStorage addAttribute: NSParagraphStyleAttributeName value: otherLinesParagraphStyle range: range];
            }
        }
        
        [textStorage endEditing];
    }
    
}


- (void) reloadTableViews
{

    NSDictionary *port;
    NSEnumerator *portEnm;
    NSString *selectedCategory = [[[self selectedCategory] copy] autorelease];
    
    [_portNamesArray release];
    _portNamesArray = [[NSMutableArray alloc] init];

    portEnm = [[_app ports] objectEnumerator];
    while (port = [portEnm nextObject])
    {
        if (![selectedCategory length] || 
            [[port objectForKey: DPCategoriesKey] containsObject: selectedCategory])
        {
            if (![_searchString length] || 
                ([[port objectForKey: DPNameKey] rangeOfString: _searchString].location != NSNotFound) || 
                ([[port objectForKey: DPDescriptionKey] rangeOfString: _searchString].location != NSNotFound))
            {
                [_portNamesArray addObject: [port objectForKey: DPNameKey]];
            }
        }
    }

    if ([[_outlineView indicatorImageInTableColumn: _sortedColumn] isEqual: [NSImage imageNamed: @"NSDescendingSortIndicator"]])
    {
        [_portNamesArray sortUsingFunction: reverseComparePortNamesByIdentifier context: [_sortedColumn identifier]];
    }
    else
    {
        [_portNamesArray sortUsingFunction: comparePortNamesByIdentifier context: [_sortedColumn identifier]];
    }
    
    [_tableView reloadData];
    [_outlineView reloadData];
    [self reloadTextView];
    [self reloadStatus];
}


- (void) portProgressNotification: (NSNotification *)aNotification
{
    [self reloadStatus];
}


- (void) portRefreshNotification: (NSNotification *) aNotification
{
    [self reloadTableViews];
}


/** Ports outlineview methods **/

/* 
The "item" objects in the outline view are the unique names of the ports NOT the ports dictionaries.  It might seem more efficient/intuitive to use the port  dictionary directly as the outlineview's items and avoid the need to lookup the appropriate dictionary by name each time BUT that does not work!   The same port dictionary can be referenced from more than one place in the outlineview (e.g. both at the root level and as a dependency) and having the same item referenced more than once confuses NSOutlineView when you go to expand/collapse that item
*/

- (NSDictionary *) selectedPort
{
    NSDictionary *selectedPort = nil;
    if ([_outlineView selectedRow] > -1)
    {
        selectedPort = [_app portForName: [_outlineView itemAtRow: [_outlineView selectedRow]]];
    }
    return selectedPort;
}


- (int) outlineView: (NSOutlineView *)olv numberOfChildrenOfItem: (id)item 
{
    NSArray *names = ((nil == item) ? (NSArray *)_portNamesArray : [[_app portForName: item] objectForKey: DPDependsKey]);
    return [names count];
}


- (id) outlineView: (NSOutlineView *)olv child: (int)index ofItem: (id)item 
{
    NSArray *names = ((nil == item) ? (NSArray *)_portNamesArray : [[_app portForName: item] objectForKey: DPDependsKey]);
    return [names objectAtIndex: index];
}


- (BOOL) outlineView: (NSOutlineView *)olv isItemExpandable: (id)item 
{
    return ([self outlineView: olv numberOfChildrenOfItem: item] > 0);
}


- (id) outlineView: (NSOutlineView *)olv objectValueForTableColumn: (NSTableColumn *)tableColumn byItem: (id)item 
{
    NSDictionary *port = [[_app ports] objectForKey: item];
    return [port objectForKey: [tableColumn identifier]];
}


- (void) outlineViewSelectionDidChange: (NSNotification *)aNotification 
{
    [self reloadTextView];
}


- (BOOL) outlineView: (NSTableView *)tableView shouldSelectTableColumn: (NSTableColumn *)tableColumn 
/*
    Handle sorting columns when a column header is clicked
*/
{
    NSImage* ascendingSortIndicator = [NSImage imageNamed: @"NSAscendingSortIndicator"];
	NSImage* descendingSortIndicator = [NSImage imageNamed: @"NSDescendingSortIndicator"];
    BOOL descendingSort = NO;
    NSEnumerator* columnEnm = [[_outlineView tableColumns] objectEnumerator];
	NSTableColumn* column;

    // toggle the indicator image
    if ([_outlineView indicatorImageInTableColumn: tableColumn] == ascendingSortIndicator)
    {
        descendingSort = YES;
    }
    while (column = [columnEnm nextObject])
    {
		[_outlineView setIndicatorImage:nil inTableColumn:column];
    }
	[_outlineView setHighlightedTableColumn: tableColumn];
    [_outlineView setIndicatorImage: (descendingSort  ? descendingSortIndicator : ascendingSortIndicator) inTableColumn: tableColumn];

    // re-sort and redisplay
    [_sortedColumn release];
    _sortedColumn = [tableColumn retain];    
    [self reloadTableViews];

    return NO; // we don't really want to select the column
}


/* Categories tableView methods */


- (NSString *) selectedCategory
{
    NSString *category = nil;
    if ([_tableView selectedRow] > 0)  // index 0 == ALL 
    {
        category = [[_app categories] objectAtIndex: [_tableView selectedRow]];
    }
    return category;
}


- (int) numberOfRowsInTableView: (NSTableView *)tableView
{
    return [[_app categories] count];
}


- (id) tableView: (NSTableView *)tableView objectValueForTableColumn: (NSTableColumn *)tableColumn row: (int)row
{
    return [[_app categories] objectAtIndex: row];
}


- (void) tableViewSelectionDidChange: (NSNotification *)aNotification 
{
    [self clearSearchField: self];
    [self reloadTableViews];
}


/** Toolbar **/

 
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *)itemIdentifier willBeInsertedIntoToolbar: (BOOL)flag
/*
    Given an item identifier, this method creates and returns an item based on the information in the userdefaults dictionary.
*/
{
    NSToolbarItem *item = nil;
    NSDictionary *toolbarItemDict = [[[[NSUserDefaults standardUserDefaults] objectForKey: [toolbar identifier]] objectForKey: @"itemInfoByIdentifier"] objectForKey: itemIdentifier];
    if (toolbarItemDict)
    { 
        item = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier];
		[item setLabel: NSLocalizedString([toolbarItemDict objectForKey: @"label"], @"toolbar item label")];
        if ([toolbarItemDict objectForKey: @"paletteLabel"])
        {
            [item setPaletteLabel: NSLocalizedString([toolbarItemDict objectForKey: @"paletteLabel"], @"toolbar item palette label")];
        }
        else
        {
            [item setPaletteLabel: [item label]];
        }
        [item setToolTip: NSLocalizedString([toolbarItemDict objectForKey: @"toolTip"], @"toolbar item tool tip")];
        if ([toolbarItemDict objectForKey: @"view"])
        {
            NSView *aView = [self valueForKey: [toolbarItemDict objectForKey: @"view"]];
            [item setView: aView];
            [item setMinSize: [aView bounds].size];
        }
        else
        {
			SEL selector =  NSSelectorFromString([toolbarItemDict objectForKey: @"action"]);
            [item setImage: [NSImage imageNamed: [toolbarItemDict objectForKey: @"imageName"]]];
            [item setAction: selector];
            [item setTarget: ([self respondsToSelector: selector] ? self : nil)];
        }
    }
    return item;
}

    
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar;
/* 
    Returns the ordered list of items to be shown in the toolbar by default.
*/
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey: [toolbar identifier]] objectForKey: @"defaultItemIdentifiers"];
}


- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar;
/* 
    Returns the list of all allowed items by identifier.
*/
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey: [toolbar identifier]] objectForKey: @"allowedItemIdentifiers"];
}


- (void) toolbarWillAddItem: (NSNotification *)notification
{
	NSToolbarItem *item = [[notification userInfo] objectForKey: @"item"];
	if ([[item itemIdentifier] isEqualToString: NSToolbarPrintItemIdentifier])
	{
		[item setTarget: self];
	}
}


- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem 
{
    return YES;
}


- (void) controlTextDidChange: (NSNotification *)aNotification
/*
    Handles automated searching when you start typing in the search textfield and then pause for more than .5 seconds
*/
{
	[[self class] cancelPreviousPerformRequestsWithTarget: self 
		selector: @selector(search:) 
		object: [aNotification object]];
	[self performSelector: @selector(search:) 
		withObject: [aNotification object] 
		afterDelay: 0.5];
}


- (IBAction) search: (id)sender
{
	if (![[_searchTextField stringValue] isEqualToString: _searchString])
	{		
		[[self class] cancelPreviousPerformRequestsWithTarget: self 
			selector: @selector(search:) 
			object: sender];
        [_searchString release];
        _searchString = [[_searchTextField stringValue] copy];
		[self reloadTableViews];
	}
}


- (IBAction) clearSearchField: (id)sender
{
    [_searchTextField setStringValue: @""];
    [self search: sender];
}
    
    
- (IBAction) install: (id)sender
{
    NSDictionary *port = [self selectedPort];
    [[PMConsole sharedConsole] showWindow: self];
    [_app executeTarget: DPInstallTarget forPortName: [port objectForKey: DPNameKey]];
}


- (IBAction) build: (id)sender
{
    NSDictionary *port = [self selectedPort];
    [[PMConsole sharedConsole] showWindow: self];
    [_app executeTarget: DPBuildTarget forPortName: [port objectForKey: DPNameKey]];
}


- (IBAction) checksum: (id)sender
{
    NSDictionary *port = [self selectedPort];
    [[PMConsole sharedConsole] showWindow: self];
    [_app executeTarget: DPChecksumTarget forPortName: [port objectForKey: DPNameKey]];
}


- (IBAction) clean: (id)sender
{
    NSDictionary *port = [self selectedPort];
    [[PMConsole sharedConsole] showWindow: self];
    [_app executeTarget: DPCleanTarget forPortName: [port objectForKey: DPNameKey]];
}


- (IBAction) package: (id)sender
{
    NSDictionary *port = [self selectedPort];
    [[PMConsole sharedConsole] showWindow: self];
    [_app executeTarget: DPPackageTarget forPortName: [port objectForKey: DPNameKey]];
}


- (IBAction) fetch: (id)sender
{
    NSDictionary *port = [self selectedPort];
    [[PMConsole sharedConsole] showWindow: self];
    [_app executeTarget: DPFetchTarget forPortName: [port objectForKey: DPNameKey]];
}


- (IBAction) reload: (id)sender
{
    [(PMApp *)[NSApp delegate] resetPorts];
}


- (IBAction) showConsole: (id)sender
{
    [[PMConsole sharedConsole] showWindow: self];
}


- (void) printDocument: (id)sender
{
    [_textView print: sender];
}


@end
