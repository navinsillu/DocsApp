//
//  Message.m
//  Whatsapp
//
//  Created by Rafael Castro on 6/16/15.
//  Copyright (c) 2015 HummingBird. All rights reserved.
//

#import "Message.h"

@implementation Message

-(id)init
{
    self = [super init];
    if (self)
    {
        self.sender = MessageSenderMyself;
        self.status = MessageStatusSending;
        self.text = @"";
        self.heigh = 44;
        self.date = [NSDate date];
        self.identifier = @"";
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.identifier forKey:@"identifier"];
    [encoder encodeObject:self.chat_id forKey:@"chat_id"];
    [encoder encodeObject:self.text forKey:@"text"];
    [encoder encodeObject:self.date forKey:@"date"];
    [encoder encodeObject:[NSNumber numberWithInt:self.heigh] forKey:@"heigh"];
    [encoder encodeObject:[NSNumber numberWithInt:self.status] forKey:@"status"];
    [encoder encodeObject:[NSNumber numberWithInt:self.sender] forKey:@"sender"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.identifier = [decoder decodeObjectForKey:@"identifier"];
        self.chat_id = [decoder decodeObjectForKey:@"chat_id"];
        self.text = [decoder decodeObjectForKey:@"text"];
        self.date = [decoder decodeObjectForKey:@"date"];
        self.heigh = [[decoder decodeObjectForKey:@"heigh"] intValue];
        self.status = [[decoder decodeObjectForKey:@"status"] intValue];
        self.sender = [[decoder decodeObjectForKey:@"sender"] intValue];
    }
    return self;
}

+(Message *)messageFromDictionary:(NSDictionary *)dictionary
{
    Message *message = [[Message alloc] init];
    message.text = dictionary[@"text"];
    message.identifier = dictionary[@"message_id"];
    message.status = [dictionary[@"status"] integerValue] + 1;
    
    NSString *dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSSS";
    
    //Date in UTC
    NSTimeZone *inputTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
    [inputDateFormatter setTimeZone:inputTimeZone];
    [inputDateFormatter setDateFormat:dateFormat];
    NSDate *date = [inputDateFormatter dateFromString:dictionary[@"sent"]];
    
    //Convert time in UTC to Local TimeZone
    NSTimeZone *outputTimeZone = [NSTimeZone localTimeZone];
    NSDateFormatter *outputDateFormatter = [[NSDateFormatter alloc] init];
    [outputDateFormatter setTimeZone:outputTimeZone];
    [outputDateFormatter setDateFormat:dateFormat];
    NSString *outputString = [outputDateFormatter stringFromDate:date];
    
    message.date = [outputDateFormatter dateFromString:outputString];
    
    return message;
}
@end
