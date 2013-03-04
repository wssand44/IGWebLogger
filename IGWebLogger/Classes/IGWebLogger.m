//
//  IGWebLogger.m
//  IGWebLogger
//
//  Created by Francis Chong on 13年3月4日.
//  Copyright (c) 2013年 Ignition Soft. All rights reserved.
//

#import "IGWebLogger.h"
#import "WebSocket.h"

@implementation IGWebLogger

static IGWebLogger *sharedInstance;

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[IGWebLogger alloc] init];
    });
}

+ (IGWebLogger *)sharedInstance
{
	return sharedInstance;
}

- (id)init
{
	if (sharedInstance != nil)
	{
		return nil;
	}
	
	if ((self = [super init]))
	{
        self.webSockets = [NSMutableArray array];
	}

	return self;
}

#pragma mark - Public

- (void)addWebSocket:(WebSocket*)webSocket
{
    dispatch_sync([DDLog loggingQueue], ^{
        [self.webSockets addObject:webSocket];
    });
}

- (void)removeWebSocket:(WebSocket*)webSocket
{
    dispatch_sync([DDLog loggingQueue], ^{
        [self.webSockets removeObject:webSocket];
    });
}

#pragma mark - DDLogger

- (void)logMessage:(DDLogMessage *)logMessage
{
	if ([self.webSockets count] > 0)
	{
        NSString *logMsg = [self formatLogMessage:logMessage];
        if (logMsg)
        {
            [self.webSockets enumerateObjectsUsingBlock:^(WebSocket* socket, NSUInteger idx, BOOL *stop) {
                [socket sendMessage:logMsg];
            }];
        }
	}
}

- (NSString *)loggerName
{
	return @"hk.ignition.logger.IGWebLogger";
}

// a DDLogFormatter that format the log in JSON

#pragma mark - DDLogFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString* logLevel;
    switch (logMessage->logFlag)
    {
        case LOG_FLAG_ERROR : logLevel = @"error"; break;
        case LOG_FLAG_WARN : logLevel = @"warn"; break;
        case LOG_FLAG_INFO : logLevel = @"info"; break;
        default : logLevel = @"verbose"; break;
    }
    
    NSError* error;
    NSString* file = [NSString stringWithUTF8String:logMessage->file];
    NSString* function = [NSString stringWithUTF8String:logMessage->function];

    NSDictionary* data = @{
                           @"message": logMessage->logMsg,
                           @"level": logLevel,
                           @"file": file,
                           @"function": function,
                           @"line": [NSNumber numberWithInt:logMessage->lineNumber]
                        };
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                       options:0
                                                         error:&error];
    NSString* jsonStr = [[NSString alloc] initWithData:jsonData
                                              encoding:NSUTF8StringEncoding];
    return jsonStr;
}

@end