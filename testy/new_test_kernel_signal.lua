package.path = package.path..";../?.lua"

local Kernel = require("schedlua.kernel")()
local Functor = require("schedlua.functor")
local Scheduler = require("schedlua.scheduler")()
local MainScheduler = require("schedlua.scheduler")()

local function getNewTaskID() 
	taskID = taskID + 1;
	return taskID;
end

local function spawn(func, priority, ...)
	local task = Task(func, ...)
	task.TaskID = getNewTaskID();
	if (priority == "high") then
		MainScheduler:scheduleTask(task, {...});
	else
		Scheduler:scheduleTask(task, {...});
	end
	return task;
end

local function main()
	local t1 = spawn(task1, "low")
	local t2 = spawn(task2, "high")

	while (true) do
		--print("STATUS: ", t1:getStatus(), t2:getStatus())
		if t1:getStatus() == "dead" and t2:getStatus() == "dead" then
			break;
		end
		MainScheduler:step()
		Scheduler:step()
	end
end

main()

