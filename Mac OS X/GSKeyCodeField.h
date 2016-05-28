#import <Cocoa/Cocoa.h>

@interface GSKeyCodeFieldCell : NSActionCell {
  unsigned short keyCode;
}
- (instancetype)initWithKeyCode:(unsigned short)aKeyCode NS_DESIGNATED_INITIALIZER;
@property (nonatomic) unsigned short keyCode;
- (IBAction)takeKeyValueFrom:(id)sender;
@end

@interface GSKeyCodeField : NSControl {
  NSEventModifierFlags modifiers;
}
@property unsigned short keyCode;
- (IBAction)takeKeyValueFrom:(id)sender;
@end
