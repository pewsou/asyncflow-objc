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
//  Copyright © 2019-2022 Boris Vigman. All rights reserved.
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
                ASFKLog(@"DONE");
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
                    ASFKLog(@"DONE");
                    return YES;
                }
                return NO;
            }
            else{
                [_masterSecret invalidateAll];
                _masterSecret=newsec;
                ASFKLog(@"DONE");
                return YES;
            }
        }
        return NO;
    }
    ASFKLog(@"FAILED");
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

-(BOOL) matchConfigSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther{
    if(secCurrent && secOther){
        BOOL r1=secretProcConfig(secCurrent,secOther);
        return r1;
    }else if(secCurrent==nil && secOther==nil){
        return YES;
    }
    return NO;
}
#pragma mark - Private methods
-(BOOL) isMasterSecretValid:(ASFKMasterSecret*)msecret matcher:(ASFKSecretComparisonProc)match{
    if(_masterSecret && msecret){
        BOOL r1=match(_masterSecret,msecret);
        return r1;
    }else if(_masterSecret==nil && msecret==nil){
        return YES;
    }
    return NO;
}
@end
