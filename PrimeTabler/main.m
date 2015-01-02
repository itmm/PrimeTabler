@import Foundation;
@import Quartz;
@import CoreText;

#import "Entry.h"

static const NSInteger kColumns = 8;
static const NSInteger kRows = 10;
static const CGFloat kWidth = 824;
static const CGFloat kHeight = 475;
static const CGFloat kCellWidth = kWidth/kColumns;
static const CGFloat kCellHeight = kHeight/kRows;
static const NSInteger kCount = kColumns * kRows;

static const NSString *kFontName = @"Menlo-Regular";
static const CGFloat kFontSize = 40;

static CTFontRef font = NULL;

static void drawEntryAtIndex(CGContextRef ctx, Entry *entry, NSInteger index) {
    if (!entry.value) return;
    
    NSString *value = [NSString stringWithFormat: @"%d", (int) entry.value];
    NSAttributedString *attributedValue = [[NSAttributedString alloc] initWithString: value
        attributes: @{
            (NSString *) kCTFontAttributeName: (__bridge NSFont *) font,
            (NSString *)kCTForegroundColorAttributeName: (__bridge id) entry.color.CGColor
    }];
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef) attributedValue);
    
    NSInteger column = index % kColumns;
    NSInteger row = index / kColumns;
    
    CGRect frame = CGRectMake(column * kCellWidth, (kRows - 1 - row) * kCellHeight, kCellWidth, kCellHeight);
    CGRect textFrame = CTLineGetBoundsWithOptions(line, 0);
    CGPoint textOrigin = CGPointMake(
        frame.origin.x + (frame.size.width - textFrame.size.width)/2 - textFrame.origin.x,
        frame.origin.y + (frame.size.height - textFrame.size.height)/2 - textFrame.origin.y
    );
    CGContextSetTextPosition(ctx, textOrigin.x, textOrigin.y);
    CTLineDraw(line, ctx);
    CFRelease(line);
}

static NSMutableData *data = nil;

static size_t consumer_put(void *info, const void *buffer, size_t count) {
    NSMutableData *data = (__bridge NSMutableData *)(info);
    [data appendBytes: buffer length: count];
    return count;
}


static void consumer_release(void *info) {
    NSMutableData *data = (__bridge NSMutableData *)(info);
    static NSInteger outCount = 0;
    NSString *path = [[NSString stringWithFormat: @"~/Desktop/out_%d.pdf", (int) ++outCount] stringByExpandingTildeInPath];
    [data writeToFile: path atomically: YES];
}

static void render(NSArray *entries) {
    data = [NSMutableData new];
    CGDataConsumerCallbacks callbacks = { consumer_put, consumer_release };
    CGDataConsumerRef consumer = CGDataConsumerCreate((__bridge void *)(data), &callbacks);
    if (!consumer) { NSLog(@"Can't create consumer"); return; }
    
    CGRect mediaBox = CGRectMake(0, 0, kWidth, kHeight);
    CGContextRef ctx = CGPDFContextCreate(consumer, &mediaBox, NULL);
    if (!ctx) { NSLog(@"Can't create context"); CGDataConsumerRelease(consumer); return; }
    
    font = CTFontCreateWithName((CFStringRef) kFontName, kFontSize, NULL);
    CGPDFContextBeginPage(ctx, NULL);
    for (NSInteger i = 0; i < entries.count; ++i) {
        drawEntryAtIndex(ctx, entries[i], i);
    }
    CGPDFContextEndPage(ctx);
    
    CFRelease(font); font = NULL;
    CGContextRelease(ctx);
    
    CGDataConsumerRelease(consumer);
}

NSMutableArray *initial() {
    NSMutableArray *entries = [NSMutableArray new];
    for (NSInteger i = 0, j = 2; i < kCount; ++i, ++j) {
        [entries addObject: [Entry entryWithValue: j]];
    }
    return entries;
}

void classicalSieve() {
    NSMutableArray *entries = initial();
    render(entries);
    
    NSInteger pivotIndex = 0;
    double limit = sqrt(entries.count);
    while (pivotIndex < limit) {
        Entry *e = entries[pivotIndex];
        e.color = NSColor.greenColor;
        render(entries);
        BOOL somethingChanged = NO;
        NSInteger nextPivotIndex = -1;
        for (NSInteger j = pivotIndex + 1; j < entries.count; ++j) {
            Entry *n = entries[j];
            if ((n.value % e.value) == 0 && n.color == NSColor.whiteColor) {
                n.color = NSColor.darkGrayColor;
                somethingChanged = YES;
            } else if (nextPivotIndex == -1 && n.color != NSColor.darkGrayColor) {
                nextPivotIndex = j;
            }
        }
        if (somethingChanged) render(entries);
        pivotIndex = nextPivotIndex >= 0 ? nextPivotIndex : entries.count;
    }
    
    BOOL somethingChanged = NO;
    for (Entry *e in entries) {
        if (e.color == NSColor.whiteColor) {
            e.color = NSColor.greenColor;
            somethingChanged = YES;
        }
    }
    if (somethingChanged) render(entries);
}

void streamSieve() {
    NSMutableArray *entries = initial();
    NSMutableArray *summary = [NSMutableArray new];
    NSMutableArray *summaries = [NSMutableArray new];
    render(entries);
    
    NSInteger next = ((Entry *) entries.lastObject).value + 1;
    for (NSInteger pivotIndex = 0; pivotIndex < entries.count; ++pivotIndex) {
        Entry *p = entries[pivotIndex];
        p.color = NSColor.greenColor;
        render(entries);
        BOOL somethingChanged = NO;
        for (NSInteger j = pivotIndex + 1; j < entries.count; ++j) {
            Entry *e = entries[j];
            if ((e.value % p.value) == 0) {
                e.color = NSColor.darkGrayColor;
                somethingChanged = YES;
            }
        }
        if (somethingChanged) {
            render(entries);
            if (summary.count < kCount) {
                for (NSInteger j = 0; j < kColumns; ++j) {
                    Entry *old = entries[j];
                    Entry *new = [Entry entryWithValue: old.value];
                    new.color = old.color;
                    [summary addObject: new];
                }
                [summaries addObject: [NSArray arrayWithArray: summary]];
            }
            for (NSInteger j = pivotIndex + 1; j < entries.count; ) {
                Entry *e = entries[j];
                if (e.color == NSColor.darkGrayColor) {
                    [entries removeObjectAtIndex: j];
                } else ++j;
            }
            render(entries);
            while (entries.count < kCount) {
                BOOL found = NO;
                while (!found) {
                    found = YES;
                    for (NSInteger i = 0; i < pivotIndex; ++i) {
                        Entry *e = entries[i];
                        if ((next % e.value) == 0) { found = NO; break; }
                    }
                    if (found) [entries addObject: [Entry entryWithValue: next]];
                    ++next;
                }
            }
            render(entries);
        }
    }
    for (NSArray *sum in summaries) {
        render(sum);
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        classicalSieve();
        streamSieve();
    }
    return 0;
}
