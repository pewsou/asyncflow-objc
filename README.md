# Asynchronous Flow Kit
This is an attempt to build Objective-C framework for asynchronous (concurrent) programming. 

# Why?
*Concurrent programming is complex. Let's make it easier.*

The motivation is to provide robust toolkit with which one could design (concurrent) execution flow without caring too much about concurrency-related issues. Inspired by Caolan's Async package.

# Architecture
The Kit is built as a collection of independent objects each of which represents some concurrency pattern.
The API provides consistent set of operations while the set is split to 2 groups: one for linear concurrent/asynchronous execution, other for conditional execution (will be available in future).

# Semantics
In the course of this SW package next terms defined:
1. *Procedure/Routine/Code Block* - this is routine provided by caller ("block" in terms of Obj-C) that only supposed to process data fed by set of arguments.
2. *Summary* - a routine provided by caller; it is called when data processing session is done. It receives execution results as parameter.
3. Method *"callXXX"* - **blocking** method; it will always return only AFTER all the procedures that have started by this call also have ended and summary was called (if exists).
3. Method *"castXXX"* - **non-blocking** method; it will always return without waiting for ending of procedures.
4. Method *"storeXXX/addXXX"* - adds the items (usually procedures) to the instance of the object so any future invocation of *cast/call* will involve the new definitions.
5. Method *"replaceXXX"* - replaces the stored items in the instance of the object with new collection (probably empty one) so any future invocation of *cast/call* will involve the new definitions.
6. *Session* - Independent set of routines, ready for data processing. Each session has unique ID.

# Available Concurrency/Asynchronity Patterns
1. *Pipeline* - multiple data, multiple routines. Proc1 is applied to item 1, result passed to Proc2, while Proc1 starts working on item 2 and so on. New data items can be submitted anytime. The execution is transparently performed using internal threadpool, while executing threads mapped, onto available CPUs providing by this some degree of parallelization.
2. *Mailbox* - An alternative to Botifications mechanism; a FIFO container owned by some user; one can write messages into it, while the owner may read them later. Almost every operation requires application of some secret, that approves invoker's eligibility. Mailbox can be standalone and only the owner may read messages; or it can allow some group of other users to read. Also container may be configured for self-destruction; same about messages. Broadcast/multicast operations supported. 

For more details please see Wiki.

# Compatibility
Tested with OSX 10.12



Contact by email: rainbowsup191+ASFK@gmail.com
Discord: https://discord.com/channels/1057957242810400828/1057957242810400831
