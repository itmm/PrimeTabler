@import Foundation;
@import Quartz;

@interface Entry : NSObject

    + (instancetype) entryWithValue: (NSInteger) value;

    @property (readonly) NSInteger value;
    @property NSColor *color;

@end
