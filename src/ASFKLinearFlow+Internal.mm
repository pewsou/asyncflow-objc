//
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

#import "ASFKLinearFlow+Internal.h"

@implementation ASFKLinearFlow (Internal)
-(ASFKParamSet*) _convertInputDictionary:(NSDictionary*) input to:(ASFKParamSet*)ps{
    if(input){
        ps.input=input;
    }else{
        ps.input=nil;
    }
    return ps;
}
-(ASFKParamSet*) _convertInputArray:(NSArray*) input to:(ASFKParamSet*)ps{
    if(input){
        ps.input=input;
    }else{
        ps.input=nil;
    }
    return ps;
}
-(ASFKParamSet*) _convertInputOrderedSet:(NSOrderedSet*) input to:(ASFKParamSet*)ps{
    if(input){
        ps.input=input;
    }else{
        ps.input=nil;
    }
    return ps;
}
-(ASFKParamSet*) _convertInputUnorderedSet:(NSSet*) input to:(ASFKParamSet*)ps{
    if(input){
        ps.input=input;
    }else{
        ps.input=nil;
    }
    return ps;
}

-(ASFKParamSet*) _convertInput:(id) input to:(ASFKParamSet*)ps{
    if(input){
            ps.input=@[input];
    }else{
        ps.input=nil;
    }
    return ps;
}
@end

@implementation ASFKParamSet
-(id) init{
    self=[super init];
    if(self){
        self.procs=nil;
        self.summary=nil;
        self.cancProc=nil;
        self.input=nil;
        self.excond=nil;
        self.hasForeignProcs=NO;
        //self.customSessionId=nil;
        self.sessionId=nil;
    }
    return self;
}

@end
