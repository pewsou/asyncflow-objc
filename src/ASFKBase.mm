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
//  Created by Boris Vigman on 15/02/2019.
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
#import "ASFKBase+Internal.h"
#include <mach/mach.h>
#include <mach/mach_time.h>
#import "ASFKQueue+Internal.h"

@implementation ASFKPriv_EndingTerm
+ (ASFKPriv_EndingTerm *)singleInstance {
    static ASFKPriv_EndingTerm *singleInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleInstance = [[self alloc] init];
    });
    return singleInstance;
}
@end

@implementation ASFKReturnInfo{

}
-(id) init{
    self=[super init];
    if(self){
        totalSessionTime=0;
        totalProcsTime=0;
        totalProcsCount=0;
        totalSessionsCount=0;
        returnCodeSuccessful=NO;
        returnCodeDescription=@"";
        returnResult=nil;
        returnStatsProcsElapsedSec=0;
        returnStatsSessionElapsedSec=0;
        returnSessionId=nil;
    }
    return self;
}
@end

@implementation ASFKConfigParams
-(id) init{
    self = [super init];
    if(self) {
        retInfo=nil;
    }
    return self;
}
-(void) setupReturnInfo{
    if(retInfo==nil){
        retInfo=[ASFKReturnInfo new];
    }
}
@end

@implementation ASFKSessionConfigParams
-(id) init{
    self = [super init];
    if(self) {
        progressProc=nil;
        summaryRoutine=nil;
        procs=nil;
        cancellationProc=nil;
        expCondition=nil;
        onPauseProc=nil;
        blockCallMode=ASFK_BC_NO_BLOCK;
    }
    return self;
}

@end

@implementation ASFKExecutionParams{
    
}
-(id) init{
    self = [super init];
    if(self) {
        progressProc=nil;
        summaryRoutine=nil;
        procs=nil;
        cancellationProc=nil;
        expCondition=nil;
        onPauseProc=nil;
        preBlock=nil;
    }
    return self;
}
-(void) setupReturnInfo{
    if(retInfo==nil){
        retInfo=[ASFKReturnInfo new];
    }
}
@end

@implementation ASFKThreadpoolSession{
    std::atomic<BOOL> cancelled;
    std::vector<NSInteger> vectorTermPos;
}
-(id)init{
    self=[super init];
    if(self){
        [self _TPSinitWithSession:nil andSubsession:nil blkMode:ASFK_BC_NO_BLOCK];
    }
    return self;
}
-(id)initWithSessionId:(ASFK_IDENTITY_TYPE)sessionId andSubsessionId:(ASFK_IDENTITY_TYPE)subId blkMode:(eASFKBlockingCallMode)blkMode{
    self=[super init];
    if(self){
        [self _TPSinitWithSession:sessionId andSubsession:subId blkMode:blkMode];
    }
    return self;
}

-(void)_TPSinitWithSession:(ASFK_IDENTITY_TYPE)sessionId andSubsession:(ASFK_IDENTITY_TYPE)subId blkMode:(eASFKBlockingCallMode)blkMode{
    procs=[NSMutableArray array];
    excond=[[ASFKExpirationCondition alloc]init];
    isStopped=NO;
    paused=NO;
    onPauseNotification=nil;
    callMode=blkMode;
    if(sessionId){
        cblk= [self newSession:sessionId andSubsession:subId];
    }else{
        cblk= [self newSession];
    }
    
    self.sessionId=cblk.sessionId;
    
    passSummary=nil;
    expirationSummary=nil;
    onPauseNotification=nil;
    cancelled=NO;
    cancellationHandler=^id(id identity){
        ASFKLog(@"Default cancellation handler");
        return nil;
    };
    
}
-(void) _invokeCancellationHandler:(ASFKCancellationRoutine) cru identity:(id)identity{
    BOOL tval=NO;
    if(cru==nil){
        return;
    }
    
    if(cancelled.compare_exchange_strong(tval,YES))
    {
        DASFKLog(@"Cancellation on the way, session %@",identity);
        cru(identity);
    }
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
+ (ASFKGlobalQueue *)singleInstance {
    static ASFKGlobalQueue *singleInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleInstance = [[self alloc] init];
    });
    return singleInstance;
}

- (id)init {
    self = [super init];
    if (self) {
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
            //ASFKLog(@"deploying %lu tasks",(unsigned long)[blarray count]);
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
        ASFKControlBlock* cb = (ASFKControlBlock*)obj;// [ctrlblocks objectForKey:key];
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
