/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.
 
 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//  Copyright © 2019-2022 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
#import "ASFKBase+Internal.h"
#include <mach/mach.h>
#include <mach/mach_time.h>
#import "ASFKQueue+Internal.h"

@implementation ASFKExecutionParams{
 
}
-(id) init{
    self = [super init];
    if(self) {
        progressProc=nil;
        SummaryRoutine=nil;
        procs=nil;
        cancellationProc=nil;
        expCondition=nil;
    }
    return self;
}
@end


@implementation ASFKGlobalQueue{
    NSMutableArray* mQ;
    dispatch_queue_t dConQ_UserInteractive;
    dispatch_queue_t dConQ_Background;
    dispatch_queue_t dConQ_Utility;
    NSLock* lock;
}
#pragma mark Singleton Methods
+ (ASFKGlobalQueue *)sharedManager {
    static ASFKGlobalQueue *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        NSUInteger pr=[[NSProcessInfo processInfo] activeProcessorCount]*ASFK_TP_LOAD_FACTOR;
        ASFKLog(@"ASFK: Active processors: %lu detected",(unsigned long)pr);
        lock=[NSLock new];
        dConQ_UserInteractive=dispatch_get_global_queue(
                        QOS_CLASS_USER_INTERACTIVE, 0);
        dConQ_Utility=dispatch_get_global_queue(
                                    QOS_CLASS_UTILITY, 0);
        dConQ_Background=dispatch_get_global_queue(
                                    QOS_CLASS_BACKGROUND, 0);
    }
    return self;
}
-(id) submitBlocks:(NSArray<dispatch_block_t>*)blarray summary:(id(^)(void))summary QoS:(long)qos blocking:(BOOL)blocking{
    __block dispatch_queue_t q=[self _resolveQueue:qos];
    if(blocking){
        if(blarray && [blarray count]>0){
            dispatch_apply([blarray count], q, ^(size_t index) {
                dispatch_block_t b= [blarray objectAtIndex:index];
                b();
            });
            return summary();
        }
    }else{
        dispatch_async(dispatch_get_global_queue(ASFK_PRIVSYM_QOS_CLASS, 0), ^{
        if(blarray && [blarray count]>0){
            dispatch_apply([blarray count], q, ^(size_t index) {
                dispatch_block_t b= [blarray objectAtIndex:index];
                b();
            });
            summary();
        }
        });
    }
    return nil;
}

-(dispatch_queue_t) _resolveQueue:(long)qos{
    if(qos==QOS_CLASS_BACKGROUND){
        return dConQ_Background;
    }else if(qos==QOS_CLASS_USER_INTERACTIVE){
        return dConQ_UserInteractive;
    }else{
        return dConQ_Utility;
    }
}
@end

@interface ASFKBase()
@property  NSMutableDictionary* priv_sources;
@property  NSMutableDictionary* priv_targets;
@end
@implementation ASFKBase
+(NSString*) ASFKVersion{
    return ASFK_VERSION;
}
-(id) ASFKVersion{
    return ASFK_VERSION;
}
-(id)init{
    self = [super init];
    if(self){
        [self _Baseinit:nil];
    }
    return self;
}
-(id)initWithName:(NSString*)name{
    self = [super init];
    if(self){
        [self _Baseinit:name];
    }
    return self;
}
-(void) _Baseinit:(NSString*)name{
    if(name){
        _itsName=name;
    }else{
        _itsName=[ASFKBase generateIdentity];
    }
    self.priv_sources=[NSMutableDictionary new];
    self.priv_targets=[NSMutableDictionary new];
    priv_statistics=[NSMutableDictionary new];
    _sources=_priv_sources;
    _targets=_priv_targets;
    lkNonLocal=[NSLock new];
    semHighLevelCall=dispatch_semaphore_create(1);
    ctrlblocks=[NSMutableDictionary new];
}
-(NSDictionary*)getStatistics{
    [lkNonLocal lock];
    NSDictionary* s=[priv_statistics copy];
    [lkNonLocal unlock];
    return s;
}

-(void)cancelAll{
    [lkNonLocal lock];
    [ctrlblocks enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        ASFKControlBlock* cb = (ASFKControlBlock*)obj;
        if(cb){
            [cb cancel];
        }else{
            WASFKLog(@"ASFKBase> Failed to start session cancelling because session identifier was not found");
        }
        cb=nil;
    }];

    [ctrlblocks removeAllObjects];
    [lkNonLocal unlock];
    
}
-(void)cancelSession:(NSString*)sessionId{
    if(sessionId){
        [lkNonLocal lock];
        ASFKControlBlock* cb= [ctrlblocks objectForKey:sessionId];
        if(cb){
            [cb cancel];
            [ctrlblocks removeObjectForKey:cb.sessionId];
            cb=nil;
        }else{
            WASFKLog(@"ASFKBase> Failed to start session cancelling because session identifier was not found");
        }
        [lkNonLocal unlock];
        ASFKLog(@"Session removed");
    }else{
        WASFKLog(@"ASFKBase> Failed to start session cancelling because session identifier is invalid");
    }
}

-(BOOL) isBusy{
    [lkNonLocal lock];
    BOOL res=[ctrlblocks count]>0?YES:NO;
    [lkNonLocal unlock];
    return res;
}
-(NSUInteger) controlBlocks{
    [lkNonLocal lock];
    NSUInteger res=[ctrlblocks count];
    [lkNonLocal unlock];
    return res;
}
-(BOOL) isBusySession:(ASFK_IDENTITY_TYPE)sessionId{
    [lkNonLocal lock];
    id res=[ctrlblocks objectForKey:sessionId];
    [lkNonLocal unlock];
    if(res){
        return YES;
    }
    return NO;
}

@end
