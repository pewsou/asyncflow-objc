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
#import "ASFKMailbox.h"
#import "ASFKAuthorizationMgr.h"

@interface Private_ASFKBlocker:NSObject{
@public NSCondition* rlocker;
@public BOOL blocked;
}
@property (nonatomic) id msg;
@property (nonatomic) id msgId;
@property (nonatomic) NSDate* date;
@property (nonatomic) ASFKMBMsgProperties* props;

@end
@implementation Private_ASFKBlocker
@end

@interface Private_ASFKMBMsg:NSObject{
@public NSCondition* wlocker;
@public BOOL blocked;
}
    @property (nonatomic) id msg;
    @property (nonatomic) id msgId;
    @property (nonatomic) NSDate* date;
    @property (nonatomic) ASFKMBMsgProperties* props;

@end
@implementation Private_ASFKMBMsg
-(id)init{
    self=[super init];
    if(self){
        self.msg=nil;
        self.date=[NSDate date];
        self.props=[ASFKMBMsgProperties new];
        self.msgId=[NSUUID UUID];
        wlocker=nil;
        blocked=NO;
    }
    return self;
}
@end

@implementation ASFKMBCallbacksMaintenance
-(id) init{
    self=[super init];
    if(self){
        prMemPressure=nil;
    }
    return self;
}
@end
#pragma mark - Container

@interface ASFKSomeContainer:NSObject<ASFKLockable>{
    @protected NSMutableOrderedSet* messages;
    @protected ASFKFilteringQueue* entranceQ;
    @protected NSMutableSet* retractionList;
    @protected NSLock* lock1;
    @protected NSDate* dateRef;
    @protected NSMutableSet* backusers;
    @protected ASFKMBContainerProperties* itscprops;
    @protected NSMutableDictionary* uprops;
    clbkASFKMBFilter itsMsgFilter;
    std::atomic<BOOL> blacklisted;
    std::atomic<eASFKQDroppingPolicy> dropPolicy;
    std::atomic<NSUInteger> memLimitHigh;
    std::atomic<NSUInteger> memLimitLow;
    ASFKPrivateSecret* myPSecret;
}
@property (readonly) id itsOwnerId;
@property (readonly) NSSet* users;

-(void) fitNewMsgProps:(ASFKMBMsgProperties*)mprops forGroup:(ASFKMBContainerProperties*)cprops;
-(void) fitNewMemberProps:(ASFKMBGroupMemberProperties*)mprops forGroup:(ASFKMBContainerProperties*)cprops;
-(id)initWithUser:(id)uid privateSecret:(ASFKPrivateSecret*) pSecret properties:(ASFKMBContainerProperties*)properties;
-(BOOL) setProperties:(ASFKMBContainerProperties*)props;
-(BOOL) setMemberingLimitsLow:(NSUInteger)low high:(NSUInteger)high;
-(BOOL) isValid;
-(BOOL) isBlacklisted;
-(BOOL) isPrivateSecretValid:(ASFKPrivateSecret*)secret matcher:(ASFKSecretComparisonProc)match;
-(BOOL) setPrivateSecret:(ASFKPrivateSecret*)oldsec newsec:(ASFKPrivateSecret*)newsec user:(id)uid authMgr:(ASFKAuthorizationMgr*)auth;
-(BOOL) isPrivate;
-(BOOL) isInvitable;
-(BOOL) canShareUserList;
-(NSArray*) read:(NSUInteger)amount offset:(NSUInteger)offset forUser:(id)uid latest:(BOOL) yesno;
-(NSArray*) readBlocking:(NSUInteger)amount offset:(NSUInteger)offset forUser:(id)uid latest:(BOOL) yesno;
-(NSUInteger) pop:(NSUInteger)amount  offset:(NSUInteger)offset forUser:(id)uid latest:(BOOL) yesno;
-(void) markBlacklisted;
-(void) runPeriodicProc:(NSDate*)tmpoint;
-(void) discardUser:(id) uid;
-(void) discardAllMessages;
-(id)   addMsg:(id) msg withProperties:(ASFKMBMsgProperties*)properties group:(BOOL)grp blockable:(BOOL)blk;
-(NSUInteger) userCount;
-(NSUInteger) msgCount;
-(BOOL) blindedUser:(id)uid;
-(BOOL) mutedUser:(id)uid;
-(BOOL) hasUser:(id)uid;
-(BOOL) canUserPost:(id)uid;
-(BOOL) canRetract;
-(BOOL) shouldBeDeletedAtDate:(NSDate*)aDate;
-(BOOL) mute:(BOOL) yesno user:(id)uid secret:(ASFKPrivateSecret*)secret group:(BOOL)grp;
-(BOOL) muteAll:(BOOL) yesno secret:(ASFKPrivateSecret*)secret group:(BOOL)grp;
-(BOOL) blind:(BOOL) yesno user:(id)uid secret:(ASFKPrivateSecret*)secret;
-(BOOL) blindAll:(BOOL) yesno secret:(ASFKPrivateSecret*)secret;
-(BOOL) retractMsg:(id)msgId;
-(void) purge:(NSDate*)tm;
-(BOOL) setMsgQthresholdsLow:(NSUInteger)low high:(NSUInteger)high;
-(BOOL) setMsgQDropPolicy:(eASFKQDroppingPolicy)policy ;
-(BOOL) setMsgQDropperL1:(ASFKFilter*)dropAlg ;
-(BOOL) setMsgQDropperL2:(clbkASFKMBFilter)dropAlg ;
-(void) _testAndRemove:(NSDate*)tmpoint;
-(void) _testAndAccept:(NSDate*)tmpoint;
@end
@implementation ASFKSomeContainer{
    Private_ASFKBlocker* readBlocker;
}
+(NSDate*) maxDate1:(NSDate*)d1 date2:(NSDate*)d2{
    if(d1 && d2){
        if([d1 compare:d2]==NSOrderedAscending){
            return d2;
        }
        else{
            return d1;
        }
    }
    else if(d1){
        return d1;
    }
    else if(d2){
        return d2;
    }
    else return nil;
}
+(NSDate*) minDate1:(NSDate*)d1 date2:(NSDate*)d2{
    if(d1 && d2){
        if([d1 compare:d2]==NSOrderedDescending){
            return d2;
        }
        else{
            return d1;
        }
    }
    else if(d1){
        return d1;
    }
    else if(d2){
        return d2;
    }
    else return nil;
}
-(void)fitNewMsgProps:(ASFKMBMsgProperties*)mprops forGroup:(ASFKMBContainerProperties*)cprops{
    [mprops.msgDeletionTimer testAndSetEarliest:cprops.containerDeleteTimer];
    [mprops.msgDeletionTimer testAndSetEarliest:cprops.containerDropMsgTimer];
    [mprops.msgDeletionTimer delayToDeadline];

}
-(void)fitNewMemberProps:(ASFKMBGroupMemberProperties*)mprops forGroup:(ASFKMBContainerProperties*)cprops{
    [mprops.grpMemLeaveTimer testAndSetEarliest:cprops.containerKickoutTimer];
    [mprops.grpMemLeaveTimer delayToDeadline];
   
}
-(id)initWithUser:(id)uid privateSecret:(ASFKPrivateSecret*) pSecret properties:(ASFKMBContainerProperties*)properties{
    self=[super init];
    if(self){
        messages=[NSMutableOrderedSet orderedSet];
        backusers=[[NSMutableSet alloc] init];
        entranceQ=[ASFKFilteringQueue new];
        retractionList=[NSMutableSet set];
        _users=backusers;
        lock1=[NSLock new];
        dateRef=[NSDate date];
        _itsOwnerId=uid;
        blacklisted=NO;
        myPSecret=pSecret;
        uprops=[NSMutableDictionary dictionary];
        itscprops=[ASFKMBContainerProperties new];;
        if(properties){
            [itscprops initFromProps:properties];
            [itscprops.containerDeleteTimer delayToDeadline];
        }
        memLimitLow=0;
        memLimitHigh=0;

        readBlocker=[Private_ASFKBlocker new];
        readBlocker->rlocker=[NSCondition new];
    }
    return self;
}
-(BOOL) isBlacklisted{
    return blacklisted;
}
-(BOOL) isValid{
    return blacklisted?NO:YES;
}
-(BOOL) isPrivate{
    return !blacklisted && itscprops.isPrivate;
}
-(BOOL) canShareUserList{
    return !blacklisted && !itscprops.noUserListSharing;
}
-(BOOL) canRetract{
    return itscprops.retractionAllowed;
}
-(BOOL) isInvitable{
    return !blacklisted && itscprops.isInvitable;
}
-(BOOL) isPrivateSecretValid:(ASFKPrivateSecret*)secret matcher:(ASFKSecretComparisonProc)match{
    if(match==nil || blacklisted){
        return NO;
    }
    return match(secret,myPSecret);

}

-(void) markBlacklisted{
    blacklisted=YES;
}
-(void) begin{
    [lock1 lock];
}
-(void) commit{
    [lock1 unlock];
}
#pragma mark - config
-(BOOL) setProperties:(ASFKMBContainerProperties *)newprops{
    if(blacklisted || !newprops){
        return NO;
    }
    [lock1 lock];
    if(itscprops){
        
    }
    itscprops=[ASFKMBContainerProperties new];
    [itscprops initFromProps:newprops];
    [itscprops.containerDeleteTimer delayToDeadline];
    [itscprops.containerDropMsgTimer delayToDeadline];
    [itscprops.containerKickoutTimer delayToDeadline];
    [lock1 unlock];
    return YES;
}

-(BOOL) setPrivateSecret:(ASFKPrivateSecret*)oldsec newsec:(ASFKPrivateSecret*)newsec user:(id)uid authMgr:(ASFKAuthorizationMgr*)auth{
    if([uid isEqualTo:_itsOwnerId]==NO){
        return NO;
    }
    if(oldsec==nil && myPSecret==nil){
        DASFKLog(@"Attempting reset of private secret for user %@",uid);
        if(newsec!=nil){
            //test validity of new secret
            if([newsec validSecretSecurity]){
                myPSecret=newsec;

                ASFKLog(@"DONE");
                return YES;
            }
            return NO;
        }
        else{
            myPSecret=newsec;

            return YES;
        }
    }
    else if(myPSecret!=nil && oldsec!=nil){
        //test old secret validity
        if([myPSecret validSecretSecurity] &&
           [oldsec validSecretSecurity] &&
           [self isPrivateSecretValid:oldsec matcher:auth->secretProcSecurity]){
            if(newsec!=nil){
                if([newsec validSecretSecurity]){
                    [myPSecret invalidateAll];
                    myPSecret=newsec;

                    ASFKLog(@"DONE");
                    return YES;
                }
                return NO;
            }
            else{
                [myPSecret invalidateAll];
                myPSecret=nil;

                ASFKLog(@"DONE");
                return YES;
            }
        }
        return NO;
    }
    ASFKLog(@"FAILED");
    return NO;
}
-(BOOL) setMsgQthresholdsLow:(NSUInteger)low high:(NSUInteger)high {
    if(blacklisted){
        return NO;
    }
    BOOL res=NO;
    if(high>=low ){
        [entranceQ setMinQSize:low];
        [entranceQ setMaxQSize:high];

        res=YES;
    }
    return res;
}
-(BOOL) setMsgQDropperL1:(ASFKFilter*)dropAlg {
    if(blacklisted){
        return NO;
    }
    BOOL res=NO;
        [entranceQ setDroppingAlgorithmL1:dropAlg];
        res=YES;
    return res;
}
-(BOOL) setMsgQDropperL2: (clbkASFKMBFilter)dropAlg{
    if(blacklisted){
        return NO;
    }
    BOOL res=NO;

    [lock1 lock];
    itsMsgFilter=dropAlg;
    [lock1 unlock];
        res=YES;
    return res;
}
-(BOOL) setMsgQDropperPolicy:(eASFKQDroppingPolicy)policy{
    if(blacklisted){
        return NO;
    }
    BOOL res=NO;
    [entranceQ setDroppingPolicy:policy];

    res=YES;
    
    return res;
}
-(BOOL) setMemberingLimitsLow:(NSUInteger)low high:(NSUInteger)high{
    if(blacklisted){
        return NO;
    }
    BOOL res=NO;
    if(high>=low ){
        memLimitHigh=high;
        memLimitLow=low;
        res=YES;
    }
    return res;
}
#pragma mark - querying
-(BOOL) canUserPost:(id)uid{
    if(blacklisted){
        return NO;
    }
    [lock1 lock];
    BOOL res=[self _canUserPost:uid];
    [lock1 unlock];
    return res;
}
-(BOOL) hasUser:(id)uid{
    if(blacklisted){
        return NO;
    }
    [lock1 lock];
    BOOL res=[_users containsObject:uid];
    [lock1 unlock];
    return res;
}
-(BOOL) blindedUser:(id)uid{
    if(blacklisted){
        return NO;
    }
    BOOL res=NO;
    [lock1 lock];
    ASFKMBGroupMemberProperties* up=[uprops objectForKey:uid];
    if(up){
        res=up.isBlinded;
    }
    [lock1 unlock];
    return res;
}
-(BOOL) mutedUser:(id)uid{
    if(blacklisted){
        return NO;
    }
    BOOL res=NO;
    [lock1 lock];
    ASFKMBGroupMemberProperties* up=[uprops objectForKey:uid];
    if(up){
        res=up.isMuted;
    }
    [lock1 unlock];
    return res;
}
-(NSUInteger) userCount{
    if(blacklisted){
        return 0;
    }
    [lock1 lock];
    NSUInteger c=[_users count];
    [lock1 unlock];
    return c;
}

-(NSUInteger) msgCount{
    if(blacklisted){
        return 0;
    }
    [lock1 lock];
    NSUInteger c=[messages count]+[entranceQ count];;
    [lock1 unlock];
    return c;
}
#pragma mark - adding
-(BOOL) addUser:(id)uid withProperties:(ASFKMBGroupMemberProperties*)ps{
    if(blacklisted){
        return NO;
    }
    BOOL res=NO;
    if([self.itsOwnerId isEqual:uid]){
        EASFKLog(@"ASFKMailbox: Group id is the same as candidate user");
        return res;
    }
    ASFKMBGroupMemberProperties* gmp=[ASFKMBGroupMemberProperties new];
    [lock1 lock];
    if([backusers containsObject:uid]){
        [lock1 unlock];
        return NO;
    }
    [gmp initFromProps:ps];
    [self fitNewMemberProps:gmp forGroup:itscprops];
    
    if(!itscprops.isPrivate){
        if([backusers count]<memLimitHigh || memLimitHigh==0){
            [backusers addObject:uid];
            //if(ps){
            [uprops setObject:gmp forKey:uid];
            //}
            res=YES;
            if(itscprops.onJoinProc){
                itscprops.onJoinProc(self.itsOwnerId, uid);
            }
        }
    }
    [lock1 unlock];
    return res;
}
-(id) addMsg:(id) msg withProperties:(ASFKMBMsgProperties *)properties group:(BOOL)grp blockable:(BOOL)blk{
    if(msg==nil){
        return nil;
    }
    if(blacklisted){
        return nil;
    }
    if([self msgCount]>ASFK_PRIVSYM_PER_MLBX_MAX_MSG_LIMIT){
        WASFKLog(@"Too many messages in container %@; delivery failed!",self.itsOwnerId);
        return nil;
    }
    
    BOOL grant=NO;
    [lock1 lock];
    if(itscprops.blockingReadwriteAllowed){
        blk &= itscprops.blockingReadwriteAllowed;
    }
    else{
        blk=NO;
    }
    
    if(properties==nil || [properties isKindOfClass:[NSNull null]]){
        grant=[self _canUserPost:nil];
    }
    else{
        grant=[self _canUserPost:properties.msgAuthorId];
    }
    if(grp==YES)
    {
        grant &=!itscprops.noPostUnpopulatedGroup || (itscprops.noPostUnpopulatedGroup && (([backusers count]) >0));
    }

    BOOL memLim= (memLimitLow==0 || ([backusers count] >= memLimitLow && memLimitLow>0))?YES:NO;
    [lock1 unlock];
    if(grant==NO){
        return nil;
    }
    id uuid=nil;

    if(memLim){
        if(grant){
            Private_ASFKMBMsg* privmsg=[Private_ASFKMBMsg new];
            privmsg.msg=msg;
            [privmsg.props initFromProps:properties];
            [privmsg.props setPropMsgId:privmsg.msgId];
            [self fitNewMsgProps:privmsg.props forGroup:itscprops];
            uuid=privmsg.msgId;
            
            if(blk==YES){
                privmsg->blocked=YES;
                privmsg->wlocker=[NSCondition new];
                BOOL success = [entranceQ push:privmsg];
                if(success){
                    [readBlocker->rlocker lock];
                    [readBlocker->rlocker signal];
                    [readBlocker->rlocker unlock];
                    [privmsg->wlocker lock];
                    [privmsg->wlocker wait];
                    [privmsg->wlocker unlock];

                }
                else{
                    uuid=nil;
                }
                
            }
            else{
                if(![entranceQ push:privmsg]){
                    uuid=nil;
                }
                else{
                    [readBlocker->rlocker lock];
                    [readBlocker->rlocker signal];
                    [readBlocker->rlocker unlock];
                }
            }
            
        }
    }
    
    return uuid;
}
#pragma mark - reading
-(NSArray*) readBlocking:(NSUInteger)amount offset:(NSUInteger)offset forUser:(id)uid latest:(BOOL) yesno{
    if(blacklisted){
        return @[];
    }
    
    NSDate* tmpoint=[NSDate date];
    [self _testAndRemove:tmpoint];
    [self _testAndAccept:tmpoint];
    NSMutableArray* ma=[NSMutableArray array];
    NSMutableArray* readMsgs=[NSMutableArray array];
    NSMutableIndexSet* iset=[NSMutableIndexSet new];
    [lock1 lock];
    if(NO==itscprops.blockingReadwriteAllowed){
        [lock1 unlock];
        return @[];
    }
    BOOL hasuser=[_users containsObject:uid] || [_itsOwnerId isEqualTo:uid];
    if(!hasuser){
        [lock1 unlock];
        return ma;
    }
    if(NO==[self _canUserRead:uid]){
        [lock1 unlock];
        return ma;
    }
    NSUInteger msc=[messages count];
    [lock1 unlock];

    if(msc < 1 || amount > msc){
        [readBlocker->rlocker lock];
        
        while(1){
            [self _testAndRemove:tmpoint];
            [self _testAndAccept:tmpoint];
            [lock1 lock];
            msc=[messages count];
            [lock1 unlock];
            if(msc < 1 ){
                [readBlocker->rlocker wait];
            }
            else{
                break;
            }
        }
        
        [readBlocker->rlocker unlock];
    }
    
    
    if(msc < 1 || offset >= msc){
        
        return ma;
    }
    
    if(amount > msc){
        amount=msc;
    }
    NSInteger lowbound=offset;
    if(yesno){
        lowbound=msc-amount;
        if(lowbound<0){
            lowbound=0;
        }
        lowbound=lowbound+offset;
    }
    
    if(lowbound>msc){
        lowbound=msc;
    }
    NSInteger hibound=lowbound+amount;
    if(hibound>msc){
        hibound=msc;
    }
    
    for (NSInteger ui=lowbound; ui<hibound; ++ui)
    {
        Private_ASFKMBMsg* privmsg=[messages objectAtIndex:ui];
        if(privmsg->blocked == YES){
            if((privmsg.props.msgDeletionTimer && [privmsg.props passedDeletionDate:tmpoint]) || privmsg.props->maxAccessLimit==0){
                [iset addIndex:ui];
            }
            else{
                [ma addObject:privmsg.msg];
                privmsg.props->maxAccessLimit.fetch_sub(1);
                [readMsgs addObject:privmsg.msgId];
                [privmsg->wlocker lock];
                [privmsg->wlocker broadcast];
                [privmsg->wlocker unlock];
            }
        }
        else
        {
            if((privmsg.props.msgDeletionTimer && [privmsg.props passedDeletionDate:tmpoint]) || privmsg.props->maxAccessLimit==0){
                [iset addIndex:ui];
            }
            else if(
               (privmsg.props.msgReadabilityTimer.itsDeadline==nil
                || [privmsg.props passedReadingDate:tmpoint])
               )
            {
                if(privmsg.props->maxAccessLimit>0)
                {
                    [ma addObject:privmsg.msg];
                    privmsg.props->maxAccessLimit.fetch_sub(1);
                    [readMsgs addObject:privmsg.msgId];
                }
            }
        }
        
    }
    [messages removeObjectsAtIndexes:iset];
    [lock1 lock];
    NSUInteger msgCount=[messages count];
    ASFKMbNotifyOnContainerReadRoutine crr=itscprops.onReadProc;
    [lock1 unlock];
    if(crr){
        crr(self.itsOwnerId,readMsgs,msgCount);
    }
    return ma;
}
-(NSArray*) read:(NSUInteger)amount offset:(NSUInteger)offset forUser:(id)uid latest:(BOOL) yesno{
    if(blacklisted){
        return @[];
    }
    NSDate* tmpoint=[NSDate date];
    [self _testAndRemove:tmpoint];
    [self _testAndAccept:tmpoint];
    NSMutableArray* ma=[NSMutableArray array];
    NSMutableArray* readMsgs=[NSMutableArray array];
    NSMutableIndexSet* iset=[NSMutableIndexSet new];
    [lock1 lock];
    BOOL hasuser=[_users containsObject:uid] || [_itsOwnerId isEqualTo:uid];
    if(!hasuser){
        [lock1 unlock];
        return @[];
    }
    if(NO==[self _canUserRead:uid]){
        [lock1 unlock];
        return @[];
    }
    NSUInteger msc=[messages count];
    
    if(offset >= msc ){
        [lock1 unlock];
        return ma;
    }

    if(msc < 1 ){
        [lock1 unlock];
        return ma;
    }
    
    if(amount>msc){
        amount=msc;
    }
    NSInteger lowbound=offset;
    if(yesno){
        lowbound=msc-amount;
        if(lowbound<0){
            lowbound=0;
        }
        lowbound=lowbound+offset;
    }

    if(lowbound>msc){
        lowbound=msc;
    }
    NSInteger hibound=lowbound+amount;
    if(hibound>msc){
        hibound=msc;
    }
    
    for (NSInteger ui=lowbound; ui<hibound; ++ui)
    {
        Private_ASFKMBMsg* privmsg=[messages objectAtIndex:ui];

        if([privmsg.props passedDeletionDate:tmpoint]){
            [iset addIndex:ui];
            if(privmsg->blocked==YES && privmsg->wlocker != nil){
                [privmsg->wlocker lock];
                [privmsg->wlocker broadcast];
                [privmsg->wlocker unlock];
            }
        }
        else{
            if((privmsg.props.msgReadabilityTimer.itsDeadline==nil
               || [privmsg.props passedReadingDate:tmpoint])
               ){
                if(privmsg.props->maxAccessLimit>0){
                    [ma addObject:privmsg.msg];
                    privmsg.props->maxAccessLimit.fetch_sub(1);
                    [readMsgs addObject:privmsg.msgId];
                }
            }
        }
    }

    [messages removeObjectsAtIndexes:iset];
    NSUInteger msgCount=[messages count];
    ASFKMbNotifyOnContainerReadRoutine crr=itscprops.onReadProc;
    ASFKMbNRunOnContainerReadRoutine rcr=itscprops.runOnReadProc;
    [lock1 unlock];
    if(crr){
        crr(self.itsOwnerId,readMsgs,msgCount);
    }
    
    if(rcr){
        rcr(self.itsOwnerId,[NSDate date],ma);
    }
    return ma;
}

-(NSUInteger) pop:(NSUInteger)amount offset:(NSUInteger)offset forUser:(id)uid latest:(BOOL)yesno{
    if(blacklisted){
        return 0;
    }
    NSDate* tmpoint=[NSDate date];
    [self _testAndRemove:tmpoint];
    [self _testAndAccept:tmpoint];

    NSMutableArray* poppedMsgs=[NSMutableArray array];
    [lock1 lock];
    BOOL hasuser=[_users containsObject:uid] || [_itsOwnerId isEqualTo:uid];
    if(!hasuser){
        [lock1 unlock];
        return 0;
    }
    if(NO==[self _canUserRead:uid]){
        [lock1 unlock];
        return 0;
    }
    NSUInteger msc=[messages count];
    if(msc<1){
        [lock1 unlock];
        return 0;;
    }
    if(offset >= msc ){
        [lock1 unlock];
        return 0;
    }
    if(amount>msc){
        amount=msc;
    }
    NSInteger lowbound=offset;
    if(yesno){
        lowbound=msc-amount;
        if(lowbound<0){
            lowbound=0;
        }
        lowbound=lowbound+offset;
    }

    NSInteger hibound=lowbound+amount;
    if(hibound>msc){
        hibound=msc;
    }
    for (NSInteger ui=lowbound; ui<hibound; ++ui) {
        Private_ASFKMBMsg* privmsg=[messages objectAtIndex:ui];
            [poppedMsgs addObject:privmsg.msgId];
            if(privmsg->blocked==YES && privmsg->wlocker != nil){
                [privmsg->wlocker lock];
                [privmsg->wlocker broadcast];
                [privmsg->wlocker unlock];
            }
    }

    NSRange rn=NSMakeRange(lowbound, hibound-lowbound);
    [messages removeObjectsInRange:rn];
    NSUInteger msgCount=[messages count];
    ASFKMbNotifyOnContainerPopRoutine cpr=itscprops.onPopProc;
    
    [lock1 unlock];
    if(cpr){
        cpr(self.itsOwnerId,poppedMsgs,msgCount);
    }
    
    return rn.length;
}
#pragma mark - deletion
-(BOOL) shouldBeDeletedAtDate:(NSDate*)aDate{
    BOOL res=NO;
    if(aDate){
        [lock1 lock];
        if(itscprops.containerDeleteTimer){
            if([itscprops.containerDeleteTimer isConditionMetAfterDateValue:aDate data:nil]){
                //[lock1 unlock];
                res=YES;
            }
        }
        [lock1 unlock];
    }
    return res;
}
-(void) purge:(NSDate*)tm{
    if(blacklisted){
        return;
    }
    [lock1 lock];
    while ([entranceQ count]>0) {
        Private_ASFKMBMsg* msg=[entranceQ pull];
        if (msg->wlocker && msg->blocked==YES) {
            [msg->wlocker lock];
            [msg->wlocker broadcast];
            [msg->wlocker unlock];
            msg->wlocker=nil;
        }
    }
    [entranceQ reset];

    [messages enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Private_ASFKMBMsg* msg=(Private_ASFKMBMsg* )obj;
        if (msg->wlocker) {
            [msg->wlocker lock];
            [msg->wlocker broadcast];
            [msg->wlocker unlock];
            msg->wlocker=nil;
        }
    }];
    [messages removeAllObjects];
    if(readBlocker->rlocker){
        [readBlocker->rlocker lock];
        [readBlocker->rlocker broadcast];
        [readBlocker->rlocker unlock];
        
    }
    ASFKMbNotifyOnContainerDiscardRoutine dp=itscprops.onDiscardProc;
    [lock1 unlock];
    if(dp){
        dp(self.itsOwnerId, tm);
    }
}
-(void) discardAllMessages{
    [self purge:[NSDate date]];
}
-(void) discardAllUsers{
    if(blacklisted){
        return;
    }
    [lock1 lock];
    [backusers removeAllObjects];
    [uprops removeAllObjects];
//    [messages removeAllObjects];
//    [entranceQ reset];
    [lock1 unlock];
}
-(void) discardUser:(id)uid{
    if(blacklisted){
        return;
    }
    [lock1 lock];
    BOOL hasuser=[_users containsObject:uid];
    if(!hasuser){
        [lock1 unlock];
        return;
    }
    [backusers removeObject:uid];
    [uprops removeObjectForKey:uid];
    [lock1 unlock];
    if(itscprops.onLeaveProc){
        itscprops.onLeaveProc(self.itsOwnerId, uid);
    }
}
#pragma mark - moderation
-(BOOL) mute:(BOOL)yesno user:(id)uid secret:(ASFKPrivateSecret *)secret group:(BOOL)grp{
    if(blacklisted){
        return NO;
    }
    if(grp){
        BOOL res=NO;
        [lock1 lock];
        BOOL hasuser=[_users containsObject:uid];
        if(!hasuser){
            [lock1 unlock];
            return NO;
        }
        ASFKMBGroupMemberProperties* up=[uprops objectForKey:uid];
        if(up){
            up.isMuted=yesno;
            res=YES;
        }
        [lock1 unlock];
        return res;
    }
    else{
        BOOL res=NO;
        [lock1 lock];

        ASFKMBGroupMemberProperties* up=[uprops objectForKey:uid];
        if(up){
            up.isMuted=yesno;
            res=YES;
        }
        else{
            if(yesno){
                ASFKMBGroupMemberProperties* u=[ASFKMBGroupMemberProperties new];
                u.isMuted=YES;
                [uprops setObject:u forKey:uid];
                res=YES;
            }
        }
        [lock1 unlock];
        return res;
    }
}
-(BOOL) muteAll:(BOOL)yesno secret:(ASFKPrivateSecret *)secret group:(BOOL)grp{
    if(blacklisted){
        return NO;
    }
    if(grp){
        BOOL res=YES;
        [lock1 lock];

        [uprops enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            BOOL hasuser=[_users containsObject:key] || [key isEqualTo:self.itsOwnerId];
            if(hasuser){
                ASFKMBGroupMemberProperties* up=(ASFKMBGroupMemberProperties* )obj;
                up.isMuted=yesno;
            }
            
        }];
        [lock1 unlock];
        return res;
    }
    else{
        BOOL res=YES;
        [lock1 lock];

        [uprops enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                ASFKMBGroupMemberProperties* up=(ASFKMBGroupMemberProperties* )obj;
                up.isMuted=yesno;
            
        }];
        [lock1 unlock];
        return res;

    }
}
-(BOOL) blind:(BOOL)yesno user:(id)uid secret:(ASFKPrivateSecret *)secret{
    if(blacklisted){
        return NO;
    }
    BOOL res=NO;
    [lock1 lock];
    BOOL hasuser=[_users containsObject:uid];
    if(!hasuser){
        [lock1 unlock];
        return NO;
    }
    ASFKMBGroupMemberProperties* up=[uprops objectForKey:uid];
    if(up){
        up.isBlinded=yesno;
        res=YES;
    }
    [lock1 unlock];
    return res;
}
-(BOOL) blindAll:(BOOL)yesno secret:(ASFKPrivateSecret *)secret{
    if(blacklisted){
        return NO;
    }
    BOOL res=YES;
    [lock1 lock];

    [uprops enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        BOOL hasuser=[_users containsObject:key] || [key isEqualTo:self.itsOwnerId];
        if(hasuser){
            ASFKMBGroupMemberProperties* up=(ASFKMBGroupMemberProperties* )obj;
            up.isBlinded=yesno;
        }
        
    }];

    [lock1 unlock];
    return res;
}
-(BOOL) retractMsg:(id)msgId{
    if(blacklisted){
        return NO;
    }
    [lock1 lock];
    [retractionList addObject:msgId];
    [lock1 unlock];
    return NO;
}
#pragma mark - maintenance
-(void) runPeriodicProc:(NSDate*)tmpoint{
    if(blacklisted){
        return;
    }
    
    [self _testAndRemove:tmpoint];
    [self _testAndAccept:tmpoint];
    [self _testAndRemove:tmpoint];
}
#pragma mark - Private methods
-(void) _testAndRemove:(NSDate*)tmpoint{
    [lock1 lock];
    NSIndexSet* inset1=[messages indexesOfObjectsPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Private_ASFKMBMsg* o=obj;
        BOOL rmCandidate=NO;
        rmCandidate |= [o.props passedDeletionDate:tmpoint];
        if([retractionList containsObject: o.props.msgId]){
            rmCandidate = YES;
            [retractionList removeObject:o.props.msgId];
            if(o->blocked){
                [o->wlocker lock];
                [o->wlocker broadcast];
                [o->wlocker unlock];
            }
        }
        else{
            [entranceQ removeObjWithProperty:o.props.msgId andBlock:^BOOL(id item, id sample, BOOL* stop) {
                Private_ASFKMBMsg* o=item;
                if (item && sample && [o.msgId isEqualTo:sample])
                {
                    *stop = YES;
                    if(o->blocked){
                        [o->wlocker lock];
                        [o->wlocker broadcast];
                        [o->wlocker unlock];
                    }
                    return YES;
                }
                return NO;
            }];
        }
        return rmCandidate;
    }];
    //[lock1 lock];

    [messages removeObjectsAtIndexes:inset1];
    //[entranceQ filterWith:nil];
    
    NSMutableArray* userstoRemove=[NSMutableArray array];
    for (id userid in backusers) {
        ASFKMBGroupMemberProperties* gmp=[uprops objectForKey:userid];
        if(gmp){
            if ([gmp passedLeavingDate:tmpoint]) {
                [userstoRemove addObject:userid];
            }
        }
    }
    for (id userid in userstoRemove) {
        [backusers removeObject:userid];
        [uprops removeObjectForKey:userid];
    }
    
    [lock1 unlock];
    
}
-(void) _testAndAccept:(NSDate*)tmpoint{
    [lock1 lock];

    NSUInteger eqsize=[entranceQ count];

    ASFKMbNotifyOnNewMsgRoutine onInb=itscprops.onNewMsgProc;
    [lock1 unlock];
    NSUInteger msgCount=0;
    for (NSUInteger i=0; i<eqsize; ++i) {
        [lock1 lock];
        if([entranceQ count]==0){
            [lock1 unlock];
            break;
        }
        
        [lock1 unlock];
        
        id msg=[entranceQ pullWithCount:msgCount];
        
        if(msg){

            [messages addObject:msg];
            ++msgCount;

        }
    }
    if(onInb && msgCount>0){
        onInb(self.itsOwnerId, msgCount);
    }
}
-(BOOL) _canUserPost:(id)uid{
    BOOL res=YES;
    if(uid==nil){
        if(!itscprops || !itscprops.anonimousPostingAllowed){
            res=NO;
        }
        else{
            res=YES;
        }
    }
    else{
        ASFKMBGroupMemberProperties* up=[uprops objectForKey:uid];
        if(up){
            res = !up.isMuted;
        }
        else{
            res=[uid isEqual:self.itsOwnerId];
        }
    }
    
    return res;
}
-(BOOL) _canUserRead:(id)uid{
    BOOL res=YES;
    if(uid==nil){

        res=NO;

    }
    else{
        ASFKMBGroupMemberProperties* up=[uprops objectForKey:uid];
        if(up){
            res = !up.isBlinded;
        }
        else{
            res=[uid isEqual:self.itsOwnerId];
        }
    }
    
    return res;
}
@end
#pragma mark - ASFKMailbox
@interface ASFKMailbox()

@end

@implementation ASFKMailbox{

    NSMutableArray* deferredCalls;
    NSMutableArray* deferredBroadcasts;
    NSMutableArray* deferredBroadcastsProps;
    NSMutableDictionary* deferredMulticastUsers;
    NSMutableDictionary* deferredMulticastProps;
    NSMutableArray* blacklistedUsers;
    NSMutableArray* blacklistedGroups;
    ASFKAuthorizationMgr* authmgr;
}


#pragma mark Singleton Methods
+ (ASFKMailbox *)sharedManager {
    static ASFKMailbox *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}
-(id) init{
    self =[super init];
    if(self){
        [self _mbInit];
    }
    return self;
}
-(void) _mbInit{
    lockDB=[NSLock new];
    lockUsersDB=[NSLock new];
    lockGroupsDB=[NSLock new];
    users=[NSMutableDictionary new];
    groups=[NSMutableDictionary new];
    deferredBroadcasts=[NSMutableArray array];
    deferredCalls=[NSMutableArray array];
    deferredBroadcastsProps=[NSMutableArray array];
    deferredMulticastUsers=[NSMutableDictionary dictionary];
    deferredMulticastProps=[NSMutableDictionary dictionary];
    blacklistedUsers=[NSMutableArray array];
    blacklistedGroups=[NSMutableArray array];
    authmgr=[ASFKAuthorizationMgr new];
    
}
#pragma mark - Secret
- (BOOL)setMasterSecret:(ASFKMasterSecret*)oldsec newSecret:(ASFKMasterSecret*)newsec {
    return [authmgr setMasterSecret:oldsec newSecret:newsec];
}
-(BOOL)setPrivateSecret:(ASFKPrivateSecret *)oldsec withNew:(ASFKPrivateSecret *)newsec forUser:(id)uid{
    if(uid==nil){
        return NO;
    }
    
    [lockUsersDB lock];
    ASFKSomeContainer* sg0=[users objectForKey:uid];
    [lockUsersDB unlock];
    if(sg0){
        if( ([sg0 isPrivateSecretValid:oldsec matcher:authmgr->secretProcSecurity]) && ([sg0 isPrivateSecretValid:oldsec matcher:authmgr->secretProcSecurity])){
            return [sg0 setPrivateSecret:oldsec newsec:newsec user:uid authMgr:authmgr];
        }
    }
    return NO;
}
-(BOOL)setGroupSecret:(ASFKGroupSecret *)oldsec withNew:(ASFKGroupSecret *)newsec forGroup:(id)gid usingPrivateSecret:(ASFKPrivateSecret *)priv{
    if(gid==nil || [gid isKindOfClass:[NSNull class]]){
        return NO;
    }
    
    [lockGroupsDB lock];
    ASFKSomeContainer* sg0=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    if(sg0){
        if( ([sg0 isPrivateSecretValid:oldsec matcher:authmgr->secretProcSecurity]) && ([sg0 isPrivateSecretValid:oldsec matcher:authmgr->secretProcSecurity])){
            return [sg0 setPrivateSecret:oldsec newsec:newsec user:gid authMgr:authmgr];
        }
    }
    return NO;
}
#pragma mark - Creation
-(id) createMailbox:(id)uid withProperties:(ASFKMBContainerProperties*)props secret:(ASFKPrivateSecret*)psecret{
    if(!uid){
        return nil;
    }

    if(YES == [self _test_mailboxes_limit:ASFK_PRIVSYM_MAX_MLBX_LIMIT]){
        [self _discard_relaxMemoryPressure:ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE];
        return nil;
    }
    ASFKMBContainerProperties* p0=[ASFKMBContainerProperties new];
    if(props==nil)
    {
        p0.anonimousPostingAllowed=YES;
        p0.isInvitable=YES;
    }
    else{
        [p0 initFromProps:props];
    }
    p0.isPrivate=YES;
    
    ASFKSomeContainer* sg=[[ASFKSomeContainer alloc]initWithUser:uid privateSecret:psecret properties:p0];
    [lockUsersDB lock];
    if([users objectForKey:uid]){
        [lockUsersDB unlock];
        return nil;
    }
    [users setObject:sg forKey:uid];
    [lockUsersDB unlock];
    return uid;
}

-(id) createGroup:(id)gid withProperties:(ASFKMBContainerProperties*)props secret:(ASFKPrivateSecret*)psecret{
    if(!gid){
        return nil;
    }
    
    if(YES == [self _test_mailboxes_limit:ASFK_PRIVSYM_MAX_MLBX_LIMIT]){
        [self _discard_relaxMemoryPressure:ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE];
        return nil;
    }
    ASFKMBContainerProperties* p0=[ASFKMBContainerProperties new];
    if(props==nil)
    {
        p0.anonimousPostingAllowed=YES;
        p0.isPrivate=NO;
    }
    else{
        [p0 initFromProps:props];
    }
    p0.isInvitable=NO;
    
    ASFKSomeContainer* sg=[[ASFKSomeContainer alloc]initWithUser:gid privateSecret:psecret properties:p0];
    [lockGroupsDB lock];
    if([groups objectForKey:gid]){
        [lockGroupsDB unlock];
        return nil;
    }
    [groups setObject:sg forKey:gid];
    [lockGroupsDB unlock];
    return gid;
}

-(id) cloneGroup:(id)gid newId:(id)newid withProperties:(ASFKMBContainerProperties*)props secret:(ASFKPrivateSecret*)psecret{
    if(YES == [self _test_mailboxes_limit:ASFK_PRIVSYM_MAX_MLBX_LIMIT]){
        [self _discard_relaxMemoryPressure:ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE];
        return nil;
    }
    if(gid!=nil && newid!=nil){
        [lockGroupsDB lock];
        ASFKSomeContainer* sg0=[groups objectForKey:gid];
        [lockGroupsDB unlock];
        BOOL ps=[sg0 isPrivateSecretValid:psecret matcher:authmgr->secretProcCreate];
        if(sg0
           && [groups objectForKey:newid]==nil
           && ps
           && [sg0 canShareUserList]
           ){
            ASFKSomeContainer* sg1=[[ASFKSomeContainer alloc]initWithUser:newid privateSecret:psecret properties:props];
            [groups setObject:sg1 forKey:newid];
            [sg0 begin];
            NSSet* res=[NSSet setWithSet:sg0.users];
            for (id user in res) {
                [sg1 addUser:user withProperties:nil];
            }
            [sg0 commit];
            
            return newid;
        }
    }
    return nil;
}
-(BOOL) addUser:(id)uid toGroup:(id)gid withProperties:(ASFKMBGroupMemberProperties*)props secret:(ASFKPrivateSecret*)psecret{
    [self _cast_relaxMemoryPressure:ASFK_PRIVSYM_MEM_PRESSURE_MLBX_THRESHOLD ];
    if(!gid || !uid){
        return NO;
    }
    
    [lockUsersDB lock];
    ASFKSomeContainer* sgu=[users objectForKey:uid];
    [lockUsersDB unlock];
    if(sgu==nil){
        EASFKLog(@"ASFKMailbox: user %@ not found, not added to group %@",uid,gid);
        return NO;
    }
    if(![sgu isInvitable]){
        EASFKLog(@"ASFKMailbox: user %@ cannot join group %@",uid,gid);
        return NO;
    }
    [lockGroupsDB lock];
    ASFKSomeContainer* sgg=[groups objectForKey:gid];
    BOOL sggvalid=(sgg && ![sgg isPrivate]);
    [lockGroupsDB unlock];
    if(sggvalid && [sgg isPrivateSecretValid:psecret matcher:authmgr->secretProcHost]){
        BOOL res=[sgg addUser:uid withProperties:props];
        return res;
    }else{
        EASFKLog(@"ASFKMailbox: group %@ not found or is not eligible for posting",gid);
    }
    
    return NO;
}
#pragma mark - maintenance
-(NSUInteger) runDiscarding:(size_t)sampleSize timepoint:(NSDate*)tm{
    dispatch_queue_t dConQ_Background=dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
    
    NSArray* ua=[self _repackItems:blacklistedUsers  sampleSize:sampleSize dispQ:dConQ_Background];
    if([ua count]>0){
        dispatch_apply([ua count], dConQ_Background, ^(size_t index) {
            ASFKSomeContainer* obj=[ua objectAtIndex:index];
            [obj purge:tm];

        });
    }
    tm=[NSDate date];
    NSArray* ga=[self _repackItems:blacklistedGroups sampleSize:sampleSize dispQ:dConQ_Background];
    if([ga count]>0){
        dispatch_apply([ga count], dConQ_Background, ^(size_t index) {

            ASFKSomeContainer* obj=[ga objectAtIndex:index];
            [obj purge:tm];

        });

    }
    
    return 0;
}
-(NSUInteger) runDeferredRoutines:(size_t)sampleSize{
    dispatch_queue_t dConQ_Background=dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
    [lockDB lock];
    //
    [lockDB unlock];
    dispatch_apply(4, dConQ_Background, ^(size_t index) {
        //
    });
    return 0;
}
-(NSUInteger) runDelivery:(size_t)sampleSize{
    dispatch_queue_t dConQ_Background=dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
    [lockDB lock];
    if([deferredBroadcasts count]>0){
        NSMutableArray* brc=nil;
        NSMutableArray* brcprops=nil;
        if(sampleSize>0){
            brc=[NSMutableArray array];
            brcprops=[NSMutableArray array];
            NSUInteger u=0;
            NSUInteger totusers=[deferredBroadcasts count];
            for (; u<sampleSize && u<totusers; ++u) {
                if(u==sampleSize){
                    break;
                }
                [brc addObject:[deferredBroadcasts objectAtIndex:u]];
                [brcprops addObject:[deferredBroadcastsProps objectAtIndex:u]];
            }
            NSRange rn=NSMakeRange(0, u);
            [deferredBroadcasts removeObjectsInRange:rn];
            [deferredBroadcastsProps removeObjectsInRange:rn];
        }else{
            brc=[NSMutableArray arrayWithArray:deferredBroadcasts];
            brcprops =[NSMutableArray arrayWithArray:deferredBroadcastsProps];
            [deferredBroadcasts removeAllObjects];
            [deferredBroadcastsProps removeAllObjects];
        }
        [lockDB unlock];
        
        [lockGroupsDB lock];
        NSArray* arg=[groups allKeys];
        [lockGroupsDB unlock];
        dispatch_apply([arg count], dConQ_Background, ^(size_t index) {
            id key=[arg objectAtIndex:index];
            [lockGroupsDB lock];
            ASFKSomeContainer* sg=[groups objectForKey:key];
            [lockGroupsDB unlock];
            if(sg && [sg isValid]){
                NSUInteger indx=0;
                ASFKMBMsgProperties* props=[brcprops objectAtIndex:indx];
                if([props isKindOfClass:[NSNull class]]){
                    props=nil;
                }else{
                    [props setPropMsgId:[NSUUID UUID]];
                }
                for (id msg in brc) {
                    [sg addMsg:msg withProperties:props group:YES blockable:NO];
                    ++indx;
                }
            }
        });
        [lockUsersDB lock];
        NSArray* aru=[users allKeys];
        [lockUsersDB unlock];
        dispatch_apply([aru count], dConQ_Background, ^(size_t index) {
            id key=[aru objectAtIndex:index];
            [lockUsersDB lock];
            ASFKSomeContainer* sg=[users objectForKey:key];
            [lockUsersDB unlock];
            if(sg && [sg isValid]){
                NSUInteger indx=0;
                ASFKMBMsgProperties* props=[brcprops objectAtIndex:indx];
                if([props isKindOfClass:[NSNull class]]){
                    props=nil;
                }else{
                    [props setPropMsgId:[NSUUID UUID]];
                }
                for (id msg in brc) {
                    [sg addMsg:msg withProperties:props group:NO blockable:NO];
                    ++indx;
                }
            }
        });
    }
    else{
        [lockDB unlock];
    }
    
    [lockDB lock];

    if([deferredMulticastUsers count]>0){
        NSMutableArray* mausr=[NSMutableArray arrayWithArray:[deferredMulticastUsers allKeys]];
        NSMutableDictionary* md=[NSMutableDictionary dictionaryWithObjects:[deferredMulticastUsers allValues] forKeys:mausr];
        NSUInteger totusers=[deferredMulticastUsers count];
        if(sampleSize>0){
            NSUInteger u=sampleSize<totusers?sampleSize:totusers;
            NSRange rn=NSMakeRange(u, totusers-u);
            [mausr removeObjectsInRange:rn];
            for (id key in mausr) {
                [deferredMulticastUsers removeObjectForKey:key];
                [deferredMulticastProps removeObjectForKey:key];
            }
        }
        else{
            deferredMulticastUsers=[NSMutableDictionary dictionary];
            deferredMulticastProps=[NSMutableDictionary dictionary];
        }
        [lockDB unlock];

        dispatch_apply([mausr count], dConQ_Background, ^(size_t index) {
            id uskey=[mausr objectAtIndex:index];
            NSArray* msgs=[md objectForKey:uskey];
            [lockUsersDB lock];
            ASFKSomeContainer* sg=[users objectForKey:uskey];
            [lockUsersDB unlock];
            ASFKMBMsgProperties* props=nil;
            for (id msg in msgs) {
                if(sg && [sg isValid]){
                    [sg addMsg:msg withProperties:props group:NO blockable:NO];
                }
            }
        });
    }else{
        [lockDB unlock];
    }

    return 0;
}
-(NSUInteger) runPeriodic:(size_t)sampleSize timepoint:(NSDate*)tm callbacks:(ASFKMBCallbacksMaintenance*)clbs{
    [lockUsersDB lock];
    NSUInteger refcount0 = [blacklistedUsers count];
    NSUInteger refcount1 = [blacklistedGroups count];
    [lockUsersDB unlock];
    [lockGroupsDB lock];
    NSUInteger refcount3 = [deferredBroadcasts count];
    NSUInteger refcount4 = [deferredMulticastUsers count];
    [lockGroupsDB unlock];
    NSUInteger objCount=refcount0+refcount1+refcount3+refcount4;
    
    //process blacklisted users
    if(tm==nil){
        tm=[NSDate date];
    }
    if(objCount>ASFK_PRIVSYM_MEM_PRESSURE_MSG_THRESHOLD){
        if(clbs && clbs->prMemPressure){
            clbs->prMemPressure(tm,objCount);
        }
    }
    //dispatch_queue_t dConQ_Background=dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
    
    //dispatch_apply(2, dConQ_Background, ^(size_t index)
    //{
        //if(index==0)
        {
            [lockUsersDB lock];
            [users enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                ASFKSomeContainer* sg=(ASFKSomeContainer*)obj;
                if(sg){
                    if([sg shouldBeDeletedAtDate:tm]){
                        [sg markBlacklisted];
                        //[blacklistedUsers addObject:sg];
                    }
                    else{
                        [sg runPeriodicProc:tm];
                    }
                    
                }
            }];
            [lockUsersDB unlock];
        }
//        else
        {
//
            [lockGroupsDB lock];
            [groups enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                ASFKSomeContainer* sg=(ASFKSomeContainer*)obj;
                if(sg){
                    if([sg shouldBeDeletedAtDate:tm]){
                        [sg markBlacklisted];
                        //[blacklistedGroups addObject:sg];
                    }
                    else{
                        [sg runPeriodicProc:tm];
                    }
                    
                }
            }];
            [lockGroupsDB unlock];
        }
    //};

    dispatch_queue_t dConQ_Background=dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
    dispatch_apply(2, dConQ_Background, ^(size_t index){
        if(index==0){
            NSMutableArray* deadkeys=[NSMutableArray new];
            [lockUsersDB lock];
            [users enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                ASFKSomeContainer* sg=(ASFKSomeContainer*)obj;
                if([sg isBlacklisted]){
                    [deadkeys addObject:key];
                }
            }];
            //blacklistedUsers = [NSMutableArray new];
            [users removeObjectsForKeys:deadkeys];
            [lockUsersDB unlock];
        }
        else{
            NSMutableArray* deadkeys=[NSMutableArray new];
            [lockGroupsDB lock];
            [groups enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                ASFKSomeContainer* sg=(ASFKSomeContainer*)obj;
                if([sg isBlacklisted]){
                    [deadkeys addObject:key];
                }
            }];
            //blacklistedGroups = [NSMutableArray new];
            [groups removeObjectsForKeys:deadkeys];
            [lockGroupsDB unlock];
        }
    });
    return 0;
}
-(NSUInteger) runDaemon:(size_t)sampleSize timepoint:(NSDate*)tm callbacks:(ASFKMBCallbacksMaintenance*)clbs{
    if(tm==nil){
        tm=[NSDate date];
    }
    [self runDiscarding:sampleSize timepoint:tm];
    [self runDelivery:sampleSize];
    [self runPeriodic:sampleSize timepoint:tm callbacks:clbs];
    return 0;
}
#pragma mark - Configuring
-(BOOL) setProperties:(ASFKMBContainerProperties*)props forMailbox:(id)uid secret:(ASFKPrivateSecret*)secret{
    if(!uid || !props){
        return NO;
    }
    BOOL res=NO;
    ASFKMBContainerProperties* p0=[ASFKMBContainerProperties new];
    [p0 initFromProps:props];
    p0.isPrivate=YES;
    p0.noPostUnpopulatedGroup=NO;
    p0.noUserListSharing=YES;
    
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    if(sg && ( [sg isPrivateSecretValid:secret matcher:authmgr->secretProcConfig])){
        res=[sg setProperties:p0];
    }
    [lockUsersDB unlock];
    return res;
}
-(BOOL) setProperties:(ASFKMBContainerProperties*)props forGroup:(id)gid secret:(ASFKPrivateSecret*)secret{
    if(!gid || !props){
        return NO;
    }
    ASFKMBContainerProperties* p0=[ASFKMBContainerProperties new];
    [p0 initFromProps:props];
    p0.isInvitable=NO;

    BOOL res=NO;

    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    if(sg && ( [sg isPrivateSecretValid:secret matcher:authmgr->secretProcConfig])){
        res=[sg setProperties:p0];
    }
    [lockGroupsDB unlock];
    return res;
}
-(BOOL) setMemberingLimitsLow:(NSUInteger)low high:(NSUInteger)high forGroup:(id)gid secret:(ASFKPrivateSecret*)secret{
    if(!gid){
        return NO;
    }
    BOOL res=NO;

    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcConfig])){
        res=[sg setMemberingLimitsLow:low high:high ];
    }
    [lockGroupsDB unlock];
    return res;
}
#pragma mark - Configuring/Queues/Group
-(BOOL) setMsgQThresholdsLow:(NSUInteger)low high:(NSUInteger)high forGroup:(id)gid secret:(ASFKPrivateSecret*)secret{
    if(!gid){
        return NO;
    }
    BOOL res=NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcConfig])){
        res=[sg setMsgQthresholdsLow:low high:high];
    }
    [lockGroupsDB unlock];
    return res;
}
-(BOOL) setMsgQDropPolicy:(eASFKQDroppingPolicy)policy forGroup:(id)gid secret:(ASFKPrivateSecret*)secret{
    if(!gid){
        return NO;
    }
    BOOL res=NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcConfig])){
        res=[sg setMsgQDropperPolicy:policy];
    }
    [lockGroupsDB unlock];
    return res;
}
-(BOOL) setMsgQDroppingAlgorithmL1:(ASFKFilter*)dropAlg forGroup:(id)gid secret:(ASFKPrivateSecret*)secret{
    if(!gid){
        return NO;
    }
    BOOL res=NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcConfig])){
        res=[sg setMsgQDropperL1:dropAlg];
    }
    [lockGroupsDB unlock];
    return res;
}
-(BOOL) setMsgQDroppingAlgorithmL2:(clbkASFKMBFilter)dropAlg forGroup:(id)gid secret:(ASFKPrivateSecret*)secret{
    if(!gid){
        return NO;
    }
    BOOL res=NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcConfig])){
        res=[sg setMsgQDropperL2:dropAlg];
    }
    [lockGroupsDB unlock];
    return res;
}
#pragma mark - Configuring/Queues/Mailbox
-(BOOL) setMsgQThresholdsLow:(NSUInteger)low high:(NSUInteger)high forMailbox:(id)uid secret:(ASFKPrivateSecret*)secret{
    if(!uid){
        return NO;
    }
    BOOL res=NO;

    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcConfig])){
        res=[sg setMsgQthresholdsLow:low high:high];
    }
    [lockUsersDB unlock];
    return res;
}
-(BOOL) setMsgQDropPolicy:(eASFKQDroppingPolicy)policy forMailbox:(id)uid secret:(ASFKPrivateSecret*)secret{
    if(!uid){
        return NO;
    }
    BOOL res=NO;
    
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcConfig])){
        res=[sg setMsgQDropperPolicy:policy];
    }
    [lockUsersDB unlock];
    return res;
}
-(BOOL) setMsgQDroppingAlgorithmL1:(ASFKFilter*)dropAlg forMailbox:(id)uid secret:(ASFKPrivateSecret*)secret{
    if(!uid){
        return NO;
    }
    BOOL res=NO;
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcConfig])){
        res=[sg setMsgQDropperL1:dropAlg];
    }
    [lockUsersDB unlock];
    return res;
}
-(BOOL) setMsgQDroppingAlgorithmL2:(clbkASFKMBFilter)dropAlg forMailbox:(id)uid secret:(ASFKPrivateSecret*)secret{
    if(!uid){
        return NO;
    }
    BOOL res=NO;
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcConfig])){
        res=[sg setMsgQDropperL2:dropAlg];
    }
    [lockUsersDB unlock];
    return res;
}

#pragma mark - Discarding
-(BOOL) discardMailbox:(id)uid secret:(ASFKSecret*)secret{
    [self _discard_relaxMemoryPressure: ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE];
    
    if(!uid){
        return NO;
    }
    BOOL ms=NO;
    if([secret isKindOfClass:[ASFKMasterSecret class]]){
        ms=[authmgr isMasterSecretValid:((ASFKMasterSecret*)secret) matcher:authmgr->secretProcDiscard];
    }
    BOOL res=NO;
    
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    [lockUsersDB unlock];
    if(sg ){
        BOOL ps=NO;
        if(ms==NO){
            ps=[sg isPrivateSecretValid:((ASFKPrivateSecret*)secret) matcher:authmgr->secretProcDiscard];
        }
        if ( ms || ps){
            [sg markBlacklisted];
            [lockDB lock];
            [blacklistedUsers addObject:sg];
            [lockDB unlock];
            [lockUsersDB lock];
            [users removeObjectForKey:uid];
            [lockUsersDB unlock];
            res=YES;
        }
    }
    
    return res;
}
-(BOOL) discardGroup:(id)gid secret:(ASFKSecret*)secret{
    [self _discard_relaxMemoryPressure: ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE];
    
    if(!gid){
        return NO;
    }
    
    BOOL res=NO;
    BOOL ms= NO;
    if([secret isKindOfClass:[ASFKMasterSecret class]]){
        ms=[authmgr isMasterSecretValid:((ASFKMasterSecret*)secret) matcher:authmgr->secretProcDiscard];
    }
    
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    
    if(sg){
        BOOL ps=NO;
        if(ms==NO){
            ps=[sg isPrivateSecretValid:((ASFKPrivateSecret*)secret) matcher:authmgr->secretProcDiscard];
        }
        if( ms || ps){
            [sg markBlacklisted];
            [lockDB lock];
            [blacklistedGroups addObject:sg];
            [lockDB unlock];
            [lockGroupsDB lock];
            [groups removeObjectForKey:gid];
            [lockGroupsDB unlock];
            res=YES;
        }
    }
    
    return res;
}
-(BOOL) discardAllMailboxesWithSecret:(ASFKMasterSecret*)secret{
    [self _discard_relaxMemoryPressure: ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE];
    
    if(![authmgr isMasterSecretValid:secret matcher:authmgr->secretProcDiscard]){
        return NO;
    }
    ASFKLog(@"Discarding all users");
    [lockUsersDB lock];
    [lockDB lock];
    [blacklistedUsers addObject:users];
    [lockDB unlock];

    users=[NSMutableDictionary dictionary];
    [lockUsersDB unlock];
    return YES;
}
-(BOOL) discardAllGroupsWithSecret:(ASFKMasterSecret*)secret{
    ASFKLog(@"Discarding all groups");
    [self _discard_relaxMemoryPressure: ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE];
    
    if(NO==[authmgr isMasterSecretValid:secret matcher:authmgr->secretProcDiscard]){
        return NO;
    }
    [lockGroupsDB lock];
    [lockDB lock];
    [blacklistedGroups addObject:groups];
    [lockDB unlock];
    groups=[NSMutableDictionary dictionary];
    [lockGroupsDB unlock];
    return YES;
}
-(BOOL) discardAllMessagesWithSecret:(ASFKMasterSecret*)secret{
    ASFKLog(@"Discarding messages from groups");
    [self _discard_relaxMemoryPressure: ASFK_PRIVSYM_MSG_RELEASE_SAMPLE_SIZE];
    
    BOOL ms=[authmgr isMasterSecretValid:secret matcher:authmgr->secretProcDiscard];
    if(ms==NO){
        return NO;
    }
    [lockGroupsDB lock];

    [groups enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        ASFKSomeContainer* sg=(ASFKSomeContainer*)obj;
        if(sg && ms){
            [sg discardAllMessages];
        }
    }];
    [lockGroupsDB unlock];
    ASFKLog(@"Discarding messages from users");
    [lockUsersDB lock];

    [users enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        ASFKSomeContainer* sg=(ASFKSomeContainer*)obj;
        if(sg && ms){
            [sg discardAllMessages];
        }
    }];
    [lockUsersDB unlock];
    return YES;
}
-(BOOL) discardAllMessagesFromMailbox:(id)uid secret:(ASFKPrivateSecret*)secret{
    ASFKLog(@"Discarding ALL messages from user %@",uid);
    [self _discard_relaxMemoryPressure: ASFK_PRIVSYM_MSG_RELEASE_SAMPLE_SIZE];
    if( !uid){
        return NO;
    }
    BOOL res=NO;
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    [lockUsersDB unlock];
    if(sg && [sg isPrivateSecretValid:secret matcher:authmgr->secretProcHost]){
        [sg discardAllMessages];
        res=YES;
    }
    
    return res;
}
-(BOOL) discardAllMessagesFromGroup:(id)gid secret:(ASFKPrivateSecret*)secret{
    ASFKLog(@"Discarding ALL messages from group %@",gid);
    [self _discard_relaxMemoryPressure: ASFK_PRIVSYM_MSG_RELEASE_SAMPLE_SIZE];
    
    if( !gid){
        return NO;
    }
    BOOL res=NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcHost])){
        [sg discardAllMessages];
        res=YES;
    }
    return res;
}
-(BOOL) discardUsers:(NSArray*)uids fromGroup:(id)gid  secret:(ASFKPrivateSecret*)secret{
    ASFKLog(@"Discarding ALL users from group %@",gid);
    [self _discard_relaxMemoryPressure: ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE];
    if(!uids || !gid){
        return NO;
    }
    if([uids count]==0){
        return NO;
    }
    BOOL res=NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcHost])){
        for (id uid in uids) {
            [sg discardUser:uid];
        }
        res=YES;
    }
    else{
        EASFKLog(@"ASFKMailbox: group not found for key %@",gid);
        return NO;
    }
    return res;
}
-(BOOL) discardUser:(id)uid fromGroup:(id)gid secret:(ASFKPrivateSecret*)secret{
    [self _discard_relaxMemoryPressure: ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE];
    if(!uid || !gid){
        return NO;
    }
    BOOL res=NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcHost])){
        [sg discardUser:uid];
        res=YES;
    }
    else{
        EASFKLog(@"ASFKMailbox: group not found for key %@",gid);
        return NO;
    }
    return res;
}
-(BOOL) discardAllUsersFromGroup:(id)gid  secret:(ASFKPrivateSecret*)secret{
    [self _discard_relaxMemoryPressure: ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE];
    if(!gid ){
        return NO;
    }
    [lockGroupsDB lock];
        ASFKSomeContainer* sg=[groups objectForKey:gid];
        if(sg && ( [sg isPrivateSecretValid:secret matcher:authmgr->secretProcHost])){
            [sg discardAllUsers];
        }
    [lockGroupsDB unlock];
    return YES;
}
-(BOOL) discardUserFromAllGroups:(id)uid secret:(ASFKMasterSecret*)secret{
    [self _discard_relaxMemoryPressure: ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE];
    if(!uid ){
        return NO;
    }
    BOOL ms=[authmgr isMasterSecretValid:secret matcher:authmgr->secretProcDiscard];
    if(ms==NO){
        return NO;
    }
    [lockGroupsDB lock];

    [groups enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        ASFKSomeContainer* sg=(ASFKSomeContainer*)obj;
        if(sg && (YES==ms /*|| [sg isPrivateSecretValid:secret]*/)){
            [sg discardUser:uid];
        }
    }];
    [lockGroupsDB unlock];

    return YES;
}
#pragma mark - Stats
-(NSUInteger) totalMessages{
    __block NSUInteger c0=0;
    [lockUsersDB lock];
    [users enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        ASFKSomeContainer* sg=(ASFKSomeContainer*)obj;
        if(sg && [sg isValid]){
            c0+=[sg msgCount];
        }
    }];

    [lockUsersDB unlock];
    __block NSUInteger c1=0;
    [lockGroupsDB lock];
    [groups enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        ASFKSomeContainer* sg=(ASFKSomeContainer*)obj;
        if(sg && [sg isValid]){
            c1+=[sg msgCount];
        }
    }];

    [lockGroupsDB unlock];
    return c0+c1;
}
-(NSUInteger) totalGroups{
    [lockGroupsDB lock];
    NSUInteger c=[groups count];
    [lockGroupsDB unlock];
    return c;
}
-(NSUInteger) totalMailboxes{
    [lockUsersDB lock];
    NSUInteger c=[users count];
    [lockUsersDB unlock];
    return c;
}
-(NSUInteger) totalMessagesInGroup:(id)gid{
    if(!gid){
        return 0;
    }
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    NSUInteger c=0;
    [lockGroupsDB unlock];
    if(sg){
        c=[sg msgCount];
    }else{
        EASFKLog(@"ASFKMailbox: group not found for key %@",gid);
    }
    return c;
}
-(NSUInteger) totalMessagesInMailbox:(id)uid{
    if(!uid){
        return 0;
    }
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    [lockUsersDB unlock];
    NSUInteger c=0;
    if(sg){
        c=[sg msgCount];
    }else{
        EASFKLog(@"ASFKMailbox: user not found for key %@",uid);
    }
    return c;
}
-(NSUInteger) totalUsersInGroup:(id)gid{
    if(!gid){
        return 0;
    }
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    NSUInteger c=0;
    [lockGroupsDB unlock];
    if(sg && [sg isValid]){
        c=[sg userCount];
    }else{
        EASFKLog(@"ASFKMailbox: group not found for key %@",gid);
    }
    return c;
}
#pragma mark - Read with blocking
-(NSArray*) waitAndReadMsg:(NSRange)skipAndTake fromMailbox:(id)mid unblockIf:(ASFKMbLockConditionRoutine)condition withSecret:(ASFKPrivateSecret*)secret{
    if(!mid){
        return @[];
    }
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:mid];
    [lockUsersDB unlock];

    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcRead])){
        NSArray* a=[sg readBlocking:skipAndTake.length offset:skipAndTake.location forUser:mid latest:YES];
        return a;
    }
    return @[];
}

#pragma mark - Read without blocking
-(NSArray*) readEarliestMsg:(NSRange)skipAndTake fromMailbox:(id)uid withSecret:(ASFKPrivateSecret*)secret{
    if(!uid){
        return @[];
    }

    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    [lockUsersDB unlock];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcRead])){
        NSArray* a=[sg read:skipAndTake.length offset:skipAndTake.location forUser:uid latest:NO];
        return a;
    }
    return @[];
}
-(NSArray*) readLatestMsg:(NSRange)skipAndTake fromMailbox:(id)uid withSecret:(ASFKPrivateSecret*)secret{
    if(!uid){
        return @[];
    }
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    [lockUsersDB unlock];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcRead])){
        NSArray* a=[sg read:skipAndTake.length offset:skipAndTake.location forUser:uid latest:YES];
        return a;
    }
    return @[];
}
-(NSArray*) readEarliestMsg:(NSRange)skipAndTake fromGroup:(id)gid forUser:(id)uid withSecret:(ASFKPrivateSecret*)secret{
    if(!gid || !uid){
        return @[];
    }

    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    NSArray* a=nil;
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcRead])){
        a=[sg read:skipAndTake.length offset:skipAndTake.location forUser:uid latest:NO];
    }
    else{
        a=@[];
    }
    
    return a;
}
-(NSArray*) readLatestMsg:(NSRange)skipAndTake fromGroup:(id)gid forUser:(id)uid withSecret:(ASFKPrivateSecret*)secret{
    if(!gid || !uid){
        return @[];
    }
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];

    NSArray* a=nil;
    if(sg && ( [sg isPrivateSecretValid:secret matcher:authmgr->secretProcRead])){
        a=[sg read:skipAndTake.length offset:skipAndTake.location forUser:uid latest:YES];
    }
    else{
        a=@[];
    }
    
    return a;
}
-(NSUInteger) popEarliestMsg:(NSRange)skipAndTake  fromMailbox:(id)uid withSecret:(ASFKPrivateSecret*)secret{
    if(!uid){
        return 0;
    }

    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    [lockUsersDB unlock];
    if(sg &&([sg isPrivateSecretValid:secret matcher:authmgr->secretProcPop])){
        NSUInteger a=[sg pop:skipAndTake.length offset:skipAndTake.location forUser:uid latest:NO];
        return a;
    }
    return 0;
}
-(NSUInteger) popLatestMsg:(NSRange)skipAndTake fromMailbox:(id)uid withSecret:(ASFKPrivateSecret*)secret{
    if(!uid){
        return 0;
    }

    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    [lockUsersDB unlock];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcPop])){
        NSUInteger a=[sg pop:skipAndTake.length offset:skipAndTake.location forUser:uid latest:YES];
        return a;
    }
    return 0;
}
-(void) popLatestMsg:(NSRange)skipAndTake  fromGroup:(id)gid forUser:(id)uid withSecret:(ASFKPrivateSecret*)secret {
    if(!gid || !uid){
        return ;
    }

    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcPop])){
        [sg pop:skipAndTake.length offset:skipAndTake.location forUser:uid latest:YES];
    }
}
-(void) popEarliestMsg:(NSRange)skipAndTake fromGroup:(id)gid forUser:(id)uid withSecret:(ASFKPrivateSecret*)secret{
    if(!gid || !uid){
        return ;
    }

    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:gid];
    [lockUsersDB unlock];
    if(sg && ([sg isPrivateSecretValid:secret matcher:authmgr->secretProcPop])){
        [sg pop:skipAndTake.length offset:skipAndTake.location forUser:uid latest:NO];
    }
}

#pragma mark - Unicasting
-(id) cast:(id)msg forMailbox:(id)uid withProperties:(ASFKMBMsgProperties*)props secret:(ASFKPrivateSecret*)secret{
    [self _cast_relaxMemoryPressure:ASFK_PRIVSYM_MEM_PRESSURE_MSG_THRESHOLD ];
    if(!uid || !msg){
        return nil;
    }
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    [lockUsersDB unlock];
    if(sg && [sg isPrivateSecretValid:secret matcher:authmgr->secretProcUnicast]){
        return [sg addMsg:msg withProperties:props group:NO blockable:NO];
    }
    return nil;
}
-(id) cast:(id)msg forGroup:(id)gid withProperties:(ASFKMBMsgProperties*)props secret:(ASFKPrivateSecret*)secret{
    [self _cast_relaxMemoryPressure:ASFK_PRIVSYM_MEM_PRESSURE_MSG_THRESHOLD ];
    if(!gid || !msg){
        return nil;
    }

    id res=nil;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    if(sg && [sg isPrivateSecretValid:secret matcher:authmgr->secretProcUnicast]){

        res=[sg addMsg:msg withProperties:props group:YES blockable:NO];
    }
    
    return res;
}
-(id) call:(id)msg forMailbox:(id)uid withProperties:(ASFKMBMsgProperties *)props unblockIf:(ASFKCondition*)condition secret:(ASFKPrivateSecret*)secret{
    [self _cast_relaxMemoryPressure:ASFK_PRIVSYM_MEM_PRESSURE_MSG_THRESHOLD ];
    if(!uid || !msg){
        return nil;
    }
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    [lockUsersDB unlock];
    if(sg && [sg isPrivateSecretValid:secret matcher:authmgr->secretProcUnicast]){

        return [sg addMsg:msg withProperties:props group:NO blockable:YES];
    }
    return nil;
}

#pragma mark - Multicasting
-(BOOL) broadcast:(id)msg withProperties:(ASFKMBMsgProperties*)props secret:(ASFKSecret*)secret{
    [self _cast_relaxMemoryPressure:ASFK_PRIVSYM_MEM_PRESSURE_MSG_THRESHOLD ];
    if(!msg){
        return NO;
    }
    BOOL ms=NO;
    ms=[authmgr isMasterSecretValid:(secret) matcher:authmgr->secretProcMulticast];
    [lockDB lock];
    [deferredBroadcasts addObject:msg];
    if(!props){
        [deferredBroadcastsProps addObject:[NSNull null]];
    }else{
        [props setPropMsgRetractBeforeDate:nil];
        [deferredBroadcastsProps addObject:props];
    }
    [lockDB unlock];
    return YES;
}
-(id) multicast:(id)msg toMembersOfGroup:(id)g0 secret:(ASFKSecret*)secret{
    [self _cast_relaxMemoryPressure:ASFK_PRIVSYM_MEM_PRESSURE_MSG_THRESHOLD ];
    if(msg==nil){
        return nil;
    }
    BOOL validSecret=NO;
    if([secret isKindOfClass:[ASFKMasterSecret class]]){
        validSecret=[authmgr isMasterSecretValid:((ASFKMasterSecret*)secret) matcher:authmgr->secretProcMulticast];
    }
    if(g0!=nil){
        [lockGroupsDB lock];
        ASFKSomeContainer* sg0=[groups objectForKey:g0];
        if(sg0 && [sg0 isValid] && [sg0 canShareUserList]){
            [lockGroupsDB unlock];
            id retval=nil;
            if(validSecret==NO){
                validSecret=[sg0 isPrivateSecretValid:(ASFKPrivateSecret*)secret matcher:authmgr->secretProcMulticast];
            }
            if(validSecret==NO){
                return retval;
            }
            
            [sg0 begin];
            NSMutableSet* res=[NSMutableSet setWithSet:sg0.users];
            [sg0 commit];
            if([res count]>0){
                ASFKMBMsgProperties* mprops=[ASFKMBMsgProperties new];
                [self _castToSetOfUsers:res msg:msg properties:mprops];
                retval=mprops.msgId;
            }
            
            return retval;
        }
        [lockDB unlock];
    }
    return nil;
}

#pragma mark - Message hiding & retraction
-(BOOL) retractMsg:(id)msgId fromGroup:(id)gid secret:(ASFKPrivateSecret*)secret{
    if(!msgId || !gid)
        return NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    BOOL res=NO;
    if(sg && [sg canRetract] &&[sg isPrivateSecretValid:secret matcher:authmgr->secretProcIssuer]){
        res=[sg retractMsg:msgId];
    }
    return res;
}
-(BOOL) retractMsg:(id)msgId fromMailbox:(id)uid secret:(ASFKPrivateSecret*)secret{
    if(!msgId || !uid)
        return NO;
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uid];
    [lockUsersDB unlock];
    BOOL res=NO;
    if(sg && [sg canRetract] && [sg isPrivateSecretValid:secret matcher:authmgr->secretProcIssuer]){
        res=[sg retractMsg:msgId];
    }
    return res;
}
-(BOOL) mute:(BOOL)yesno user:(id)uid inGroup:(id)gid secret:(ASFKPrivateSecret *)secret{
    if(!gid || !uid)
        return NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    if(sg && [sg isPrivateSecretValid:secret matcher:authmgr->secretProcModerate]){
        return [sg mute:yesno user:uid secret:secret group:YES];
    }
    return NO;
}
-(BOOL) muteAll:(BOOL)yesno inGroup:(id)gid secret:(ASFKPrivateSecret *)secret{
    if(!gid )
        return NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    if(sg && [sg isPrivateSecretValid:secret matcher:authmgr->secretProcModerate]){
        return [sg muteAll:yesno secret:secret group:YES];
    }
    return NO;
}
-(BOOL) mute:(BOOL)yesno user:(id)uidguest inMailbox:(id)uidhost secret:(ASFKPrivateSecret *)secret{
    if(!uidguest || !uidhost)
        return NO;
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uidhost];
    [lockUsersDB unlock];
    if(sg && [sg isPrivateSecretValid:secret matcher:authmgr->secretProcModerate]){
        return [sg mute:yesno user:uidguest secret:secret group:NO];
    }
    return NO;
}
-(BOOL) muteAll:(BOOL)yesno inMailbox:(id)uidhost secret:(ASFKPrivateSecret *)secret{
    if(!uidhost)
        return NO;
    [lockUsersDB lock];
    ASFKSomeContainer* sg=[users objectForKey:uidhost];
    [lockUsersDB unlock];
    if(sg && [sg isPrivateSecretValid:secret matcher:authmgr->secretProcModerate]){
        return [sg muteAll:yesno secret:secret group:NO];
    }
    return NO;
}
-(BOOL) blind:(BOOL)yesno user:(id)uidguest inGroup:(id)gid secret:(ASFKPrivateSecret *)secret{
    if(!gid || !uidguest)
        return NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    if(sg &&[sg isPrivateSecretValid:secret matcher:authmgr->secretProcModerate]){
        return [sg blind:yesno user:uidguest secret:secret];
    }
    return NO;
}
-(BOOL) blindAll:(BOOL)yesno inGroup:(id)gid secret:(ASFKPrivateSecret *)secret{
    if(!gid )
        return NO;
    [lockGroupsDB lock];
    ASFKSomeContainer* sg=[groups objectForKey:gid];
    [lockGroupsDB unlock];
    if(sg &&[sg isPrivateSecretValid:secret matcher:authmgr->secretProcModerate]){
        return [sg blindAll:yesno secret:secret];
    }
    return NO;
}
#pragma mark - Private methods
-(void) _castToSetOfUsers:(NSSet*) uset msg:(id)msg properties:(ASFKMBMsgProperties*)props{
    if(uset && msg){
        [props setPropMsgId:[NSUUID UUID]];
        
        [lockDB lock];
        for (id u in uset) {
            NSMutableArray* ma;
            ma=[deferredMulticastUsers objectForKey:u];
            if(ma){
                [ma addObject:msg];
            }
            else{
                ma=[NSMutableArray array];
                [ma addObject:msg];
                [deferredMulticastUsers setObject:ma forKey:u];
                if(!props){
                    [deferredMulticastProps setObject:[NSNull null] forKey:u];
                }else{
                    [deferredMulticastProps setObject:props forKey:u];
                }
            }
        }
        [lockDB unlock];
    }
    
}
-(void) _castToArrayOfUsers:(NSArray*)uarr msg:(id)msg properties:(ASFKMBMsgProperties*)props{
//    [lockDB lock];
//    NSUInteger defrefcount= [deferredMulticastUsers count];
//    [lockDB unlock];
//    if(defrefcount>ASFK_PRIVSYM_MEM_PRESSURE_MSG_THRESHOLD){
        [self _cast_relaxMemoryPressure: ASFK_PRIVSYM_MSG_RELEASE_SAMPLE_SIZE];
//    }
    if(uarr && msg){
        [props setPropMsgId:[NSUUID UUID]];
        [lockDB lock];
        for (id u in uarr) {
            NSMutableArray* ma=[deferredMulticastUsers objectForKey:u];
            if(ma){
                [ma addObject:msg];
            }
            else{
                [deferredMulticastUsers setObject:[NSMutableArray array] forKey:u];
                if(!props){
                    [deferredMulticastProps setObject:[NSNull null] forKey:u];
                }
                else{
                    [deferredMulticastProps setObject:props forKey:u];
                }
            }
            
        }
        
        [lockDB unlock];
    }
    
}
-(void) _cast_relaxMemoryPressure:(size_t)sampleSize{
    [lockDB lock];
    NSUInteger defrefcount0= [deferredBroadcasts count];
    NSUInteger defrefcount1= [deferredMulticastUsers count];
    [lockDB unlock];
    
    if(defrefcount0 > ASFK_PRIVSYM_MEM_PRESSURE_MSG_THRESHOLD || ASFK_PRIVSYM_MEM_PRESSURE_MSG_THRESHOLD > ASFK_PRIVSYM_MEM_PRESSURE_MSG_THRESHOLD){
        [self runDelivery:sampleSize ];
    }
    
}
-(void) _discard_relaxMemoryPressure:(size_t)sampleSize{
    //if(NO==[self _test_mailboxes_limit:ASFK_PRIVSYM_MEM_PRESSURE_MLBX_THRESHOLD])
    //{
        WASFKLog(@"Too many mailboxes or groups created!");
    [self runDiscarding:sampleSize timepoint:[NSDate date]] ;
    //}
        
}
-(BOOL) _test_mailboxes_limit:(NSUInteger)limit{
    [lockDB lock];
    NSUInteger defrefcount0= [blacklistedUsers count];
    NSUInteger defrefcount1= [blacklistedGroups count];
    [lockDB unlock];
    [lockUsersDB lock];
    NSUInteger ucount= [users count];
    [lockUsersDB unlock];
    [lockGroupsDB lock];
    NSUInteger gcount= [groups count];
    [lockGroupsDB unlock];
    
    return limit<=defrefcount0+defrefcount1+ucount+gcount;
}
-(NSArray<ASFKSomeContainer*>*) _repackItems:(NSMutableArray*)containers sampleSize:(size_t)iter dispQ:(dispatch_queue_t)dq{
    NSMutableArray<ASFKSomeContainer*>* ma=[NSMutableArray array];
    
    for (NSUInteger i=0; i<iter; ++i) {
        [lockDB lock];
        id obj=[containers firstObject];
        [lockDB unlock];
        if(!obj){
            break;
        }
        if([obj isKindOfClass:[NSMutableDictionary class]]){
            NSMutableArray<ASFKSomeContainer*>* chunk=[NSMutableArray array];
            NSMutableArray* obsolete=[NSMutableArray array];
            [obj enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull object, BOOL * _Nonnull stop) {
                [chunk addObject:object ];
                [obsolete addObject:key];
                if([chunk count]==iter){
                    *stop=YES;;
                }
            }];

            for (id key in obsolete) {
                [obj removeObjectForKey:key];
            }
            if([obj count]==0){
                [lockDB lock];
                if([containers count]>0){
                    [containers removeObjectAtIndex:0];
                }
                [lockDB unlock];
            }
            
            return chunk;
        }
        else{
            [ma addObject:(ASFKSomeContainer*)obj];
            [lockDB lock];
            if([containers count]>0){
                [containers removeObjectAtIndex:0];
            }
            [lockDB unlock];
        }
    }
    
    return ma;
}
@end
