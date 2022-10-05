#import "GSKeyCodeField.h"
#include <Carbon/Carbon.h>

NSDictionary<NSNumber*, NSString*> *nameDictionary;

@implementation GSKeyCodeFieldCell
@synthesize keyCode;

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nameDictionary = @{
      @0: @"A",
      @1: @"S",
      @2: @"D",
      @3: @"F",
      @4: @"H",
      @5: @"G",
      @6: @"Z",
      @7: @"X",
      @8: @"C",
      @9: @"V",

      @11: @"B",
      @12: @"Q",
      @13: @"W",
      @14: @"E",
      @15: @"R",
      @16: @"Y",
      @17: @"T",
      @18: @"1",
      @19: @"2",
      @20: @"3",
      @21: @"4",
      @22: @"6",
      @23: @"5",
      @24: @"=",
      @25: @"9",
      @26: @"7",
      @27: @"-",
      @28: @"8",
      @29: @"0",
      @30: @"]",
      @31: @"O",
      @32: @"U",
      @33: @"[",
      @34: @"I",
      @35: @"P",
      @36: @"Return",
      @37: @"L",
      @38: @"J",
      @39: @"'",
      @40: @"K",
      @41: @";",
      @42: @"\\",
      @43: @",",
      @44: @"/",
      @45: @"N",
      @46: @"M",
      @47: @".",
      @48: @"Tab",
      @49: @"Spacebar",
      @50: @"`",
      @51: @"Delete",
      @52: @"Enter",
      @53: @"Escape",

      @55: @"Command",
      @56: @"Shift",
      @57: @"Caps Lock",
      @58: @"Option",
      @59: @"Control",
      @60: @"Fn Shift",


      @63: @"Function",

      @65: @".",

      @67: @"*",

      @69: @"+",

      @71: @"Clear",



      @75: @"/",
      @76: @"Enter",

      @78: @"-",


      @81: @"=",
      @82: @"0",
      @83: @"1",
      @84: @"2",
      @85: @"3",
      @86: @"4",
      @87: @"5",
      @88: @"6",
      @89: @"7",

      @91: @"8",
      @92: @"9",



      @96: @"F5",
      @97: @"F6",
      @98: @"F7",
      @99: @"F3",
      @100: @"F8",
      @101: @"F9",
      
      @103: @"F11",







      @109: @"F10",
      @110: @"Fn Enter",
      @111: @"F12",
      
      
      
      @115: @"Home",
      @116: @"Page Up",
      @117: @"Fn Delete",
      @118: @"F4",
      @119: @"End",
      @120: @"F2",
      @121: @"Page Down",
      @122: @"F1",
      @123: @"Left Arrow",
      @124: @"Right Arrow",
      @125: @"Down Arrow",
      @126: @"Up Arrow",
      @127: @"Num Lock",
    };
  });
}

// ---------------------------------------------------------
//  Initialization
// ---------------------------------------------------------

- (instancetype)init {
  return [self initWithKeyCode:(unsigned short)-1];
}

- (instancetype)initWithKeyCode:(unsigned short)aKeyCode {
  if ((self = [super init]) != nil) {
    keyCode = aKeyCode;
  }
  return self;
}

- (instancetype)initTextCell:(NSString *)string {
  return [self initWithKeyCode:(unsigned short)-1];
}

- (instancetype)initImageCell:(NSImage *)image {
  return [self initWithKeyCode:(unsigned short)-1];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super initWithCoder:decoder];
  if (decoder.allowsKeyedCoding) {
    keyCode = [decoder decodeIntForKey:@"GSKeyCode"];
  }
  else {
    [decoder decodeValueOfObjCType:@encode(unsigned short) at:&keyCode];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  if (coder.allowsKeyedCoding) {
    [coder encodeInt:keyCode forKey:@"GSKeyCode"];
  }
  else {
    [coder encodeValueOfObjCType:@encode(unsigned short) at:&keyCode];
  }
}

- (id)copyWithZone:(NSZone *)zone {
  return [[GSKeyCodeFieldCell allocWithZone:zone] initWithKeyCode:self.keyCode];
}

- (void)sendActionToTarget {
  if (self.target && self.action) {
    [(NSControl *)self.controlView sendAction:self.action to:self.target];
  }
}

// ---------------------------------------------------------
//  Setting and getting values
// ---------------------------------------------------------

- (void)setKeyCode:(unsigned short)aKeyCode {
  if (keyCode != aKeyCode) {
    keyCode = aKeyCode;
    [(NSControl *)self.controlView updateCell:self];
    [self sendActionToTarget];
  }
}

- (void)setObjectValue:(id)object {
  if ([object isMemberOfClass:[NSString class]]) {
    self.stringValue = object;
  }
  else {
    [NSException raise: NSInvalidArgumentException format: @"%@ Invalid object %@", NSStringFromSelector(_cmd), object];
  }
}

- (id)objectValue {
  return self.stringValue;
}

- (void)setStringValue:(NSString *)string {
  int aKeyCode;
  NSScanner *scanner;
  scanner = [NSScanner scannerWithString:string];
  if ([scanner scanInt:&aKeyCode] && scanner.atEnd) {
    self.keyCode = aKeyCode;
  }
  else {
    [NSException raise: NSInvalidArgumentException format: @"%@ Invalid string %@", NSStringFromSelector(_cmd), string];
  }
}

- (NSString *)stringValue {
  return [NSString stringWithFormat:@"%d", keyCode];
}

// ---------------------------------------------------------
//  Target / action methods
// ---------------------------------------------------------

- (IBAction)takeKeyValueFrom:(id)sender {
  if ([sender isMemberOfClass:[GSKeyCodeFieldCell class]]) {
    self.keyCode = [sender keyCode];
  }
  else {
    self.stringValue = [sender stringValue];
  }
}

// ---------------------------------------------------------
//  Drawing Routines
// ---------------------------------------------------------

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  NSString *string;
  NSRect insetRect;

  insetRect = NSInsetRect(cellFrame, 5.0, 3.0);

  if (keyCode == (unsigned short)-1) {
    string = [NSString string];
  }
  else {
    string = nameDictionary[@(keyCode)];
    if (string == nil) {
      string = [NSString stringWithFormat:@"%hu", keyCode];
    }
  }

  NSDrawWhiteBezel(cellFrame, cellFrame);

  if (self.showsFirstResponder) {
    if (string.length == 0) {
      [[NSColor selectedTextBackgroundColor] set];
      NSRectFill(insetRect);
    }
    else {
      NSDictionary *attributes;
      NSSize textSize;
      NSRect textRect, drawRect;
      attributes = @{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:self.controlSize]], NSBackgroundColorAttributeName: [NSColor selectedTextBackgroundColor], NSForegroundColorAttributeName: [NSColor selectedTextColor]};
      textSize = [string sizeWithAttributes:attributes];
      textRect = NSMakeRect(NSMinX(insetRect), NSMaxY(insetRect) - textSize.height + 5.0, textSize.width, textSize.height);
      drawRect = NSIntersectionRect(NSUnionRect(insetRect, textRect), insetRect);
      [string drawInRect:drawRect withAttributes:attributes];
    }

    [NSGraphicsContext saveGraphicsState];
    NSSetFocusRingStyle(NSFocusRingOnly);
    [[NSBezierPath bezierPathWithRect:NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height)] fill];
    [NSGraphicsContext restoreGraphicsState];
  }
  else {
    NSDictionary *attributes;
    NSSize textSize;
    NSRect textRect, drawRect;
    attributes = @{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:self.controlSize]], NSBackgroundColorAttributeName: [NSColor textBackgroundColor], NSForegroundColorAttributeName: [NSColor selectedTextColor]};
    textSize = [string sizeWithAttributes:attributes];
    textRect = NSMakeRect(NSMinX(insetRect), NSMaxY(insetRect) - textSize.height + 5.0, textSize.width, textSize.height);
    drawRect = NSIntersectionRect(NSUnionRect(insetRect, textRect), insetRect);
    [string drawInRect:drawRect withAttributes:attributes];
  }
}

// ---------------------------------------------------------
//  Mouse Tracking
// ---------------------------------------------------------

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
	[(NSControl *)controlView updateCell:self];
  return YES;
}

// ---------------------------------------------------------
//  Context Menu
// ---------------------------------------------------------

- (NSMenu *)menuForEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
  return nil;
}

// ---------------------------------------------------------
//  Keyboard Event Handling : Binding Methods
// ---------------------------------------------------------

- (void)performClick:(id)sender {
}

@end

@implementation GSKeyCodeField

+ (void)initialize {
  if (self == [GSKeyCodeField class]) {
    [self setCellClass:[GSKeyCodeFieldCell class]];
  }
}

+ (Class)cellClass {
  return [GSKeyCodeFieldCell class];
}

- (instancetype)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect]) != nil) {
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)performClick:(id)sender {
  [self.cell performClick:sender];
}

- (void)setKeyCode:(unsigned short)aKeyCode {
  [self.cell setKeyCode:aKeyCode];
}

- (unsigned short)keyCode {
  return [self.cell keyCode];
}

- (IBAction)takeKeyValueFrom:(id)sender {
  [self.cell takeKeyValueFrom:sender];
}

// ---------------------------------------------------------
//  Focus ring maintenance
// ---------------------------------------------------------

- (BOOL)becomeFirstResponder {
  BOOL okToChange;
  if ((okToChange = [super becomeFirstResponder])) {
    UInt32 carbonModifiers;
    [super setKeyboardFocusRingNeedsDisplayInRect:self.bounds];
    carbonModifiers = GetCurrentKeyModifiers();
    modifiers =
    (carbonModifiers & alphaLock ? NSEventModifierFlagCapsLock : 0) |
    (carbonModifiers & shiftKey || carbonModifiers & rightShiftKey ? NSEventModifierFlagShift : 0) |
    (carbonModifiers & controlKey || carbonModifiers & rightControlKey ? NSEventModifierFlagControl : 0) |
    (carbonModifiers & optionKey || carbonModifiers & rightOptionKey ? NSEventModifierFlagOption : 0) |
    (carbonModifiers & cmdKey ? NSEventModifierFlagCommand : 0);
//    (carbonModifiers &  ? NSNumericPadKeyMask : 0) |
//    (carbonModifiers &  ? NSHelpKeyMask : 0) |
//    (carbonModifiers &  ? NSFunctionKeyMask : 0);
  }
  return okToChange;
}

- (BOOL)resignFirstResponder {
  BOOL okToChange;
  okToChange = [super resignFirstResponder];
  if (okToChange) {
    [super setKeyboardFocusRingNeedsDisplayInRect:self.bounds];
  }
  return okToChange;
}

- (void)windowKeyStateDidChange:(NSNotification *)notif {
  if (self.window.firstResponder == self) {
    [super setKeyboardFocusRingNeedsDisplayInRect:self.bounds];
  }
}

- (void)viewDidMoveToWindow {
  NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
  SEL callback = @selector(windowKeyStateDidChange:);

  // If we've been installed in a new window, unregister for notificaions in the old window...
  [notifCenter removeObserver:self];

  // ... then register for notifications in the new window.
  [notifCenter addObserver:self selector:callback name:NSWindowDidBecomeKeyNotification object:self.window];
  [notifCenter addObserver:self selector:callback name:NSWindowDidResignKeyNotification object:self.window];
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (BOOL)needsPanelToBecomeKey {
  return YES;		// Clicking and tabbing to us will makes us key
}

- (void)keyDown:(NSEvent *)theEvent {
  if (!theEvent.ARepeat) {
    [self.cell setKeyCode:theEvent.keyCode];
    [self.window selectNextKeyView:self];
  }
}

- (void)keyUp:(NSEvent *)theEvent {
  if (!theEvent.ARepeat) {
    // do nothing
  }
}

- (void)flagsChanged:(NSEvent *)theEvent {
  NSEventModifierFlags oldModifiers;
  oldModifiers = modifiers;
  modifiers = theEvent.modifierFlags & (NSEventModifierFlagCapsLock | NSEventModifierFlagShift | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagCommand | NSEventModifierFlagNumericPad | NSEventModifierFlagHelp | NSEventModifierFlagFunction);
  if (modifiers & (oldModifiers ^ modifiers)) {
    [self.cell setKeyCode:theEvent.keyCode];
    [self.window selectNextKeyView:self];
  }
  else {
    // do nothing
  }
}

@end
