//
//  DetailViewController.h
//  JudoPayDemoObjC
//
//  Created by Hamon Riazy on 14/07/2015.
//  Copyright © 2015 Judo Payments. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TransactionData;

@interface DetailViewController : UIViewController

@property (nonatomic, strong) TransactionData *transactionData;

@end
