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
//  ASFKAuthorizationMgr.m
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//
#import "ASFKBase.h"
#import "ASFKAuthorizationMgr.h"

@implementation ASFKAuthorizationMgr
ASFKMasterSecret* masterSecretBack;
-(id)init{
    self=[super init];
    if(self){
        _masterSecret=nil;
        masterSecretBack=nil;
        secretProcPop=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesPopperSecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
        };
        secretProcUnicast=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesUnicasterSecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
        };
        secretProcMulticast=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesMulticasterSecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
        };
        secretProcBroadcast=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesBroadcasterSecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
        };
        secretProcRead=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesReaderSecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
        };
        secretProcDiscard=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesDiscarderSecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
        };
        secretProcCreate=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesCreatorSecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
        };
        secretProcHost=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesHostSecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
        };
        secretProcConfig=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesConfigSecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
        };
        secretProcSecurity=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesSecuritySecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
            
        };
        secretProcIssuer=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesIssuerSecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
            
        };
        secretProcModerate=^BOOL(ASFKSecret* sec0,ASFKSecret* sec1){
            if(sec0 && sec1){
                return [sec1 matchesModeratorSecret:sec0];
            }
            else if(sec0 || sec1){
                return NO;
            }
            else{
                return YES;
            }
        };

    }
    return self;
}
-(BOOL) setMasterSecret:(ASFKMasterSecret*)oldsec newSecret:(ASFKMasterSecret*)newsec{
    if(oldsec==nil && _masterSecret==nil){
        DASFKLog(@"Attempting reset of master secret");
        if(newsec!=nil){
            //test validity of new secret
            if([newsec validSecretSecurity]){
                _masterSecret=newsec;
                masterSecretBack=nil;

                DASFKLog(@"DONE");
                return YES;
            }
            return NO;
        }
        else{

            _masterSecret=newsec;
            masterSecretBack=nil;

            return YES;
        }
    }
    else if(_masterSecret!=nil && oldsec!=nil){
        //test old secret validity
        if([_masterSecret validSecretSecurity] &&
           [oldsec validSecretSecurity] &&
           [self isMasterSecretValid:oldsec matcher:secretProcSecurity]){
            if(newsec!=nil){
                if([newsec validSecretSecurity]){

                    [_masterSecret invalidateAll];
                    _masterSecret=newsec;
                    masterSecretBack=nil;

                    DASFKLog(@"DONE");
                    return YES;
                }
                return NO;
            }
            else{

                [_masterSecret invalidateAll];
                _masterSecret=newsec;

                DASFKLog(@"DONE");
                return YES;
            }
        }
        return NO;
    }
    WASFKLog(@"FAILED");
    return NO;
}
-(BOOL) setFloatingSecret:(ASFKFloatingSecret*)newsec authorizeWith:(ASFKMasterSecret*) msec{
    BOOL mastersecValid=NO;
    if(_masterSecret == nil && msec == nil){
        mastersecValid=YES;
    }
//    else if(_masterSecret != nil && msec == nil){
//        
//    }
//    else if(_masterSecret == nil && msec != nil){
//        
//    }
    else if(_masterSecret != nil && msec != nil){
        mastersecValid=[_masterSecret validSecretSecurity];
        mastersecValid &= [msec validSecretSecurity];
        mastersecValid &= [self isMasterSecretValid:msec matcher:self->secretProcSecurity];
        
    }
//    if(_masterSecret ){
//        
//        if(msec){
//            
//        }
//        else{
//            
//        }
//    }
//    else if(msec==nil){
//        mastersecValid=YES;
//    }
    
    if(mastersecValid){
        if(_floatingSecret==nil && newsec==nil){
            DASFKLog(@"DONE");
            return YES;
        }
        else if(_floatingSecret!=nil && newsec!=nil ){
            if([_floatingSecret validCharacteristic] && [newsec validCharacteristic]){
                _floatingSecret=newsec;
                DASFKLog(@"DONE");
                return YES;
            }
        }
        else if(_floatingSecret!=nil && newsec==nil){
            if([_floatingSecret validCharacteristic] ){
                _floatingSecret=newsec;
                DASFKLog(@"DONE");
                return YES;
            }
        }
        else if(_floatingSecret==nil && newsec!=nil){
            if([newsec validCharacteristic] ){
                _floatingSecret=newsec;
                DASFKLog(@"DONE");
                return YES;
            }

        }
    }
    
    WASFKLog(@"FAILED");
    return NO;
}
-(BOOL) matchCreatorSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcCreate(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}
-(BOOL) matchDiscarderSecret:(ASFKSecret*)secCurrent with:(ASFKSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcDiscard(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}
-(BOOL) matchReaderSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcRead(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}
-(BOOL) matchPopperSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcPop(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}

-(BOOL) matchHostSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcHost(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}
-(BOOL) matchSecuritySecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcSecurity(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}
-(BOOL) matchUnicasterSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcUnicast(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}
-(BOOL) matchMulticasterSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcMulticast(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}
-(BOOL) matchBroadcasterSecret:(ASFKFloatingSecret*)secCurrent with:(ASFKFloatingSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcBroadcast(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}
-(BOOL) matchConfigSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcConfig(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}
-(BOOL) matchModeratorSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcModerate(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}
-(BOOL) matchIssuerSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcIssuer(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}

-(BOOL) isMasterSecretValid:(ASFKMasterSecret*)msecret matcher:(ASFKSecretComparisonProc)match{
    if(_masterSecret && msecret){
        BOOL r1=match(_masterSecret,msecret);
        return r1;
    }else if(_masterSecret==nil && msecret==nil){
        return YES;
    }
    return NO;
}
-(BOOL) isFloatingSecretValid:(ASFKFloatingSecret*)fsecret matcher:(ASFKSecretComparisonProc)match{
    if(_floatingSecret && fsecret){
        BOOL r1=match(_floatingSecret,fsecret);
        return r1;
    }else if(_floatingSecret==nil && fsecret==nil){
        return YES;
    }
    return NO;
}
@end
