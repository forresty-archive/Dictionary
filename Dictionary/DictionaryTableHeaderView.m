//
//  DictionaryTableHeaderView.m
//  Dictionary
//
//  Created by Forrest Ye on 7/2/13.
//
//

#import "DictionaryTableHeaderView.h"

#import "DictionaryViewDefinitions.h"

@interface DictionaryTableHeaderView ()

@end

@implementation DictionaryTableHeaderView


+ (instancetype)viewWithText:(NSString *)text {
  DictionaryTableHeaderView *view = [self sharedInstanceWithText:text];

  return view;
}


# pragma mark - private


+ (instancetype)sharedInstanceWithText:(NSString *)text {
  static NSMutableDictionary* _instances = nil;


  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    _instances = [@{} mutableCopy];
  });

  if (!_instances[text]) {
    DictionaryTableHeaderView *view = [[self alloc] initWithText:text];
    _instances[text] = view;
  }

  return _instances[text];
}


- (instancetype)initWithText:(NSString *)text {
  self = [super initWithFrame:CGRectMake(0, 0, 320, 30)];

  if (self) {
    self.backgroundColor = DICTIONARY_BASIC_TEXT_COLOR;
    self.alpha = 0.9;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 310, 30)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
    label.text = text;

    [self addSubview:label];
  }

  return self;
}


@end
