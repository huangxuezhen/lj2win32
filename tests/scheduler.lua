--[[
	This is a pure lua scheduler.  It is used
	to coordinate multiple lua coroutines.

	require("scheduler")

	It will automatically polute your global
	namespace with new keywords:
	Kernel
	halt, run, coop, spawn, suspend, yield
	onSignal, signalAll, signalAllImmediate, signalOne, waitForSignal

	With this base of spawning, and signaling, fairly complex
	cooperative multi-tasking can be constructed.
]]
local floor = math.floor;
local insert = table.insert;

local function fcomp_default( a,b ) 
   return a < b 
end

local function getIndex(t, value, fcomp)
   local fcomp = fcomp or fcomp_default

   local iStart = 1;
   local iEnd = #t;
   local iMid = 1;
   local iState = 0;

   while iStart <= iEnd do
      -- calculate middle
      iMid = floor( (iStart+iEnd)/2 );
      
      -- compare
      if fcomp( value,t[iMid] ) then
            iEnd = iMid - 1;
            iState = 0;
      else
            iStart = iMid + 1;
            iState = 1;
      end
   end

   return (iMid+iState);
end

local function binsert(tbl, value, fcomp)
   local idx = getIndex(tbl, value, fcomp);
   insert( tbl, idx, value);
   
   return idx;
end

--[[
Queue

The Queue is a simple data structure that represents a 
first in first out behavior.
--]]

local Queue = {}
setmetatable(Queue, {
	__call = function(self, ...)
		return self:create(...);
	end,
});

local Queue_mt = {
	__index = Queue;
}

function Queue.init(self, first, last, name)
	first = first or 1;
	last = last or 0;

	local obj = {
		first=first, 
		last=last, 
		name=name};

	setmetatable(obj, Queue_mt);

	return obj
end

function Queue.create(self, first, last, name)
	first = first or 1
	last = last or 0

	return self:init(first, last, name);
end

function Queue:pushFront(value)
	-- PushLeft
	local first = self.first - 1;
	self.first = first;
	self[first] = value;
end

function Queue:pinsert(value, fcomp)
	binsert(self, value, fcomp)
	self.last = self.last + 1;
end

function Queue:enqueue(value)
	--self.MyList:PushRight(value)
	local last = self.last + 1
	self.last = last
	self[last] = value

	return value
end

function Queue:dequeue(value)
	-- return self.MyList:PopLeft()
	local first = self.first

	if first > self.last then
		return nil, "list is empty"
	end
	
	local value = self[first]
	self[first] = nil        -- to allow garbage collection
	self.first = first + 1

	return value	
end

function Queue:length()
	return self.last - self.first+1
end

-- Returns an iterator over all the current 
-- values in the queue
function Queue:Entries(func, param)
	local starting = self.first-1;
	local len = self:length();

	local closure = function()
		starting = starting + 1;
		return self[starting];
	end

	return closure;
end

--[[
	Task, contains stuff related to encapsulated code
--]]
local Task = {}

setmetatable(Task, {
	__call = function(self, ...)
		return self:create(...);
	end,
});

local Task_mt = {
	__index = Task,
}

function Task.init(self, aroutine, ...)

	local obj = {
		routine = coroutine.create(aroutine), 
	}
	setmetatable(obj, Task_mt);
	
	obj:setParams({...});

	return obj
end

function Task.create(self, aroutine, ...)
	-- The 'aroutine' should be something that is callable
	-- either a function, or a table with a meta '__call'
	-- implementation.  Checking with type == 'function'
	-- is not good enough as it will miss the meta __call cases

	return self:init(aroutine, ...)
end


function Task.getStatus(self)
	return coroutine.status(self.routine);
end

-- A function that can be used as a predicate
function Task.isFinished(self)
	return task:getStatus() == "dead"
end


function Task.setParams(self, params)
	self.params = params

	return self;
end

function Task.resume(self)
--print("Task, RESUMING: ", unpack(self.params));
	return coroutine.resume(self.routine, unpack(self.params));
end

local Scheduler = {}
setmetatable(Scheduler, {
	__call = function(self, ...)
		return self:create(...)
	end,
})
local Scheduler_mt = {
	__index = Scheduler,
}

function Scheduler.init(self, ...)
	local obj = {
		TasksReadyToRun = Queue();
	}
	setmetatable(obj, Scheduler_mt)
	
	return obj;
end

function Scheduler.create(self, ...)
	return self:init(...)
end

--[[
	tasksPending

	A simple method to let anyone know how many tasks are currently
	on the ready to run list.

	This might be useful when you're running some predicate logic based 
	on how many tasks there are.
--]]
function Scheduler.tasksPending(self)
	return self.TasksReadyToRun:length();
end

-- put a task on the ready list
-- the 'task' should be something that can be executed,
-- whether it's a function, functor, or something that has a '__call'
-- metamethod implemented.
-- The 'params' is a table of parameters which will be passed to the task
-- when it's ready to run.
function Scheduler.scheduleTask(self, task, params, priority)
	--print("Scheduler.scheduleTask: ", task, params)
	params = params or {}
	
	if not task then
		return false, "no task specified"
	end

	task:setParams(params);
	

	if priority == 0 then
		self.TasksReadyToRun:pushFront(task);	
	else
		self.TasksReadyToRun:enqueue(task);	
	end

	task.state = "readytorun"

	return task;
end

function Scheduler.removeTask(self, task)
	return true;
end

function Scheduler.getCurrentTask(self)
	return self.CurrentFiber;
end

function Scheduler.suspendCurrentTask(self, ...)
	self.CurrentFiber.state = "suspended"
end

function Scheduler.step(self)
	-- see if there's a task that's ready to run
	local task = self.TasksReadyToRun:dequeue()

	-- If no task is in the ready queue, just return
	if not task then
		return true
	end

	-- if the task is already dead, then just
	-- keep it out of the ready list, and return
	if task:getStatus() == "dead" then
		self:removeTask(task)
		return true;
	end

	-- If the task we pulled off the ready list is 
	-- not dead, then perhaps it is suspended.  If that's true
	-- then it needs to drop out of the ready list.
	-- We assume that some other part of the system is responsible for
	-- keeping track of the task, and rescheduling it when appropriate.
	if task.state == "suspended" then
		return true;
	end

	-- If we have gotten this far, then the task truly is ready to 
	-- run, and it should be set as the currentFiber, and its coroutine
	-- is resumed.
	self.CurrentFiber = task;
	local results = {task:resume()};

	-- once we get results back from the resume, one
	-- of the following things could have happened.
	-- 1) The routine exited normally
	-- 2) The routine yielded
	-- 3) The routine threw an error
	--
	-- In all cases, we parse out the results of the resume 
	-- into a success indicator and the rest of the values returned 
	-- from the routine
	local success = results[1];
	table.remove(results,1);

	-- no task is currently executing
	self.CurrentFiber = nil;

	if not success then
		print("RESUME ERROR")
		print(unpack(results));
	end

	-- Again, check to see if the task is dead after
	-- the most recent resume.  If it's dead, then don't
	-- bother putting it back into the readytorun queue
	-- just remove the task from the list of tasks
	if task:getStatus() == "dead" then
		self:removeTask(task)

		return true;
	end

	-- The only way the task will get back onto the readylist
	-- is if it's state is 'readytorun', otherwise, it will
	-- stay out of the readytorun list.
	if task.state == "readytorun" then
		self:scheduleTask(task, results);
	end
end

Kernel = {
	ContinueRunning = true;
	TaskID = 0;
	Scheduler = Scheduler();
	TasksSuspendedForSignal = {};
}
local Kernel = Kernel;


local function getNewTaskID()
	Kernel.TaskID = Kernel.TaskID + 1;
	return Kernel.TaskID;
end

local function getCurrentTask()
	return Kernel.Scheduler:getCurrentTask();
end

local function getCurrentTaskID()
	return getCurrentTask().TaskID;
end


local function inMainTask()
	return coroutine.running() == nil; 
end

local function coop(priority, func, ...)
	local task = Task(func, ...)
	task.TaskID = getNewTaskID();
	task.Priority = priority;
	return Kernel.Scheduler:scheduleTask(task, {...}, priority);
end

local function spawn(func, ...)
	return coop(100, func, ...);
end

local function yield(...)
	return coroutine.yield(...);
end

local function suspend(...)
	Kernel.Scheduler:suspendCurrentTask();
	return yield(...)
end


local function signalTasks(eventName, priority, allofthem, ...)
	local tasklist = Kernel.TasksSuspendedForSignal[eventName];

	if not  tasklist then
		return false, "event not registered", eventName
	end

	local nTasks = #tasklist
	if nTasks < 1 then
		return false, "no tasks waiting for event"
	end

	if allofthem then
		--local allparams = {...}
		--print("allparams: ", allparams, #allparams)
		for i=1,nTasks do
			Kernel.Scheduler:scheduleTask(tasklist[1],{...}, priority);
			table.remove(tasklist, 1);
		end
	else
		Kernel.Scheduler:scheduleTask(tasklist[1],{...}, priority);
		table.remove(tasklist, 1);
	end

	return true;
end

local function signalOne(eventName, ...)
	return signalTasks(eventName, 100, false, ...)
end

local function signalAll(eventName, ...)
	return signalTasks(eventName, 100, true, ...)
end

local function signalAllImmediate(eventName, ...)
	return signalTasks(eventName, 0, true, ...)
end

local function waitForSignal(eventName,...)
	local currentFiber = Kernel.Scheduler:getCurrentTask();

	if currentFiber == nil then
		return false, "not currently in a running task"
	end

	if not Kernel.TasksSuspendedForSignal[eventName] then
		Kernel.TasksSuspendedForSignal[eventName] = {}
	end

	table.insert(Kernel.TasksSuspendedForSignal[eventName], currentFiber);

	return suspend(...)
end


-- One shot signal activation
local function onSignal(sigName, func)
	local function closure(sigName, func)
		func(waitForSignal(sigName));
	end

	return spawn(closure, sigName, func)
end

-- continuous signal activation
local function whenever(sigName, func)
	local function watchit(sigName, func)
		while true do
			func(waitForSignal(sigName))
		end
	end

	spawn(watchit, sigName, func)
end



local function run(func, ...)

	if func ~= nil then
		spawn(func, ...)
	end

	while (Kernel.ContinueRunning) do
		Kernel.Scheduler:step();		
	end
end

local function halt(self)
	Kernel.ContinueRunning = false;
end

local function globalizeKernel(tbl)
	tbl = tbl or _G;

	rawset(tbl, "Kernel", Kernel);

	-- task management
	rawset(tbl,"halt", halt);
	rawset(tbl,"run", run);
	rawset(tbl,"coop", coop);
	rawset(tbl,"spawn", spawn);
	rawset(tbl,"suspend", suspend);
	rawset(tbl,"yield", yield);

	-- signaling
	rawset(tbl,"onSignal", onSignal);
	rawset(tbl,"signalAll", signalAll);
	rawset(tbl,"signalAllImmediate", signalAllImmediate);
	rawset(tbl,"signalOne", signalOne);
	rawset(tbl,"waitForSignal", waitForSignal);
	rawset(tbl,"when", when);
	rawset(tbl,"whenever", whenever);

	-- extras
	rawset(tbl,"getCurrentTaskID", getCurrentTaskID);

	return tbl;
end

local global = globalizeKernel();

return Kernel