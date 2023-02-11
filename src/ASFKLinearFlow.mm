//
//  ASFKLinearFlow.m
//  Async
//
//  Created by bv on 19/10/2022.
//  Copyright © 2022 bv. All rights reserved.
//

#import "ASFKBase.h"

@implementation ASFKLinearFlow
{}

-(id)init{
    self=[super init];
    if(self){
        [self _initLF];
    }
    return self;
}
-(id)initWithName:(NSString*)name{
    self=[super initWithName:name];
    if(self){
        [self _initLF];
    }
    return self;
}
-(void) _initLF {

}
#pragma mark - Asynchronous API
-(BOOL) castArray:(NSArray*)array exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}

-(BOOL) castDictionary:(NSDictionary*)dictionary exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}


-(BOOL) castOrderedSet:(NSOrderedSet*)set exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}

-(BOOL) castArray:(NSArray*)array groupBy:(NSUInteger) grpSize exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}
-(BOOL) castArray:(NSArray*)array splitTo:(NSUInteger) numOfChunks exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}
-(BOOL) castUnorderedSet:(NSSet*)set exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}


-(BOOL) castObject:(id)uns exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}

#pragma mark - Synchronous API
-(BOOL) callArray:(NSArray*)array exParams:(ASFKExecutionParams*)params{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}
-(BOOL) callArray:(NSArray*)array groupBy:(NSUInteger) grpSize exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}
-(BOOL) callArray:(NSArray*)array splitTo:(NSUInteger) numOfChunks exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}

-(BOOL) callDictionary:(NSDictionary*)dictionary exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}


-(BOOL) callOrderedSet:(NSOrderedSet*)set exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}


-(BOOL) callUnorderedSet:(NSSet*)set exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}


-(BOOL) callObject:(id)uns exParams:(ASFKExecutionParams*)ex{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return NO;
}


-(id) pull{
    EASFKLog(ASFK_STR_WRONG_METHOD_CALL);
    return nil;
}

@end
