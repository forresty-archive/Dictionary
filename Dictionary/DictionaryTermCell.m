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
  switch (type) {
    case DictionaryTableViewCellTypeNormal:
      return [self makeCell:self withText:text type:type];
    case DictionaryTableViewCellTypeAction:
      return [self makeActionWithText:text];
    case DictionaryTableViewCellTypeDisabled:
      return [self disableWithText:text];
  }
}


- (void)disableWithText:(NSString *)text {
  [self makeCell:self withText:text type:DictionaryTableViewCellTypeDisabled];

  self.textLabel.textColor = [UIColor grayColor];
  self.selectionStyle = UITableViewCellSelectionStyleNone;
  self.accessoryType = UITableViewCellAccessoryNone;
}


- (void)makeActionWithText:(NSString *)text {
  [self makeCell:self withText:text type:DictionaryTableViewCellTypeAction];

  self.textLabel.textAlignment = NSTextAlignmentCenter;
  self.accessoryType = UITableViewCellAccessoryNone;
  self.textLabel.font = DICTIONARY_BASIC_ACTION_FONT;
}


# pragma mark private


- (void)makeCell:(UITableViewCell *)cell withText:(NSString *)text type:(DictionaryTableViewCellType)type {
  cell.tag = type;
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.textLabel.textAlignment = NSTextAlignmentLeft;
  cell.textLabel.font = DICTIONARY_BASIC_TEXT_FONT;
  cell.textLabel.text = text;
  cell.textLabel.textColor = DICTIONARY_BASIC_TEXT_COLOR;
  cell.textLabel.highlightedTextColor = DICTIONARY_BASIC_TEXT_COLOR;
}

@end
