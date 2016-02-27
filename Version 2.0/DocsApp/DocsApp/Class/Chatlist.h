//
//  Chatlist.h
//  DocsApp
//
//  Created by ev_mac16 on 27/02/16.
//  Copyright © 2016 ev_mac16. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface Chatlist : NSManagedObject

@property (nonatomic, retain) NSData * messageData;
// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

