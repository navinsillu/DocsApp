//
//  ChatController.h
//  Whatsapp
//
//  Created by Rafael Castro on 6/16/15.
//  Copyright (c) 2015 HummingBird. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Chat.h"
#import "AppDelegate.h"

//
// This class control chat exchange message itself
// It creates the bubble UI
//
@interface MessageController : UIViewController
{
    AppDelegate *appdelegate;
}
@property (strong, nonatomic) Chat *chat;
@end
