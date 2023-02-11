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
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//
#import "ASFKBase.h"

#include <atomic>
@interface ASFK_PrivSecretItem:NSObject{
    @public std::atomic<BOOL> secretSet;
    @public std::atomic<BOOL> secretValid;
    @public std::atomic<BOOL> secretCmpSet;
    @public ASFKSecretComparisonProc secretCmpProc;
}
-(BOOL) matchSecretHost:(id)sH secretGuest:(id)sG usageCount:(std::atomic<NSInteger>&)ucnt;
@end
@implementation ASFK_PrivSecretItem{

}
-(id) init{
    self = [super init];
    if(self){
        secretSet=NO;
        secretValid=YES;
        secretCmpSet=NO;;
        secretCmpProc=nil;
    }
    return self;;
}
-(BOOL) matchSecretHost:(id)sH secretGuest:(id)sG usageCount:(std::atomic<NSInteger>&)ucnt{
    if(!secretValid){
        return NO;
    }
    if((sG==nil && sH!=nil)||(sG!=nil && sH==nil))
    {
        return NO;
    }
    if(sG && sH){
        BOOL r=NO;
        if(secretCmpProc){
            r=secretCmpProc(sH,sG);
        }
        else{
            r=[sH isEqualTo:sG];
        }
        ucnt.fetch_sub(1);
        return r;
    }
    if(!sH && !sG){
        return YES;
    }
    return NO;
}
@end

@interface ASFKSecret ()
@end
@implementation ASFKSecret{
    std::atomic<BOOL> secretExpirationSet;
    
    std::atomic<NSInteger> itsUsageCount;
    std::atomic<BOOL> secretMaxUsageSet;
    
    ASFK_PrivSecretItem* psiModerator;
    ASFK_PrivSecretItem* psiMulticaster;
    ASFK_PrivSecretItem* psiBroadcaster;
    ASFK_PrivSecretItem* psiUnicaster;
    ASFK_PrivSecretItem* psiReader;
    ASFK_PrivSecretItem* psiPopper;
    ASFK_PrivSecretItem* psiDiscarder;
    ASFK_PrivSecretItem* psiCreator;
    ASFK_PrivSecretItem* psiHost;
    ASFK_PrivSecretItem* psiSecurity;
    ASFK_PrivSecretItem* psiConfig;
    ASFK_PrivSecretItem* psiIssuer;

}

-(id) init{
    self=[super init];
    if(self){
        secretExpirationSet=NO;
        _timerExpiration=[ASFKConditionTemporal new];
        
        secretMaxUsageSet=NO;
        itsUsageCount=INTMAX_MAX;
        
        psiSecurity=[ASFK_PrivSecretItem new];
        psiConfig=[ASFK_PrivSecretItem new];
        psiUnicaster=[ASFK_PrivSecretItem new];
        psiMulticaster=[ASFK_PrivSecretItem new];
        psiBroadcaster=[ASFK_PrivSecretItem new];
        psiReader=[ASFK_PrivSecretItem new];
        psiPopper=[ASFK_PrivSecretItem new];
        psiCreator=[ASFK_PrivSecretItem new];
        psiDiscarder=[ASFK_PrivSecretItem new];
        psiHost=[ASFK_PrivSecretItem new];
        psiModerator=[ASFK_PrivSecretItem new];;
        psiIssuer=[ASFK_PrivSecretItem new];
        
    }
    return self;
}

-(BOOL) setUnicasterSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiUnicaster->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiUnicaster->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setMulticasterSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiMulticaster->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiMulticaster->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setBroadcasterSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiBroadcaster->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiBroadcaster->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setCreatorSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiCreator->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiCreator->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setReaderSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiReader->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiReader->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setPopperSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiPopper->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiPopper->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setDiscarderSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiDiscarder->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiDiscarder->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setHostSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiHost->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiHost->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setSecuritySecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiSecurity->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiSecurity->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setConfigSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiConfig->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiConfig->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setModeratorSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiModerator->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiModerator->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setIssuerSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    if(cmpproc==nil){
        return NO;
    }
    BOOL tval=NO;
    if(psiIssuer->secretCmpSet.compare_exchange_strong(tval,YES))
    {
        psiIssuer->secretCmpProc=cmpproc;
        return YES;
    }
    return NO;
}
-(BOOL) setMaxUsageCountOnce:(NSInteger)maxCount{
    BOOL tval=NO;
    if(maxCount>0 && secretMaxUsageSet.compare_exchange_strong(tval,YES))
    {
        itsUsageCount=maxCount;
        return YES;
    }
    
    DASFKLog(@"ASFKMBSecret: base class called");
    return NO;
}
-(BOOL) passedMaxUsageCount{
    if(itsUsageCount<1){
        return YES;
    }
    return NO;
}
-(BOOL) passedExpirationDeadline:(NSDate*)deadline{
    if(deadline){
        return [_timerExpiration isConditionMetAfterDateValue:deadline data:nil];
    }
    return NO;
}
-(BOOL) setExpirationDateOnce:(NSDate*)aDate{
    BOOL tval=NO;
    if(secretExpirationSet.compare_exchange_strong(tval,YES))
    {
        [_timerExpiration setDueDate:aDate];
        return YES;
    }
    
    DASFKLog(@"ASFKMBSecret: base class called");
    return NO;
    
}
-(BOOL) setExpirationDelayOnce:(NSTimeInterval) sec{
    BOOL tval=NO;
    if(secretExpirationSet.compare_exchange_strong(tval,YES))
    {
        [_timerExpiration setDelay:sec];
        [_timerExpiration delayToDeadline];
        return YES;
    }
    DASFKLog(@"ASFKMBSecret: base class called");
    return NO;
}
#pragma mark - matchers
-(BOOL) matchesUnicasterSecret:(ASFKSecret*)secret{
    if(!psiUnicaster->secretValid || secret==nil){
        return NO;
    }
    
    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidateUnicasterSecret];
        return NO;
    }
    return [psiUnicaster matchSecretHost:_secretUnicaster secretGuest:secret->_secretUnicaster usageCount:itsUsageCount];
}
-(BOOL) matchesMulticasterSecret:(ASFKSecret*)secret{
    if(!psiMulticaster->secretValid || secret==nil){
        return NO;
    }
    
    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidateMulticasterSecret];
        return NO;
    }
    return [psiMulticaster matchSecretHost:_secretMulticaster secretGuest:secret->_secretMulticaster usageCount:itsUsageCount];
}
-(BOOL) matchesBroadcasterSecret:(ASFKSecret*)secret{
    if(!psiBroadcaster->secretValid || secret==nil){
        return NO;
    }
    
    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidateBroadcasterSecret];
        return NO;
    }
    return [psiBroadcaster matchSecretHost:_secretBroadcaster secretGuest:secret->_secretBroadcaster usageCount:itsUsageCount];
}
-(BOOL) matchesSecuritySecret:(ASFKSecret*)secret{
    if(!psiSecurity->secretValid || secret==nil){
        return NO;
    }
    
    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidateSecuritySecret];
        return NO;
    }
    return [psiSecurity matchSecretHost:_secretSecurity secretGuest:secret->_secretSecurity usageCount:itsUsageCount];
}
-(BOOL) matchesConfigSecret:(ASFKSecret*)secret{
    if(!psiConfig->secretValid || secret==nil){
        return NO;
    }
    
    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidateConfigSecret];
        return NO;
    }
    return [psiConfig matchSecretHost:_secretConfigurer secretGuest:secret->_secretConfigurer usageCount:itsUsageCount];
}

-(BOOL) matchesReaderSecret:(ASFKSecret*)secret{
    if(!psiReader->secretValid || secret==nil){
        return NO;
    }

    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidateReaderSecret];
        return NO;
    }

    return [psiReader matchSecretHost:_secretReader secretGuest:secret->_secretReader usageCount:itsUsageCount];
}
-(BOOL) matchesPopperSecret:(ASFKSecret*)secret{
    if(!psiPopper->secretValid || secret==nil){
        return NO;
    }
        
    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidatePopperSecret];
        return NO;
    }
    return [psiPopper matchSecretHost:_secretPopper secretGuest:secret->_secretPopper usageCount:itsUsageCount];
}
-(BOOL) matchesDiscarderSecret:(ASFKSecret*)secret{
    if(!psiDiscarder->secretValid || secret==nil){
        return NO;
    }
    
    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidateDiscarderSecret];
        return NO;
    }
    return [psiDiscarder matchSecretHost:_secretDiscarder secretGuest:secret->_secretDiscarder usageCount:itsUsageCount];
}
-(BOOL) matchesCreatorSecret:(ASFKSecret*)secret{
    if(!psiCreator->secretValid || secret==nil){
        return NO;
    }
    
    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidateCreatorSecret];
        return NO;
    }
    return [psiCreator matchSecretHost:_secretCreator secretGuest:secret->_secretCreator usageCount:itsUsageCount];
}
-(BOOL) matchesHostSecret:(ASFKSecret*)secret{
    if(!psiHost->secretValid || secret==nil){
        return NO;
    }
    
    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidateHostSecret];
        return NO;
    }
    return [psiHost matchSecretHost:_secretHost secretGuest:secret->_secretHost usageCount:itsUsageCount];
}
-(BOOL) matchesIssuerSecret:(ASFKSecret*)secret{
    if(!psiIssuer->secretValid || secret==nil){
        return NO;
    }
    
    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidateIssuerSecret];
        return NO;
    }
    return [psiIssuer matchSecretHost:_secretIssuer secretGuest:secret->_secretIssuer usageCount:itsUsageCount];
}
-(BOOL) matchesModeratorSecret:(ASFKSecret*)secret{
    if(!psiModerator->secretValid || secret==nil){
        return NO;
    }
    if([self passedExpirationDeadline:[NSDate date]] || itsUsageCount<1){
        [self invalidateModeratorSecret];
        return NO;
    }
    
    return [psiModerator matchSecretHost:_secretModerator secretGuest:secret->_secretModerator usageCount:itsUsageCount];
    
}
#pragma mark - secret setting

-(BOOL) setUnicasterSecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiUnicaster->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretUnicaster=secret;
        DASFKLog(@"ASFKMBSecret: base class called");
        return YES;
        
    }
    return NO;
}
-(BOOL) setMulticasterSecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiMulticaster->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretMulticaster=secret;
        DASFKLog(@"ASFKMBSecret: base class called");
        return YES;
        
    }
    return NO;
}
-(BOOL) setBroadcasterSecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiBroadcaster->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretBroadcaster=secret;
        DASFKLog(@"ASFKMBSecret: base class called");
        return YES;
        
    }
    return NO;
}
-(BOOL) setReaderSecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiReader->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretReader=secret;
        DASFKLog(@"ASFKMBSecret: base class called");
        return YES;
    }
    return NO;
}
-(BOOL) setPopperSecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiPopper->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretPopper=secret;
        DASFKLog(@"ASFKMBSecret: base class called");
        return YES;
    }
    return NO;
}
-(BOOL) setDiscarderSecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiDiscarder->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretDiscarder=secret;
        DASFKLog(@"ASFKMBSecret: base class called");
        return YES;
    }
    return NO;
}
-(BOOL) setCreatorSecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiCreator->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretCreator=secret;
        DASFKLog(@"ASFKMBSecret: base class called");
        return YES;
        
    }
    return NO;
}
-(BOOL) setHostSecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiHost->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretHost=secret;
        DASFKLog(@"ASFKMBSecret: class called");
        return YES;
        
    }
    return NO;
}
-(BOOL) setSecuritySecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiSecurity->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretSecurity=secret;
        DASFKLog(@"ASFKMBSecret: class called");
        return YES;
        
    }
    return NO;
}
-(BOOL) setConfigSecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiConfig->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretConfigurer=secret;
        DASFKLog(@"ASFKMBSecret: class called");
        return YES;
        
    }
    return NO;
}
-(BOOL) setModeratorSecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiModerator->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretModerator=secret;
        DASFKLog(@"ASFKMBSecret: base class called");
        return YES;
        
    }
    return NO;
}
-(BOOL) setIssuerSecretOnce:(id)secret{
    BOOL tval=NO;
    if(psiIssuer->secretSet.compare_exchange_strong(tval,YES))
    {
        _secretIssuer=secret;
        DASFKLog(@"ASFKMBSecret: class called");
        return YES;
        
    }
    return NO;
}
#pragma mark - Invalidation

-(void) invalidateUnicasterSecret{
    psiUnicaster->secretValid=NO;
}
-(void) invalidateMulticasterSecret{
    psiMulticaster->secretValid=NO;
}
-(void) invalidateBroadcasterSecret{
    psiBroadcaster->secretValid=NO;
}
-(void) invalidateReaderSecret{
    psiReader->secretValid=NO;
}
-(void) invalidatePopperSecret{
    psiPopper->secretValid=NO;
}
-(void) invalidateDiscarderSecret{
    psiDiscarder->secretValid=NO;
}
-(void) invalidateCreatorSecret{
    psiCreator->secretValid=NO;
}
-(void) invalidateConfigSecret{
    psiConfig->secretValid=NO;
}
-(void) invalidateSecuritySecret{
    psiSecurity->secretValid=NO;
}
-(void) invalidateHostSecret{
    psiHost->secretValid=NO;
}
-(void) invalidateIssuerSecret{
    psiIssuer->secretValid=NO;
}
-(void) invalidateModeratorSecret{
    psiModerator->secretValid=NO;
}

#pragma mark - Validity

-(BOOL) validSecretCreator{
    return psiCreator->secretValid;
}
-(BOOL) validSecretDiscarder{
    return psiDiscarder->secretValid;
}
-(BOOL) validSecretUnicaster{
    return psiUnicaster->secretValid;
}
-(BOOL) validSecretMulticaster{
    return psiMulticaster->secretValid;
}
-(BOOL) validSecretBroadcaster{
    return psiBroadcaster->secretValid;
}
-(BOOL) validSecretPopper{
    return psiPopper->secretValid;
}
-(BOOL) validSecretReader{
    return psiReader->secretValid;
}
-(BOOL) validSecretSecurity{
    return psiSecurity->secretValid;
}
-(BOOL) validSecretHost{
    return psiHost->secretValid;
}
-(BOOL) validSecretConfig{
    return psiConfig->secretValid;
}
-(BOOL) validSecretIssuer{
    return psiIssuer->secretValid;
}
-(BOOL) validSecretModerator{
    return psiModerator->secretValid;
}
-(void) invalidateAll{
    [self invalidateUnicasterSecret];
    [self invalidateMulticasterSecret];
    [self invalidateBroadcasterSecret];
    [self invalidateReaderSecret];
    [self invalidatePopperSecret];
    [self invalidateDiscarderSecret];
    [self invalidateCreatorSecret];
    [self invalidateHostSecret];
    [self invalidateConfigSecret];
    [self invalidateSecuritySecret];
    [self invalidateModeratorSecret];
    [self invalidateIssuerSecret];
}
-(BOOL) isValidOnDate:(NSDate*)aDate{
    return (![self passedExpirationDeadline:aDate]);
}
-(BOOL) validAll{
    return (psiCreator->secretValid     &&
            psiUnicaster->secretValid   &&
            psiMulticaster->secretValid &&
            psiBroadcaster->secretValid &&
            psiReader->secretValid      &&
            psiPopper->secretValid      &&
            psiDiscarder->secretValid   &&
            psiHost->secretValid        &&
            psiSecurity->secretValid    &&
            psiConfig->secretValid      &&
            psiModerator->secretValid   &&
            psiIssuer->secretValid
            );
}
-(BOOL) validAny{
    return (psiCreator->secretValid     ||
            psiUnicaster->secretValid   ||
            psiMulticaster->secretValid ||
            psiBroadcaster->secretValid ||
            psiReader->secretValid      ||
            psiPopper->secretValid      ||
            psiDiscarder->secretValid   ||
            psiHost->secretValid        ||
            psiSecurity->secretValid    ||
            psiConfig->secretValid      ||
            psiModerator->secretValid   ||
            psiIssuer->secretValid
            );
}
-(BOOL) validCharacteristic{
    return [self validAll];
}
@end

@implementation ASFKMasterSecret
-(id)init{
    self=[super init];
    if(self){
        [self invalidateReaderSecret];
        [self invalidatePopperSecret];
        [self invalidateModeratorSecret];
        [self invalidateHostSecret];
        [self invalidateConfigSecret];
        [self invalidateIssuerSecret];
        [self invalidateCreatorSecret];
    }
    return self;
}
-(BOOL) validCharacteristic{
    return (
            [self validSecretUnicaster]
            && [self validSecretMulticaster]
            && [self validSecretDiscarder]
            && [self validSecretSecurity]
            );
}

-(BOOL) setCreatorSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesCreatorSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setCreatorSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
-(BOOL) setModeratorSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesModeratorSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setModeratorSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
-(BOOL) setReaderSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesReaderSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setReaderSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
-(BOOL) setPopperSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesPopperSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setPopperSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
-(BOOL) setHostSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesHostSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setHostSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
-(BOOL) setConfigSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesConfigSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setConfigSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
-(BOOL) setIssuerSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesIssuerSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setIssuerSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
@end

@implementation ASFKPrivateSecret
-(id)init{
    self=[super init];
    if(self){

    }
    return self;
}
-(BOOL) validCharacteristic{
    return (
            [self validSecretReader]
            && [self validSecretUnicaster]
            && [self validSecretMulticaster]
            && [self validSecretPopper]
            && [self validSecretDiscarder]
            && [self validSecretSecurity]
            && [self validSecretHost]
            && [self validSecretModerator]
            && [self validSecretCreator]
            && [self validSecretIssuer]
            && [self validSecretConfig]
            );
}

@end

@implementation ASFKGroupSecret
-(id)init{
    self=[super init];
    if(self){
        [self invalidateSecuritySecret];
        [self invalidateConfigSecret];
        [self invalidateDiscarderSecret];
        [self invalidateCreatorSecret];
    }
    return self;
}
-(BOOL) validCharacteristic{
    return (
            [self validSecretReader]
            && [self validSecretMulticaster]
            && [self validSecretBroadcaster]
            && [self validSecretUnicaster]
            && [self validSecretPopper]
            && [self validSecretHost]
            && [self validSecretModerator]
            && [self validSecretIssuer]
            );
}

-(BOOL) setDiscarderSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesDiscarderSecret:(ASFKSecret *)secret{
    return NO;
}
-(BOOL) setDiscarderSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
-(BOOL) setSecuritySecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesSecuritySecret:(ASFKSecret *)secret{
    return NO;
}
-(BOOL) setSecuritySecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
-(BOOL) setConfigSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesConfigSecret:(ASFKSecret *)secret{
    return NO;
}
-(BOOL) setConfigSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
-(BOOL) setCreatorSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesCreatorSecret:(ASFKSecret *)secret{
    return NO;
}
-(BOOL) setCreatorSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
@end
@implementation ASFKFloatingSecret
-(id)init{
    self=[super init];
    if(self){
        [self invalidateSecuritySecret];
        [self invalidateConfigSecret];
        [self invalidateDiscarderSecret];
        [self invalidateCreatorSecret];
        [self invalidateHostSecret];
        [self invalidateIssuerSecret];
        [self invalidatePopperSecret];
        [self invalidateReaderSecret];
        [self invalidateModeratorSecret];
        [self invalidateUnicasterSecret];
        [self invalidateMulticasterSecret];
    }
    return self;
}
-(BOOL) validCharacteristic{
    return [self validSecretBroadcaster];
}

-(BOOL) setDiscarderSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesDiscarderSecret:(ASFKSecret *)secret{
    return NO;
}
-(BOOL) setDiscarderSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}

-(BOOL) setSecuritySecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesSecuritySecret:(ASFKSecret *)secret{
    return NO;
}
-(BOOL) setSecuritySecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}

-(BOOL) setConfigSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesConfigSecret:(ASFKSecret *)secret{
    return NO;
}
-(BOOL) setConfigSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}

-(BOOL) setCreatorSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesCreatorSecret:(ASFKSecret *)secret{
    return NO;
}
-(BOOL) setCreatorSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}

-(BOOL) setReaderSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesReaderSecret:(ASFKSecret *)secret{
    return NO;
}
-(BOOL) setReaderSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}

-(BOOL) setIssuerSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesIssuerSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setIssuerSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}

-(BOOL) setPopperSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesPopperSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setPopperSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}

-(BOOL) setUnicasterSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesUnicasterSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setUnicasterSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}

-(BOOL) setMulticasterSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesMulticasterSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setMulticasterSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}

-(BOOL) setModeratorSecretOnce:(id)secret{
    return NO;
}
-(BOOL) matchesModeratorSecret:(ASFKSecret*)secret{
    return NO;
}
-(BOOL) setModeratorSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc{
    return NO;
}
@end
