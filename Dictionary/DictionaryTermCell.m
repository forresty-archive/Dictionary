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
  self.textLabel.highlightedTextColor = DICTIONARY_BASIC_TEXT_COLOR;
  self.textLabel.text = text;

  switch (type) {
    case DictionaryTableViewCellTypeNormal: {
      self.selectionStyle = UITableViewCellSelectionStyleBlue;
      self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      self.textLabel.textAlignment = NSTextAlignmentLeft;
      self.textLabel.font = DICTIONARY_BASIC_TEXT_FONT;
      self.textLabel.textColor = DICTIONARY_BASIC_TEXT_COLOR;
      break;
    }
    case DictionaryTableViewCellTypeAction: {
      self.selectionStyle = UITableViewCellSelectionStyleBlue;
      self.accessoryType = UITableViewCellAccessoryNone;
      self.textLabel.textAlignment = NSTextAlignmentCenter;
      self.textLabel.font = DICTIONARY_BASIC_ACTION_FONT;
      self.textLabel.textColor = DICTIONARY_BASIC_TEXT_COLOR;
      break;
    }
    case DictionaryTableViewCellTypeDisabled: {
      self.selectionStyle = UITableViewCellSelectionStyleNone;
      self.accessoryType = UITableViewCellAccessoryNone;
      self.textLabel.textAlignment = NSTextAlignmentLeft;
      self.textLabel.font = DICTIONARY_BASIC_TEXT_FONT;
      self.textLabel.textColor = [UIColor grayColor];
      break;
    }
  }
}


@end
