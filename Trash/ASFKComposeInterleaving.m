//
//  ComposePar.m
//
//  Created by Boris Vigman on 22/03/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKComposeInterleaving.h"
#import "ASFKControlBlock+Private.h"

@interface ASFKComposeInterleaving()
@property (atomic) NSMutableArray<ASFKExecutableProcedure>* procedures;

@property (atomic) NSMutableArray<dispatch_queue_t>* queues;
@property (atomic) long currentQ;
@property (atomic) long qNum;
@property (atomic) dispatch_queue_t queue;
@property ASFKControlBlock* controlData;
@end
@implementation ASFKComposeInterleaving
@synthesize procedures = _procedures;

-(id) init{
    return [self initWithNumberOfQueues:1];
}
-(id)initWithNumberOfQueues:(long)num{
    self = [super init];
    if(self){
        self.procedures = [NSMutableArray array];
        //self.ends = [NSMutableArray array];
        self.queues = [NSMutableArray array];
        self.qNum=MAXIMAL_SYNC_QUEUES;
        if(num>0){
            self.qNum=num;
        }
        NSString* rand=[[self generateRandomNumber]stringValue];
        self.queue = dispatch_queue_create([[@"com.compose.par.Q1." stringByAppendingString:rand]cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        rand=nil;
        self.currentQ=0;
        for (long i=0; i<self.qNum; i++) {
            NSNumber* n=[self generateRandomNumber];
            [self.queues addObject:dispatch_queue_create([[[@"" stringByAppendingFormat:@"com.compose.par.Q2.%ld.",i] stringByAppendingString:[n stringValue]] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL)];
            n=nil;
        }
    }
    return self;
}
-(void) runProcedure:(ASFKExecutableProcedure)block withParams:(void*)params withSummary:(ASFKExecutableProcedureSummary)summary{
    
    void* __block result=params;
    dispatch_async(self.queue, ^{
        NSLog(@"Going to deploy synchronous block");
        dispatch_sync([self.queues objectAtIndex:self.currentQ], ^{
            NSLog(@"Starting synchronous block");
            //result=(block(self.controlData, result));
            self.currentQ=(self.currentQ+1)%self.qNum;
            NSLog(@"Synchronous block ended");
            dispatch_async(self.queue, ^{
                NSLog(@"Going to deploy synchronous summary block");
                dispatch_sync([self.queues objectAtIndex:self.currentQ], ^{
                    NSLog(@"Starting synchronous summary block");
                    //result=summary(self.controlData,result);
                    NSLog(@"Synchronous summary block ended");
                });
            });
        });
    });
}
-(void) runStoredProceduresWithParams:(void*)params withSummary:(ASFKExecutableProcedureSummary)summary
{
    void* __block result=params;
    NSUInteger len=[self.procedures count];
    for (NSUInteger i=0;i<len;i++) {
        ASFKExecutableProcedure b = [self.procedures objectAtIndex:i];
        //ASFKExecutableBlockEnd e=[self.ends objectAtIndex:i];
        dispatch_async(self.queue, ^{
            NSLog(@"Going to deploy synchronous block");
            dispatch_sync([self.queues objectAtIndex:self.currentQ], ^{
                NSLog(@"Starting synchronous block");
                //result=(b(self.controlData, result));
                //result=(e(self.controlData, result));
                self.currentQ=(self.currentQ+1)%self.qNum;
                NSLog(@"Synchronous block ended");
            });
        });
    }
    dispatch_async(self.queue, ^{
        NSLog(@"Going to deploy synchronous summary block");
        dispatch_sync([self.queues objectAtIndex:self.currentQ], ^{
            NSLog(@"Starting synchronous summary block");
            //result=summary(self.controlData,result);
            NSLog(@"Synchronous summary block ended");
        });
    });
    
}
@end
