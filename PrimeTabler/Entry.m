#import "Entry.h"

@implementation Entry

    - (instancetype) initWithValue: (NSInteger) value {
        if (self = [super init]) {
            _value = value;
            _color = NSColor.whiteColor;
        }
        return self;
    }

    + (instancetype) entryWithValue: (NSInteger) value {
        return [[Entry alloc] initWithValue: value];
    }

@end
