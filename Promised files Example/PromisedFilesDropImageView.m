//
//  PromisedFilesDropImageView.m
//  Promised files Example
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Zhi-Wei Cai.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "PromisedFilesDropImageView.h"

@implementation PromisedFilesDropImageView

#pragma mark - Drag and Drop

- (void)awakeFromNib
{
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType, nil]];
}

- (BOOL)hasPromisedFiles:(id <NSDraggingInfo>)sender
{
    // Could be other types, but we need the URLs.
    NSArray *relevantTypes = @[@"com.apple.pasteboard.promised-file-url"];
    for (NSPasteboardItem *item in [[sender draggingPasteboard] pasteboardItems]) {
        if ([item availableTypeFromArray:relevantTypes] != nil) {
            return YES;
        }
    }
    return NO;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return ([self hasPromisedFiles:sender] == YES) ? NSDragOperationCopy : NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return [self draggingEntered:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return [self hasPromisedFiles:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSString *filename;
    
    // We need to create a directory for those "promised" files.
    NSURL *tempURL = [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                             stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];
    
    if ([[NSFileManager defaultManager] createDirectoryAtURL:tempURL
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil] == YES &&
        (filename = [[sender namesOfPromisedFilesDroppedAtDestination:tempURL] firstObject]) != nil) {
        
        tempURL = [tempURL URLByAppendingPathComponent:filename];
        
        NSLog(@"File: %@", tempURL);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (![[NSFileManager defaultManager] isReadableFileAtPath:[tempURL path]]) {
                // We need to wait for the file to be avaliable.
                // This is ugly as hell. You better use File System Events
                // API of the CoreService framework.
            };
            dispatch_async(dispatch_get_main_queue(), ^{
                // File is ready, do what you want.
                self.image = [[NSImage alloc] initWithContentsOfURL:tempURL];
                // You can remove the file from temp here.
                [[NSFileManager defaultManager] removeItemAtURL:tempURL
                                                          error:nil];
            });
        });
        return YES;
    }
    return NO;
}

@end
