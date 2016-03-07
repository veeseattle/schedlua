package.path = package.path..";../?.lua"

--[[
	Simple networking test case.
	Implement a client to the daytime service (port 13)
	Make a basic TCP connection, read data, finish
--]]
local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

Scheduler = require("schedlua.scheduler")();
MainScheduler = require("schedlua.scheduler")();
Task = require("schedlua.task")

local Kernel = require("schedlua.kernel")();
local net = require("schedlua.linux_net")();
local sites = require("sites");
--local asyncio = require("asyncio")

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


local AsyncSocket = require("schedlua.AsyncSocket")

--asyncio:setEventQuanta(1000);


local function httpRequest(s, sitename)
	local request = string.format("GET / HTTP/1.1\r\nUser-Agent: schedlua (linux-gnu)\r\nAccept: */*\r\nHost: %s\r\nConnection: close\r\n\r\n", sitename);
	

	local success, err = s:write(request, #request);
	print("==== httpRequest(), WRITE: ", success, err);
	io.write(request)
	print("---------------------");

	return success, err;
end


local function httpResponse(s)
	local bytesRead = 0
	local err = nil;
	local BUFSIZ = 512;
	local buffer = ffi.new("char[512+1]");


	-- Now that the socket is ready, we can wait for it to 
	-- be readable, and do a read
	print("==== httpResponse ====")
	repeat
		bytesRead = 0;

		bytesRead, err = s:read(buffer, BUFSIZ);

		if bytesRead then
			local str = ffi.string(buffer, bytesRead);
			io.write(str);
		else
			print("==== httpResponse.READ, ERROR: ", err)
			break;
		end

	until bytesRead < 1

	print("-----------------")
end


local function probeSite(sitename)

	local s = AsyncSocket();
	print("==== probeSite : ", sitename, s.fdesc.fd);

	local success, err = s:connect(sitename, 80);  

	if not success then
		print("NO CONNECTION TO: ", sitename, err);
		return false, err
	end
	-- issue a request so we have something to read
	httpRequest(s, sitename);
	httpResponse(s);

	s:close();
end

local function stopProgram()
	Kernel:halt();
end

local function task1()
	local maxProbes = 5;

	for idx=1,maxProbes do
		Kernel:spawn(probeSite, sites[idx])
		Kernel:yield();
	end
end

-- local function task1()
-- 	print("first task, first line")
-- 	Scheduler:yield();
-- 	print("first task, second line")
-- end

local function task2()
	print("second task, only line")
end

local function main()
	local t1 = spawn(task1, 9)
	local t2 = spawn(task2, 2)

	while (true) do
		--print("STATUS: ", t1:getStatus(), t2:getStatus())
		if t1:getStatus() == "dead" and t2:getStatus() == "dead" then
			break;
		end
		MainScheduler:step()
		Scheduler:step()
	end
end

Kernel:run(main)
