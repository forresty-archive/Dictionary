//
//  MainViewController.m
//  Dictionary
//
//  Created by Feng Ye on 11/18/11.
//  Copyright (c) 2011 @forresty. All rights reserved.
//

#import "MainViewController.h"
#import "LookupHistory.h"
#import "LookupRequest.h"

#define kCellID @"wordCellID"

@implementation MainViewController {
@private
  UISearchBar *__searchBar;
  UITableView *__lookupHistoryTableView;
  UISearchDisplayController *__searchDisplayController;

  LookupHistory *__lookupHistory;
  LookupRequest *__lookupRequest;

  NSMutableArray *__completions;
  BOOL __lookingUpCompletions;
}


#pragma mark - View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];

  __lookupHistory = [LookupHistory sharedInstance];
  __lookupRequest = [[LookupRequest alloc] init];
  __completions = [@[] mutableCopy];
  __lookingUpCompletions = NO;

  [self buildViews];
}


- (void)buildViews {
  [self buildSearchBar];
  [self buildLookupHistoryTableView];
  [self buildSearchDisplayController];
  [self setupViewConstraints];
}


- (void)buildSearchBar {
  __searchBar = [[UISearchBar alloc] init];
  __searchBar.delegate = self;
  __searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
  [__searchBar sizeToFit];
}


- (void)buildLookupHistoryTableView {
  __lookupHistoryTableView = [[UITableView alloc] init];
  [__lookupHistoryTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
  __lookupHistoryTableView.dataSource = self;
  __lookupHistoryTableView.delegate = self;
  __lookupHistoryTableView.tableHeaderView = __searchBar;

  [self.view addSubview:__lookupHistoryTableView];
}


- (void)buildSearchDisplayController {
  __searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:__searchBar contentsController:self];
  __searchDisplayController.delegate = self;
  __searchDisplayController.searchResultsDataSource = self;
  __searchDisplayController.searchResultsDelegate = self;
}


- (void)setupViewConstraints {
  NSDictionary *views = NSDictionaryOfVariableBindings(__lookupHistoryTableView, self.view);
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[__lookupHistoryTableView]|" options:0 metrics:nil views:views]];
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[__lookupHistoryTableView]|" options:0 metrics:nil views:views]];
}


# pragma mark - internal


- (NSArray *)indexPathsFromOffset:(NSUInteger)offset count:(NSUInteger)count {
  NSMutableArray * indexPaths = [[NSMutableArray alloc] initWithCapacity:count];

  for (int i = 0; i < count; i++) {
    [indexPaths addObject:[NSIndexPath indexPathForRow:i + offset inSection:0]];
  }

  return indexPaths;
}


# pragma mark - history


- (void)clearHistory {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [__lookupHistoryTableView beginUpdates];
    [__lookupHistoryTableView deleteRowsAtIndexPaths:[self indexPathsFromOffset:0 count:[__lookupHistory count]] withRowAnimation:UITableViewRowAnimationTop];
    [__lookupHistory clear];
    [__lookupHistoryTableView endUpdates];
  }];

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [__lookupHistoryTableView reloadData];
  }];
}


# pragma mark - view manipulation


- (void)makeCellDefault:(UITableViewCell *)cell withText:(NSString *)text {
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.textLabel.textAlignment = NSTextAlignmentLeft;
  cell.textLabel.font = [UIFont fontWithName:@"Baskerville" size:24];
  cell.textLabel.text = text;
}


- (void)makeCellNormal:(UITableViewCell *)cell withText:(NSString *)text {
  [self makeCellDefault:cell withText:text];
  cell.textLabel.textColor = [UIColor blackColor];
}


- (void)disableCell:(UITableViewCell *)cell withText:(NSString *)text {
  [self makeCellDefault:cell withText:text];
  cell.textLabel.textColor = [UIColor grayColor];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.accessoryType = UITableViewCellAccessoryNone;
}


- (void)makeActionCell:(UITableViewCell *)cell withText:(NSString *)text {
  [self makeCellDefault:cell withText:text];
  cell.textLabel.textAlignment = NSTextAlignmentCenter;
  cell.accessoryType = UITableViewCellAccessoryNone;
  cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
}


# pragma mark - UI presentation


- (void)showDefinitionForTerm:(NSString *)term {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [__lookupHistory addLookupHistoryWithTerm:term];
    [__lookupHistoryTableView reloadData];
  }];

  UIReferenceLibraryViewController *referenceLibraryViewController = [[UIReferenceLibraryViewController alloc] initWithTerm:term];

  [self presentViewController:referenceLibraryViewController animated:YES completion:NULL];
}


# pragma mark - UITableViewDataSource


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];

  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
  }

  if (tableView == self.searchDisplayController.searchResultsTableView) {
    [self makeSearchResultCell:cell forRowAtIndexPath:indexPath];
  } else if (tableView == __lookupHistoryTableView) {
    [self makeHistoryCell:cell forRowAtIndexPath:indexPath];
  }

  return cell;
}


- (void)makeHistoryCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([__lookupHistory count] == 0) {
    [self disableCell:cell withText:@"No history"];
  } else {
    if (indexPath.row == [__lookupHistory count]) {
      [self makeActionCell:cell withText:@"Clear History"];
    } else {
      [self makeCellNormal:cell withText:[__lookupHistory[indexPath.row] description]];
    }
  }
}


- (void)makeSearchResultCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (__lookingUpCompletions) {
    [self disableCell:cell withText:@"Looking up..."];
  } else if ([__completions count] > 0) {
    [self makeCellNormal:cell withText:[__completions[indexPath.row] description]];
  } else {
    [self disableCell:cell withText:@"No result"];
  }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    return 1;
  } else if (tableView == __lookupHistoryTableView) {
    return 1;
  }

  return 0;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    return nil;
  } else if (tableView == __lookupHistoryTableView) {
    return @"History";
  }

  return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    if (__lookingUpCompletions) {
      return 1;
    } else if ([__completions count] > 0) {
      return [__completions count];
    } else {
      return 1;
    }
  } else if (tableView == __lookupHistoryTableView) {
    return [__lookupHistory count] + 1;
  }

  return 0;
}


# pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  if (tableView == self.searchDisplayController.searchResultsTableView) {
    if ([__searchBar.text length] > 0 && [__completions count] > 0 && indexPath.section == 0) {
      [self showDefinitionForTerm:__completions[indexPath.row]];

    } else if (__lookingUpCompletions) {
      // guessing, do nothing
      return;

    }
  } else if (tableView == __lookupHistoryTableView) {
    if ([__lookupHistory count] == 0) {
      // empty history, do nothing
    } else {
      if (indexPath.row == [__lookupHistory count]) {
        [self clearHistory];
      } else {
        [self showDefinitionForTerm:[__lookupHistory[indexPath.row] description]];
      }
    }
  }
}


# pragma mark - UISearchDisplayDelegate


- (BOOL)searchDisplayController:(UISearchDisplayController *)searchDisplayController shouldReloadTableForSearchString:(NSString *)searchString {
  if ([searchString length] < 1) {
    return NO;
  }

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    __lookingUpCompletions = YES;
    __completions = [@[] mutableCopy];
    [self.searchDisplayController.searchResultsTableView reloadData];
  }];

  [__lookupRequest startLookingUpDictionaryWithTerm:searchString progressBlock:^(NSArray *partialResults) {
    __lookingUpCompletions = __lookupRequest.lookingUpCompletions;
    [__completions addObjectsFromArray:partialResults];
    [self.searchDisplayController.searchResultsTableView reloadData];
//    [self insertPartialResults:partialResults];
  }];

  return NO;
}


- (void)insertPartialResults:(NSArray *)partialResults {
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [__searchDisplayController.searchResultsTableView beginUpdates];
    __lookingUpCompletions = __lookupRequest.lookingUpCompletions;

    NSArray *indexPaths = [self indexPathsFromOffset:[__completions count] count:[partialResults count]];
    [__searchDisplayController.searchResultsTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];

    [__completions addObjectsFromArray:partialResults];
    [__searchDisplayController.searchResultsTableView endUpdates];
  }];
}


# pragma mark - UISearchBarDelegate


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  if ([searchBar.text length] > 0 && [__completions count] > 0 && [searchBar.text isEqualToString:__completions[0]]) {
    [self showDefinitionForTerm:searchBar.text];
  }
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
}


@end
