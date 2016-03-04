--test_scheduler.lua
package.path = package.path..";../?.lua"

Scheduler = require("schedlua.scheduler")()
MainScheduler = require("schedlua.scheduler")()
Task = require("schedlua.task")
local taskID = 0;

local function getNewTaskID()
	taskID = taskID + 1;
	return taskID;
end

local function spawn(func, priority, ...)
	local task = Task(func, ...)
	task.TaskID = getNewTaskID();
	if (priority <= 5) then
		MainScheduler:scheduleTask(task, {...});
	else
		Scheduler:scheduleTask(task, {...});
	end
	return task;
end


local function task1()
	print("first task, first line")
	Scheduler:yield();
	print("first task, second line")
end

local function task2()
	print("second task, only line")
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


