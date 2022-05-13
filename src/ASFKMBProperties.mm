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
#import "ASFKMBProperties.h"

#pragma mark - Group member
@implementation ASFKMBGroupMemberProperties
-(id)init{
    self=[super init];
    if(self){
        _grpMemLeaveTimer=[ASFKConditionTemporal new];
        _isBlinded=NO;
        _isMuted=NO;
    }
    return self;
}
-(void) initFromProps:(ASFKMBGroupMemberProperties *)p{
    if(p){
        [_grpMemLeaveTimer setDelay:p.grpMemLeaveTimer.itsDelay];
        _isBlinded=p.isBlinded;
        _isMuted=p.isMuted;
    }
}
-(BOOL) passedLeavingDate:(NSDate *)date{
     if(_grpMemLeaveTimer){
            return [_grpMemLeaveTimer isConditionMetAfterDateValue:date data:nil];
        }
    return NO;
}
-(void) setPropLeaveOnDate:(NSDate *)date{
    if(_grpMemLeaveTimer){
        [_grpMemLeaveTimer setDueDate:date];
    }
}
-(void) setPropLeaveAfterSeconds:(NSTimeInterval)seconds{
    if(_grpMemLeaveTimer){
        [_grpMemLeaveTimer setDelay:seconds];
        [_grpMemLeaveTimer delayToDeadline];
    }
}
@end
#pragma mark - Message
@implementation ASFKMBMsgProperties{

}
-(id)init{
    self=[super init];
    if(self){
        _msgAuthorId=nil;
        _msgId=nil;
        maxAccessLimit=INTMAX_MAX;
        _msgRetractionTimer=[ASFKConditionTemporal new];
        _msgDeletionTimer=[ASFKConditionTemporal new];
        _msgReadabilityTimer=[ASFKConditionTemporal new];
        self.blocking=NO;
    }
    return self;
}
-(void) initFromProps:(ASFKMBMsgProperties *)p{
    if(p){
        _msgAuthorId=p.msgAuthorId;
        maxAccessLimit=p->maxAccessLimit.load();
        [_msgRetractionTimer setDelay:p.msgRetractionTimer.itsDelay];
        [_msgDeletionTimer setDelay:p.msgDeletionTimer.itsDelay];
        [_msgReadabilityTimer setDelay:p.msgReadabilityTimer.itsDelay];
        [_msgRetractionTimer setDueDate:p.msgRetractionTimer.itsDeadline];
        [_msgDeletionTimer setDueDate:p.msgDeletionTimer.itsDeadline];
        [_msgReadabilityTimer setDueDate:p.msgReadabilityTimer.itsDeadline];
        self.blocking=p.blocking;
    }
}
-(void) setPropDeleteOnDate:(NSDate *)date{
    if(_msgDeletionTimer){
        [_msgDeletionTimer setDueDate:date];
    }
}
-(void) setPropDeleteAfterSeconds:(NSTimeInterval)seconds{
    if(_msgDeletionTimer){
        [_msgDeletionTimer setDelay:seconds];
        [_msgDeletionTimer delayToDeadline];
    }
}

-(void) setPropMsgId:(NSUUID *)mId{
    _msgId=mId;
}
-(void) setPropMsgMaxReadLimit:(NSUInteger)limit{
    maxAccessLimit=limit;
}
-(void) setPropMsgAuthorId:(id)authorId{
    _msgAuthorId=authorId;
}

-(void) setPropMsgRetractInSeconds:(NSTimeInterval)seconds{
    if(self.msgRetractionTimer){
        [self.msgRetractionTimer setDelay:seconds];
        [self.msgRetractionTimer delayToDeadline];
    }
}
-(void) setPropMsgRetractBeforeDate:(NSDate *)date{
    if(self.msgRetractionTimer){
        [self.msgRetractionTimer setDueDate:date];
    }
}
-(void) setPropReadOnDate:(NSDate *)date{
    if(self.msgReadabilityTimer){
        [_msgReadabilityTimer setDueDate:date];
    }
}
-(void) setPropReadAfterSeconds:(NSTimeInterval)seconds{
    if(_msgReadabilityTimer){
        [_msgReadabilityTimer setDelay:seconds];
        [_msgReadabilityTimer delayToDeadline];
    }

}
-(BOOL) passedRetractionDate:(NSDate *)date{
    if(_msgRetractionTimer){
        return [_msgRetractionTimer isConditionMetAfterDateValue:date data:nil];
    }
    return NO;
}
-(BOOL) passedReadingDate:(NSDate *)date{
    if(_msgReadabilityTimer){
        return [_msgReadabilityTimer isConditionMetAfterDateValue:date data:nil];
    }
    return NO;
}
-(BOOL) passedDeletionDate:(NSDate *)date{
    if(_msgDeletionTimer){
        return [_msgDeletionTimer isConditionMetAfterDateValue:date data:nil];
    }
    return NO;
}
@end
#pragma mark - Container/Group
@implementation ASFKMBContainerProperties
-(id)init{
    self=[super init];
    if(self){
        self.onNewMsgProc=nil;
        self.onPopProc=nil;
        self.onReadProc=nil;
        self.containerFilterProc=nil;
        self.onJoinProc=nil;
        self.onLeaveProc=nil;
        self.onDiscardProc=nil;
        self.feedbackProc=nil;
        _containerDeleteTimer=[ASFKConditionTemporal new];
        _containerKickoutTimer=[ASFKConditionTemporal new];
        _containerDropMsgTimer=[ASFKConditionTemporal new];
        self.anonimousPostingAllowed=YES;
        self.isInvitable=YES;
        self.noPostUnpopulatedGroup=YES;
        self.noUserListSharing=NO;
        self.isPrivate=NO;
        self.retractionAllowed=YES;
        self.blockingReadwriteAllowed=NO;
    }
    return self;
}
-(void) initFromProps:(ASFKMBContainerProperties*)p{
    if(p){
        self.onNewMsgProc=p.onNewMsgProc;
        self.onPopProc=p.onPopProc;
        self.onReadProc=p.onReadProc;
        self.containerFilterProc=p.containerFilterProc;
        self.onJoinProc=p.onJoinProc;
        self.onLeaveProc=p.onLeaveProc;
        self.onDiscardProc=p.onDiscardProc;
        self.isInvitable=p.isInvitable;
        self.isPrivate=p.isPrivate;
        self.anonimousPostingAllowed=p.anonimousPostingAllowed;
        self.noPostUnpopulatedGroup=p.noPostUnpopulatedGroup;
        self.noUserListSharing=p.noUserListSharing;
        self.retractionAllowed=p.retractionAllowed;
        self.blockingReadwriteAllowed=p.blockingReadwriteAllowed;;
        [_containerDeleteTimer setFromTemporalCondition:p.containerDeleteTimer];
        [_containerDropMsgTimer setFromTemporalCondition:p.containerDropMsgTimer];
        [_containerKickoutTimer setFromTemporalCondition:p.containerKickoutTimer];
        
    }
}
-(void) setPropMsgCustomCondition:(ASFKCondition *)msgCustomCond{
    
}
-(void) setPropDeleteAfterSeconds:(NSTimeInterval)seconds{
    [self.containerDeleteTimer setDelay:seconds];
    [self.containerDeleteTimer delayToDeadline];
    //}
}
-(void) setPropKickoutAfterSeconds:(NSTimeInterval)seconds{
    //if( seconds>0){
        [self.containerKickoutTimer setDelay:seconds];
    [self.containerKickoutTimer delayToDeadline];
    //}
}
-(void) setPropDropMsgAfterSeconds:(NSTimeInterval)seconds{
    //if( seconds>0){
        [self.containerDropMsgTimer setDelay:seconds];
    [self.containerDropMsgTimer delayToDeadline];
    //}
}
-(void) setPropDropMsgOnDate:(NSDate *)date{
     [self.containerDropMsgTimer setDueDate:date];
    //}
}
-(void) setPropKickoutOnDate:(NSDate *)date{
    //if( date){
        [self.containerKickoutTimer setDueDate:date];
    //}
}
-(void) setPropDeleteOnDate:(NSDate *)date{
    [self.containerDeleteTimer setDueDate:date];
}

-(BOOL) passedDeletionDate:(NSDate *)date{
    if(date){
        return [self.containerDeleteTimer isConditionMetAfterDateValue:date data:nil];
    }
    return NO;
}
-(BOOL) passedKickoutDate:(NSDate *)date{
    if(date){
        return [self.containerKickoutTimer isConditionMetAfterDateValue:date data:nil];
    }
    return NO;
}
-(BOOL) passedDropMsgDate:(NSDate *)date{
    if(date){
        return [self.containerDropMsgTimer isConditionMetAfterDateValue:date data:nil];
    }
    return NO;
}
@end
#pragma mark - NULL
@implementation ASFKMBPropertiesNull
-(id)init{
    self=[super init];
    return self;
}

@end
//@implementation ASFKMBBlockableMsgProperties
//-(id) init{
//    self=[super init];
//    if(self){
//        _msgReleaseTimer=[ASFKConditionTemporal new];
//        _conditionCallRelease=nil;
//        _callRelease=nil;;
//    }
//    return self;
//}
//-(void) setPropReleaseTimer:(ASFKConditionTemporal*)condition{
//    _msgReleaseTimer=condition;
//}
//-(void) setPropCallRelease:(ASFKConditionCallRelease*)condition{
//    _conditionCallRelease=condition;
//}
//-(void) setPropCallReleaseRoutine:(ASFKMbCallReleaseRoutine)routine{
//    _callRelease=routine;
//}
//-(void) wait{
//    
//}
//-(void) signal{
//    
//}
//@end

