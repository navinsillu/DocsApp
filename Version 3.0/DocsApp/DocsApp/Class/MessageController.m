//
//  MessageController.m
//  Whatsapp
//
//  Created by Rafael Castro on 7/23/15.
//  Copyright (c) 2015 HummingBird. All rights reserved.
//

#import "MessageController.h"
#import "MessageCell.h"
#import "TableArray.h"
#import "MessageGateway.h"

#import "Inputbar.h"
#import "DAKeyboardControl.h"
#import "Chatlist.h"

@interface MessageController() <InputbarDelegate,MessageGatewayDelegate,
                                    UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet Inputbar *inputbar;
@property (strong, nonatomic) TableArray *tableArray;
@property (strong, nonatomic) MessageGateway *gateway;

@end




@implementation MessageController

-(void)viewDidLoad
{
    [super viewDidLoad];
    appdelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;

    [self setInputbar];
    [self setTableView];
    [self setGateway];
    [self getMessage];
    
    self.title = @"ChatBot";
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    __weak Inputbar *inputbar = _inputbar;
    __weak UITableView *tableView = _tableView;
    __weak MessageController *controller = self;
    
    self.view.keyboardTriggerOffset = inputbar.frame.size.height;
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        /*
         Try not to call "self" inside this block (retain cycle).
         But if you do, make sure to remove DAKeyboardControl
         when you are done with the view controller by calling:
         [self.view removeKeyboardControl];
         */
        
        CGRect toolBarFrame = inputbar.frame;
        toolBarFrame.origin.y = keyboardFrameInView.origin.y - toolBarFrame.size.height;
        inputbar.frame = toolBarFrame;
        
        CGRect tableViewFrame = tableView.frame;
        tableViewFrame.size.height = toolBarFrame.origin.y - 64;
        tableView.frame = tableViewFrame;
        
        [controller tableViewScrollToBottomAnimated:NO];
    }];
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.view endEditing:YES];
    [self.view removeKeyboardControl];
    [self.gateway dismiss];
}
-(void)viewWillDisappear:(BOOL)animated
{
    self.chat.last_message = [self.tableArray lastObject];
}

#pragma mark -

-(void)setInputbar
{
    self.inputbar.placeholder = nil;
    self.inputbar.delegate = self;
    self.inputbar.leftButtonImage = [UIImage imageNamed:@"share"];
    self.inputbar.rightButtonText = @"Send";
    self.inputbar.rightButtonTextColor = [UIColor colorWithRed:0 green:124/255.0 blue:1 alpha:1];
}
-(void)setTableView
{
    self.tableArray = [[TableArray alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f,self.view.frame.size.width, 10.0f)];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView registerClass:[MessageCell class] forCellReuseIdentifier: @"MessageCell"];
    
}
-(void)setGateway
{
    self.gateway = [MessageGateway sharedInstance];
    self.gateway.delegate = self;
    self.gateway.chat = self.chat;
    [self.gateway loadOldMessages];
}
-(void)getMessage
{
    [self.tableArray removeAllObjects];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Chatlist" inManagedObjectContext:appdelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *fetchresult = [appdelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (Chatlist *chat in fetchresult) {
        
        Message *msg = [NSKeyedUnarchiver unarchiveObjectWithData:chat.messageData];
        [self.tableArray addObject:msg];
        if(msg.status == MessageStatusSending)
        {
            [self performSelectorInBackground:@selector(callservice:) withObject:msg];
        }
    }
    [self.tableView reloadData];
}
-(void)setChat:(Chat *)chat
{
    _chat = chat;
    self.title = chat.contact.name;
}

#pragma mark - Actions

- (IBAction)userDidTapScreen:(id)sender
{
    [_inputbar resignFirstResponder];
}

#pragma mark - TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableArray numberOfSections];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableArray numberOfMessagesInSection:section];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MessageCell";
    MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        cell = [[MessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.message = [self.tableArray objectAtIndexPath:indexPath];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.tableArray objectAtIndexPath:indexPath];
    return message.heigh;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.tableArray titleForSection:section];
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame = CGRectMake(0, 0, tableView.frame.size.width, 40);
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"Helvetica" size:20.0];
    [label sizeToFit];
    label.center = view.center;
    label.font = [UIFont fontWithName:@"Helvetica" size:13.0];
    label.backgroundColor = [UIColor colorWithRed:207/255.0 green:220/255.0 blue:252.0/255.0 alpha:1];
    label.layer.cornerRadius = 10;
    label.layer.masksToBounds = YES;
    label.autoresizingMask = UIViewAutoresizingNone;
    [view addSubview:label];
    
    return view;
}
- (void)tableViewScrollToBottomAnimated:(BOOL)animated
{
    NSInteger numberOfSections = [self.tableArray numberOfSections];
    NSInteger numberOfRows = [self.tableArray numberOfMessagesInSection:numberOfSections-1];
    if (numberOfRows)
    {
        [_tableView scrollToRowAtIndexPath:[self.tableArray indexPathForLastMessage]
                                         atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

#pragma mark - InputbarDelegate

-(void)inputbarDidPressRightButton:(Inputbar *)inputbar
{
    Message *message = [[Message alloc] init];
    message.text = inputbar.text;
    message.date = [NSDate date];
    message.chat_id = _chat.identifier;
    message.status = MessageStatusSending;
    
    Chatlist *chat = [NSEntityDescription
                                      insertNewObjectForEntityForName:@"Chatlist"
                                      inManagedObjectContext:appdelegate.managedObjectContext];
    chat.messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
    NSError *error;
    if (![appdelegate.managedObjectContext save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    
    //Store Message in memory
    [self.tableArray addObject:message];
    
    //Insert Message in UI
    NSIndexPath *indexPath = [self.tableArray indexPathForMessage:message];
    [self.tableView beginUpdates];
    if ([self.tableArray numberOfMessagesInSection:indexPath.section] == 1)
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView insertRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView endUpdates];
    
    [self.tableView scrollToRowAtIndexPath:[self.tableArray indexPathForLastMessage]
                          atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    //Send message to server
    [self.gateway sendMessage:message];
    [self callservice:message];
}
-(void)inputbarDidPressLeftButton:(Inputbar *)inputbar
{
    [self.view endEditing:YES];
}
-(void)inputbarDidChangeHeight:(CGFloat)new_height
{
    //Update DAKeyboardControl
    self.view.keyboardTriggerOffset = new_height;
}

#pragma mark - MessageGatewayDelegate

-(void)gatewayDidUpdateStatusForMessage:(Message *)message
{
    NSIndexPath *indexPath = [self.tableArray indexPathForMessage:message];
    MessageCell *cell = (MessageCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateMessageStatus];
}
-(void)gatewayDidReceiveMessages:(NSArray *)array
{
    [self.tableArray addObjectsFromArray:array];
    [self.tableView reloadData];
}

#pragma mark - Webservice

-(void)callservice:(Message*)message
{
    
    NSString *escapedString = [message.text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    NSLog(@"escapedString: %@", escapedString);

    NSString *urlString = [NSString stringWithFormat:@"http://www.personalityforge.com/api/chat/?apiKey=6nt5d1nJHkqbkphe&chatBotID=63906&externalID=Navin&message=%@",escapedString];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

    NSError *error = nil;
    
    if (!error) {
        
        NSURLSessionDataTask *downloadTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error) {
                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                if (httpResp.statusCode == 200) {
                    
                    NSDictionary* json = [NSJSONSerialization
                                          JSONObjectWithData:data
                                          options:kNilOptions
                                          error:&error];
                    if(!error)
                    {
                        NSLog(@"%@",json);
                        
                        NSDictionary *msgDict = [json valueForKey:@"message"];
                        
                        if(msgDict)
                        {
                            
                            [self.tableArray removeObject:message];
                            message.status = MessageStatusSent;
                            [self.tableArray addObject:message];
                            
                            Message *message = [[Message alloc] init];
                            message.sender = MessageSenderSomeone;
                            message.status = MessageStatusReceived;
                            message.text = [msgDict valueForKey:@"message"];
                            message.date = [NSDate date];
                            message.chat_id = _chat.identifier;
                            
                            Chatlist *chat = [NSEntityDescription
                                              insertNewObjectForEntityForName:@"Chatlist"
                                              inManagedObjectContext:appdelegate.managedObjectContext];
                            chat.messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
                            NSError *error;
                            if (![appdelegate.managedObjectContext save:&error]) {
                                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                            }
                            
                            //Store Message in memory
                            [self.tableArray addObject:message];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                //Insert Message in UI
                                NSIndexPath *indexPath = [self.tableArray indexPathForMessage:message];
                                [self.tableView beginUpdates];
                                if ([self.tableArray numberOfMessagesInSection:indexPath.section] == 1)
                                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                                                  withRowAnimation:UITableViewRowAnimationNone];
                                [self.tableView insertRowsAtIndexPaths:@[indexPath]
                                                      withRowAnimation:UITableViewRowAnimationBottom];
                                [self.tableView endUpdates];
                                
                                [self.tableView scrollToRowAtIndexPath:[self.tableArray indexPathForLastMessage]
                                                      atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                            });

                        }
                        
                    }
                    
                }
            }
            else
            {
                NSLog(@"%@",error.localizedDescription);
            }
            
        }];
        
        
        [downloadTask resume];
        
    }

}

@end
