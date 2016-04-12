#import <Cocoa/Cocoa.h>

@interface GSKeyCodeFieldCell : NSActionCell {
  unsigned short keyCode;
}
- (id)initWithKeyCode:(unsigned short)aKeyCode;
@property (nonatomic) unsigned short keyCode;
- (IBAction)takeKeyValueFrom:(id)sender;
@end

@interface GSKeyCodeField : NSControl {
  unsigned int modifiers;
}
@property unsigned short keyCode;
- (IBAction)takeKeyValueFrom:(id)sender;
@end
