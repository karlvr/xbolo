#import "GSKeyCodeField.h"
#include <Carbon/Carbon.h>

NSMutableDictionary *nameDictionary;

@implementation GSKeyCodeFieldCell
@synthesize keyCode;

+ (void)initialize {
  if (self == [GSKeyCodeFieldCell class]) {
    nameDictionary = [[NSMutableDictionary alloc] init];
    nameDictionary[[NSString stringWithFormat:@"%d", 0]] = @"A";
    nameDictionary[[NSString stringWithFormat:@"%d", 1]] = @"S";
    nameDictionary[[NSString stringWithFormat:@"%d", 2]] = @"D";
    nameDictionary[[NSString stringWithFormat:@"%d", 3]] = @"F";
    nameDictionary[[NSString stringWithFormat:@"%d", 4]] = @"H";
    nameDictionary[[NSString stringWithFormat:@"%d", 5]] = @"G";
    nameDictionary[[NSString stringWithFormat:@"%d", 6]] = @"Z";
    nameDictionary[[NSString stringWithFormat:@"%d", 7]] = @"X";
    nameDictionary[[NSString stringWithFormat:@"%d", 8]] = @"C";
    nameDictionary[[NSString stringWithFormat:@"%d", 9]] = @"V";

    nameDictionary[[NSString stringWithFormat:@"%d", 11]] = @"B";
    nameDictionary[[NSString stringWithFormat:@"%d", 12]] = @"Q";
    nameDictionary[[NSString stringWithFormat:@"%d", 13]] = @"W";
    nameDictionary[[NSString stringWithFormat:@"%d", 14]] = @"E";
    nameDictionary[[NSString stringWithFormat:@"%d", 15]] = @"R";
    nameDictionary[[NSString stringWithFormat:@"%d", 16]] = @"Y";
    nameDictionary[[NSString stringWithFormat:@"%d", 17]] = @"T";
    nameDictionary[[NSString stringWithFormat:@"%d", 18]] = @"1";
    nameDictionary[[NSString stringWithFormat:@"%d", 19]] = @"2";
    nameDictionary[[NSString stringWithFormat:@"%d", 20]] = @"3";
    nameDictionary[[NSString stringWithFormat:@"%d", 21]] = @"4";
    nameDictionary[[NSString stringWithFormat:@"%d", 22]] = @"6";
    nameDictionary[[NSString stringWithFormat:@"%d", 23]] = @"5";
    nameDictionary[[NSString stringWithFormat:@"%d", 24]] = @"=";
    nameDictionary[[NSString stringWithFormat:@"%d", 25]] = @"9";
    nameDictionary[[NSString stringWithFormat:@"%d", 26]] = @"7";
    nameDictionary[[NSString stringWithFormat:@"%d", 27]] = @"-";
    nameDictionary[[NSString stringWithFormat:@"%d", 28]] = @"8";
    nameDictionary[[NSString stringWithFormat:@"%d", 29]] = @"0";
    nameDictionary[[NSString stringWithFormat:@"%d", 30]] = @"]";
    nameDictionary[[NSString stringWithFormat:@"%d", 31]] = @"O";
    nameDictionary[[NSString stringWithFormat:@"%d", 32]] = @"U";
    nameDictionary[[NSString stringWithFormat:@"%d", 33]] = @"[";
    nameDictionary[[NSString stringWithFormat:@"%d", 34]] = @"I";
    nameDictionary[[NSString stringWithFormat:@"%d", 35]] = @"P";
    nameDictionary[[NSString stringWithFormat:@"%d", 36]] = @"Return";
    nameDictionary[[NSString stringWithFormat:@"%d", 37]] = @"L";
    nameDictionary[[NSString stringWithFormat:@"%d", 38]] = @"J";
    nameDictionary[[NSString stringWithFormat:@"%d", 39]] = @"'";
    nameDictionary[[NSString stringWithFormat:@"%d", 40]] = @"K";
    nameDictionary[[NSString stringWithFormat:@"%d", 41]] = @";";
    nameDictionary[[NSString stringWithFormat:@"%d", 42]] = @"\\";
    nameDictionary[[NSString stringWithFormat:@"%d", 43]] = @",";
    nameDictionary[[NSString stringWithFormat:@"%d", 44]] = @"/";
    nameDictionary[[NSString stringWithFormat:@"%d", 45]] = @"N";
    nameDictionary[[NSString stringWithFormat:@"%d", 46]] = @"M";
    nameDictionary[[NSString stringWithFormat:@"%d", 47]] = @".";
    nameDictionary[[NSString stringWithFormat:@"%d", 48]] = @"Tab";
    nameDictionary[[NSString stringWithFormat:@"%d", 49]] = @"Spacebar";
    nameDictionary[[NSString stringWithFormat:@"%d", 50]] = @"`";
    nameDictionary[[NSString stringWithFormat:@"%d", 51]] = @"Delete";
    nameDictionary[[NSString stringWithFormat:@"%d", 52]] = @"Enter";
    nameDictionary[[NSString stringWithFormat:@"%d", 53]] = @"Escape";

    nameDictionary[[NSString stringWithFormat:@"%d", 55]] = @"Command";
    nameDictionary[[NSString stringWithFormat:@"%d", 56]] = @"Shift";
    nameDictionary[[NSString stringWithFormat:@"%d", 57]] = @"Caps Lock";
    nameDictionary[[NSString stringWithFormat:@"%d", 58]] = @"Option";
    nameDictionary[[NSString stringWithFormat:@"%d", 59]] = @"Control";
    nameDictionary[[NSString stringWithFormat:@"%d", 60]] = @"Fn Shift";


    nameDictionary[[NSString stringWithFormat:@"%d", 63]] = @"Function";

    nameDictionary[[NSString stringWithFormat:@"%d", 65]] = @".";

    nameDictionary[[NSString stringWithFormat:@"%d", 67]] = @"*";

    nameDictionary[[NSString stringWithFormat:@"%d", 69]] = @"+";

    nameDictionary[[NSString stringWithFormat:@"%d", 71]] = @"Clear";



    nameDictionary[[NSString stringWithFormat:@"%d", 75]] = @"/";
    nameDictionary[[NSString stringWithFormat:@"%d", 76]] = @"Enter";

    nameDictionary[[NSString stringWithFormat:@"%d", 78]] = @"-";


    nameDictionary[[NSString stringWithFormat:@"%d", 81]] = @"=";
    nameDictionary[[NSString stringWithFormat:@"%d", 82]] = @"0";
    nameDictionary[[NSString stringWithFormat:@"%d", 83]] = @"1";
    nameDictionary[[NSString stringWithFormat:@"%d", 84]] = @"2";
    nameDictionary[[NSString stringWithFormat:@"%d", 85]] = @"3";
    nameDictionary[[NSString stringWithFormat:@"%d", 86]] = @"4";
    nameDictionary[[NSString stringWithFormat:@"%d", 87]] = @"5";
    nameDictionary[[NSString stringWithFormat:@"%d", 88]] = @"6";
    nameDictionary[[NSString stringWithFormat:@"%d", 89]] = @"7";

    nameDictionary[[NSString stringWithFormat:@"%d", 91]] = @"8";
    nameDictionary[[NSString stringWithFormat:@"%d", 92]] = @"9";



    nameDictionary[[NSString stringWithFormat:@"%d", 96]] = @"F5";
    nameDictionary[[NSString stringWithFormat:@"%d", 97]] = @"F6";
    nameDictionary[[NSString stringWithFormat:@"%d", 98]] = @"F7";
    nameDictionary[[NSString stringWithFormat:@"%d", 99]] = @"F3";
    nameDictionary[[NSString stringWithFormat:@"%d", 100]] = @"F8";
    nameDictionary[[NSString stringWithFormat:@"%d", 101]] = @"F9";
    
    nameDictionary[[NSString stringWithFormat:@"%d", 103]] = @"F11";







    nameDictionary[[NSString stringWithFormat:@"%d", 109]] = @"F10";
    nameDictionary[[NSString stringWithFormat:@"%d", 110]] = @"Fn Enter";
    nameDictionary[[NSString stringWithFormat:@"%d", 111]] = @"F12";
    
    
    
    nameDictionary[[NSString stringWithFormat:@"%d", 115]] = @"Home";
    nameDictionary[[NSString stringWithFormat:@"%d", 116]] = @"Page Up";
    nameDictionary[[NSString stringWithFormat:@"%d", 117]] = @"Fn Delete";
    nameDictionary[[NSString stringWithFormat:@"%d", 118]] = @"F4";
    nameDictionary[[NSString stringWithFormat:@"%d", 119]] = @"End";
    nameDictionary[[NSString stringWithFormat:@"%d", 120]] = @"F2";
    nameDictionary[[NSString stringWithFormat:@"%d", 121]] = @"Page Down";
    nameDictionary[[NSString stringWithFormat:@"%d", 122]] = @"F1";
    nameDictionary[[NSString stringWithFormat:@"%d", 123]] = @"Left Arrow";
    nameDictionary[[NSString stringWithFormat:@"%d", 124]] = @"Right Arrow";
    nameDictionary[[NSString stringWithFormat:@"%d", 125]] = @"Down Arrow";
    nameDictionary[[NSString stringWithFormat:@"%d", 126]] = @"Up Arrow";
    nameDictionary[[NSString stringWithFormat:@"%d", 127]] = @"Num Lock";
  }
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
    string = nameDictionary[[NSString stringWithFormat:@"%hu", keyCode]];
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
