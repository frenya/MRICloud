//
//  DetailViewController.h
//  MRICloud
//
//  Created by Frantisek Vymazal on 16/03/15.
//  Copyright (c) 2015 F8.cz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

