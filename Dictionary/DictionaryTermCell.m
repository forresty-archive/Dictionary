//
//  DictionaryTermCell.m
//  Dictionary
//
//  Created by Forrest Ye on 7/1/13.
//
//

#import "DictionaryTermCell.h"
#import "DictionaryViewDefinitions.h"

@implementation DictionaryTermCell

- (instancetype)init {
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDictionaryTermCellID];

  if (self) {
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    backgroundView.backgroundColor = DICTIONARY_BASIC_TINT_COLOR;
    self.selectedBackgroundView = backgroundView;
  }

  return self;
}


- (void)changeToType:(DictionaryTableViewCellType)type withText:(NSString *)text {
  self.tag = type;
  self.selectionStyle = UITableViewCellSelectionStyleBlue;
  self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  self.textLabel.textAlignment = NSTextAlignmentLeft;
  self.textLabel.font = DICTIONARY_BASIC_TEXT_FONT;
  self.textLabel.text = text;
  self.textLabel.textColor = DICTIONARY_BASIC_TEXT_COLOR;
  self.textLabel.highlightedTextColor = DICTIONARY_BASIC_TEXT_COLOR;

  switch (type) {
    case DictionaryTableViewCellTypeAction:
      return [self makeActionWithText:text];
    case DictionaryTableViewCellTypeDisabled:
      return [self disableWithText:text];
    default:
      break;
  }
}


- (void)disableWithText:(NSString *)text {
  self.textLabel.textColor = [UIColor grayColor];
  self.selectionStyle = UITableViewCellSelectionStyleNone;
  self.accessoryType = UITableViewCellAccessoryNone;
}


- (void)makeActionWithText:(NSString *)text {
  self.textLabel.textAlignment = NSTextAlignmentCenter;
  self.accessoryType = UITableViewCellAccessoryNone;
  self.textLabel.font = DICTIONARY_BASIC_ACTION_FONT;
}


@end
