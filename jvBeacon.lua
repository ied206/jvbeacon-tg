--[[

	JovelBeacon v1.3

	Linux Server Monitor Bot

	2015.02.19
	Written by ied206

--]]

-- beacon lua script's path
beacon_dir	= os.getenv("HOME").."/telegram/beacon"
dofile(beacon_dir.."/bconfig.lua")

now = os.time() -- Used for ignoring old messages

print ("JovelBeacon Server Monitor Bot v1.3")
print ("Written by ied206")


function on_msg_receive (msg)
	if msg.date < now then
		return
	end
	if msg.out then
		return
	end
	if msg.text then -- text message arrived
		local in_msg = ""
		if msg.text ~= nil then
			in_msg = string.gsub(msg.text,"&[;|<>/]","")	-- delete &, ;, |, <, >, / from msg
		end

		local cmd = getcmd(in_msg)		-- exam : ping a b c d => cmd = "ping", args = "a b c d"
		local args = getarg(in_msg)		-- exam : ping a b c d => cmd = "ping", args = "a b c d"
		cmd = string.lower(cmd)
		args = string.lower(args)
		print("Received : ", cmd, "\n")

        -- user_info
		print("Name    : ", msg.from.print_name)	-- Sender's real name 
		print("Phone   : ", msg.from.phone)		-- Sender's phone number (8210AAAABBBB)
		print("UserID  : ", msg.from.id) 		-- Sender's User ID numver
		print("Msg Num : ", msg.id)				-- Message Number
		print("to.Name : ", msg.to.print_name)	-- The account's name which JovelBeacon is running

		-- Find out whether client is using General Chat or Secret Chat
		-- 요청자가 일반대화인지 비밀대화인지 구분
		client = get_receiver(msg)

		-- For logging, save client information in global variables
		-- 로그를 위해 요청자의 정보를 전역변수에 저장
		cli_type = get_msgtype(msg)
		cli_name = msg.from.print_name
		cli_phone = msg.from.phone
		cli_userid = msg.from.id

		-- Only authorized phone number can access
		-- 지정한 폰번호만 접속 허용
		if auth_check[msg.from.phone] then
			print("auth    : ", "OK")
		else
			add_bclog("UNAUTHORIZED")
			print("auth    : ", "UNAUTHORIZED")
			send_msg(client, "UNAUTHORIZED ACCESS!\nYour name and phone number will be reported.", ok_cb, false)
			for i=1, #auth_alert do
				send_msg("user#id"..auth_alert[i], "UNAUTHORIZED ACCESS!\n"..cli_name..", +"..cli_phone..", "..cli_userid.." / "..cli_type.." / "..os.date("%Y.%m.%d / %H:%M:%S").." / "..cmd.." "..args, ok_cb, false)
			end
			return
		end
		mark_read(client, ok_cb, false)	-- mark as read, 읽은 메시지로 표시

		-- commands
		if cmd == "ping" then
			call_ping(args)
		elseif cmd == "loadavg" then
			call_loadavg(args)
		elseif cmd == "cpu" then
			call_cpu(args)
		elseif cmd == "mem" then
			call_mem(args)
		elseif cmd == "disk" then
			call_disk(args)
		elseif cmd == "diskio" then
			call_diskio(args)
		elseif cmd == "netio" then
			call_netio(args)
		elseif cmd == "users" then
			call_users(args)
		elseif cmd == "uptime" then
			call_uptime(args)
		elseif cmd == "lastboot" then
			call_lastboot(args)
		elseif cmd == "lastlogin" then
			call_lastlogin(args)
		elseif cmd == "bclog" then
			call_bclog(args)
		elseif cmd == "help" then
			call_help(args)
		else
			send_msg (client, cmd .. " : Wrong Command. Type \"help\" to know list of commands.", ok_cb, false)
		end
    elseif msg.media then -- media file arrived
    end
end
 
function on_our_id (id)
	our_id = id
	print("Beacon's User ID : ", id)
end

 
function on_user_update (user,what_changed)
end
 
function on_chat_update (user,what_changed)
end
 
function on_secret_chat_update(user,what_changed)
end

function on_get_difference_end ()
end
 
function on_binlog_replay_end ()
end

function ok_cb(extra, success, result)
end

-- BasicIO

function get_receiver(msg)
	local sender = ""
	if (msg.to.id == our_id) then
		sender	= msg.from.print_name	-- General Chat, 일반대화
	else
		sender	= msg.to.print_name		-- Secret Chat, 비밀대화
	end
	return sender
end

function get_msgtype(msg)
	local msgtype = ""
	if (msg.to.id == our_id) then
		msgtype = "general" -- General Chat, 일반대화
	else
		msgtype = "secret"	-- Secret Chat, 비밀대화
		end
	return msgtype
end

function getcmd (src)
	local index = string.find(src, " ")
	local outstr = src
	if index ~= nil then
		outstr = string.sub(src, 0, index - 1)
	end
	return outstr
end

function getarg (src)
	local index = string.find(src, " ")
	local outstr = ""
	if index ~= nil then
		outstr = string.sub(src, index + 1)
	end
	return outstr
end

function strsplit(inputstr, sep)
    if sep == nil then
		sep = "%s"
    end
    local t = {} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
    end
    return t
end

function scanfile(input)
	local fp = io.open(input, "r")
	if fp ~= nil then -- Exist, 존재하는 경우
		io.close(fp)
		return true
	else -- Not exist, 존재하지 않는 경우
		return false
	end
end

function sleep(n)
	os.execute("sleep " .. tonumber(n))
end

function find_list(list, value)
	for i=1, #list do
		if value == list[i] then
			return i
		end
	end

	return false
end

function find_list_i(list, value)
	for i=1, #list do
		if string.lower(value) == string.lower(list[i]) then
			return i
		end
	end

	return false
end

function run_shell(str)
	local sh = io.popen(str)
	local stdout = sh:read("*all")
	sh:close()
	return stdout
end

-- BeaconFunctions

function add_bclog (input)
	local bclogfp = io.open(beacon_dir.."/log/bclog.txt", "a")
	local bctime = os.date("%Y.%m.%d, %H:%M:%S")
	local output = cli_name.." / "..bctime.." / "..input.."\n"
	bclogfp:write(output)
	bclogfp:close()

	bclogfp = io.open(beacon_dir.."/log/bclog_verbose.txt", "a")
	output = cli_name..", +"..cli_phone..", "..cli_userid.." / "..cli_type.." / "..bctime.." / "..input.."\n"
	bclogfp:write(output)
	bclogfp:close()
end

function call_ping (args)
	add_bclog("ping "..args)
	send_msg (client, "pong", ok_cb, false)
	return
end

function call_loadavg (args)
	add_bclog("loadavg "..args)
	local rawstr = run_shell("uptime") -- cat /proc/loadavg
	-- "22:54:19 up 6:46, 1 user, load average: 0.05, 0.06, 0.05"
	local index = string.find(rawstr, "load")
	local cutstr = string.sub(rawstr, index)
	-- "load average: 0.05, 0.06, 0.05"
	local value = strsplit(cutstr, ",:%s")
	-- ["load"], ["average"], ["0.05"], ["0.06"], ["0.05"]
	local result = "Load average of 1 min : "..value[3].."\nLoad average of 5 min : "..value[4].."\nLoad average of 15min : "..value[5]
	send_msg(client, result, ok_cb, false)
	return
end


function call_cpu (args)
	add_bclog("cpu "..args)

	local core = 0 -- cpu[0] : overall, cpu[1]~cpu[n] : k(1<=k<=n)th core
	local interval = default_interval -- default interval

	local opt_s, opt_i -- opt_s : option argument, opt_i : option integar
	if args ~= "" then -- If argument exists
		local cut_args = strsplit(args, "%s")
	-- seperate command and integar
		for i = 1, #cut_args do
			opt_s, opt_i = string.match(cut_args[i], "(%a+)(%d+)")  -- %a: letter %s: whitespace %d: integar
			opt_i = tonumber(opt_i)
			if opt_s == "t" then
				if 0 < opt_i and opt_i <= 10 then
					interval = opt_i
				else
					send_msg(client, "Wait Interval should be under 10s, over 0s.", ok_cb, false)
					return
				end
			elseif opt_s == "core" and 1 <= opt_i and opt_i <= tonumber(run_shell("nproc")) then  -- nproc : get core number
				core = opt_i
			end
		end
	end

	-- cpu[0] : overall, cpu[1]~cpu[n] : k(1<=k<=n)th core
	local cpu = {}
	for i = 1, 3 do
		cpu[i] = {["user"]=0, ["nice"]=0, ["sys"]=0, ["idle"]=0, ["iowa"]=0, ["hirq"]=0, ["sirq"]=0, ["all"]=0}  -- raw value
	end
	local cpup = {["user"]=0, ["nice"]=0, ["sys"]=0, ["idle"]=0, ["iowa"]=0, ["hirq"]=0, ["sirq"]=0, ["all"]=0}  -- percentage value
	for k = 1, 2 do -- Check once more [interval] second since initial check, 1차 측정 후 interval초 지난 후 2차 측정
		local rawstr  = run_shell("cat /proc/stat | grep --color=never cpu") -- /proc/stat is accumalting value
		local cpuraw  = strsplit(rawstr, "\n")
--[[
	--		user  	ni 		sy 		id 		iowait	irq	softirq
	cpu 		245471	4121		135777 	5864283 	37441 	1858 0 0 0 0
	cpu0 	63372	2697		33197 	1602557 	11877 	546 	0 0 0 0
	cpu1 	49314	843 		39845 	1425981 	10140 	420 	0 0 0 0
	cpu2 	72357	574 		32418 	1410754 	8015 	577 	0 0 0 0
	cpu3 	60427	6 		30315 	1424989 	7407 	313 	0 0 0 0
]]

		cpuint = strsplit(cpuraw[core+1], "%s") -- extract intended cpu core only
-- ["cpu"],["245471"],["4121"],["135777"],["5864283"],["37441"], ["1858"]
		cpu[k].user = cpuint[2]
		cpu[k].nice = cpuint[3]
		cpu[k].sys  = cpuint[4]
		cpu[k].idle = cpuint[5]
		cpu[k].iowa = cpuint[6]
		cpu[k].hirq = cpuint[7]
		cpu[k].sirq = cpuint[8]
		cpu[k].all = cpu[k].user + cpu[k].nice + cpu[k].sys + cpu[k].idle + cpu[k].iowa + cpu[k].hirq + cpu[k].sirq
		
		if k == 1 then
			sleep(interval) 
		end
	end

	-- cpu[1] are INITIAL, cpu[2] are LATER. cpu[3] are SUB.
	cpu[3].user = cpu[2].user - cpu[1].user
	cpu[3].nice = cpu[2].nice - cpu[1].nice
	cpu[3].sys  = cpu[2].sys  - cpu[1].sys 
	cpu[3].idle = cpu[2].idle - cpu[1].idle
	cpu[3].iowa = cpu[2].iowa - cpu[1].iowa
	cpu[3].hirq = cpu[2].hirq - cpu[1].hirq
	cpu[3].sirq = cpu[2].sirq - cpu[1].sirq
	cpu[3].all  = cpu[2].all  - cpu[1].all

	cpup.user = math.floor((cpu[3].user / cpu[3].all) * 1000) / 10
	cpup.nice = math.floor((cpu[3].nice / cpu[3].all) * 1000) / 10
	cpup.sys  = math.floor((cpu[3].sys  / cpu[3].all) * 1000) / 10
	cpup.idle = math.floor((cpu[3].idle / cpu[3].all) * 1000) / 10
	cpup.iowa = math.floor((cpu[3].iowa / cpu[3].all) * 1000) / 10
	cpup.hirq = math.floor((cpu[3].hirq / cpu[3].all) * 1000) / 10
	cpup.sirq = math.floor((cpu[3].sirq / cpu[3].all) * 1000) / 10

	local result
	if 0 < core then
		result = "CPU core"..core.." usage"
	else
		result = "CPU usage"
	end
	if interval ~= default_interval then
		result = result.."\n(Interval : "..interval.."sec)"
	end
	result = result.."\n\nuser = "..cpup.user.."%\n".."nice = "..cpup.nice.."%\n".."sys  = "..cpup.sys.."%\n".."idle = "..cpup.idle.."%\n".."iowait = "..cpup.iowa.."%"
	send_msg(client, result, ok_cb, false)
	return
end


function call_mem (args)
	add_bclog("mem "..args)

	local cut_args = strsplit(args, "%s")

	local postpix = "MB" -- default value is MB
	local shellarg = "-m"
	local mems_nom = false
	local mems_act = false
	local mems_sw = false
	local mems_all = false
	for i = 1, #cut_args do
		if cut_args[i] == "k" then
			shellarg = "-k"
			postpix = "KB"
		elseif cut_args[i] == "m" then
			shellarg = "-m"
			postpix = "MB"
		elseif cut_args[i] == "g" then
			shellarg = "-g"
			postpix = "GB"
		elseif (cut_args[i] == "nominal" or cut_args[i] == "no") then
			mems_nom = true
		elseif (cut_args[i] == "actual" or cut_args[i] == "ac") then
			mems_act = true
		elseif (cut_args[i] == "swap" or cut_args[i] == "sw") then
			mems_sw = true
		end
	end
	if mems_nom == false and mems_act == false and mems_sw == false then
		mems_all = true
	end
	
	local rawstr = run_shell("free "..shellarg) -- cat /proc/meminfo
--[[
             total       used       free     shared    buffers     cached
Mem:        896072     640116     255956          0     114180     216588
-/+ buffers/cache:     309348     586724
Swap:      2097148          0    2097148
--]]
	local memraw	= strsplit(rawstr, "\n") -- cut as one lines
	local realmem	= strsplit(memraw[2], "%s")
	local actumem	= strsplit(memraw[3], "%s")
	local swapmem	= strsplit(memraw[4], "%s")

	local r_total	= realmem[2]	-- 전체 실제메모리
	local r_used	= realmem[3]	-- 전체 사용중 메모리
	local r_free	= realmem[4]	-- 비어있는 메모리
	local r_shared	= realmem[5]	-- 공유중 메모리
	local r_buffer	= realmem[6]	-- 버퍼 메모리
	local r_cache	= realmem[7] 	-- 캐시된 메모리
	local a_used	= actumem[3]	-- 실제로 쓰고 있는 메모리
	local a_free	= actumem[4]	-- 실제로 비어 있는 메모리
	local s_total	= swapmem[2]	-- 총 스왑메모리
	local s_used	= swapmem[3]	-- 사용중 스왑메모리
	local s_free	= swapmem[4]	-- 비어있는 스왑메모리

	postpix = string.upper(postpix)
	local str_mem = ""
	local str_amem = ""
	local str_swap = ""
	if mems_nom == true or mems_all == true then
		str_mem	= "Nominal Memory\nTotal = "..r_total..postpix.."\nUsed = "..r_used..postpix.."\nEmpty = "..r_free..postpix.."\nBuffer = "..r_buffer..postpix.."\nCached = "..r_cache..postpix.."\n\n"
	end
	if mems_act == false and mems_all == true then
		str_amem	= "Actual Memory\nUsed = "..a_used..postpix.."\nEmpty = "..a_free..postpix.."\n\n"
	elseif mems_act == true then
		str_amem	= "Actual Memory\nTotal = "..r_total..postpix.."\nUsed = "..a_used..postpix.."\nEmpty = "..a_free..postpix.."\n\n"
	end
	if mems_sw == true or mems_all == true then
		str_swap	= "Swap Memory\nTotal = "..s_total..postpix.."\nUsed = "..s_used..postpix.."\nEmpty = "..s_free..postpix.."\n\n"
	end

	send_msg(client, str_mem..str_amem..str_swap, ok_cb, false)
	return
end


function call_disk (args)
	add_bclog("disk "..args)

-- parse arguments
	local result
	local viewlist = false
	local view_one = false
	local viewthis
	if args ~= "" then
		local cut_args = strsplit(args, "%s")
		for i = 1, #cut_args do
			if cut_args[i] == "list" then
				viewlist = true
			else
				local vlist = find_list(allow_disk["dev"], cut_args[i])
				if vlist ~= false then -- if disk is in allowed disk list // 허용된 디스크 리스트에 있는 경우
					view_one = true
					viewthis = vlist
				else
					send_msg(client, "disk \'"..cut_args[i].."\' is forbidden or not exist.\nType \"help disk\" to get manual.", ok_cb, false)
					return
				end
			end
		end
	end

-- If user wanted to view only list
	if viewlist then
		result = "Disk List\n\n"
		for i=1, #allow_disk["dev"] do
			result = result..allow_disk["dev"][i].." ("..allow_disk["label"][i]..")\n"
		end
		send_msg(client, result, ok_cb, false)
		return
	end

	local part = {}

-- Parse df command's return
	for i = 1, #allow_disk["mnt"] do
		local rawstr = run_shell("df -h | grep --color=never "..allow_disk["mnt"][i])
	--	/dev/sda5        85G   19G   63G  23% /home
		local value = strsplit(rawstr, "%s")
	--	["/dev/sda5"], ["85G"], ["19G"], ["63G"], ["23%"], ["/home"]
		part[i] = {["dev"] = value[1], ["size"] = value[2].."B", ["used"] = value[3].."B", ["avail"] = value[4].."B", ["percent"] = value[5]}
	end

-- calculate disk usage
	result = "Disk Usage\n\n"
	if view_one then -- Print device "args"
		result = result..allow_disk["dev"][viewthis].." ("..allow_disk["label"][viewthis]..")\nSize = "..part[viewthis].size.."\nUsed = "..part[viewthis].used.."\nAvail = "..part[viewthis].avail.."\nUsed% = "..part[viewthis].percent
	else -- Print all devices
		for i = 1, #allow_disk["mnt"] do
			result = result..allow_disk["dev"][i].." ("..allow_disk["label"][i]..")\nSize = "..part[i].size.."\nUsed = "..part[i].used.."\nAvail = "..part[i].avail.."\nUsed% = "..part[i].percent.."\n\n"
		end
	end

	send_msg(client, result, ok_cb, false)
	return
end


function call_diskio (args)
	add_bclog("diskio "..args)

	local result
-- parse arguments
	local sibyte = "KB/s" -- what si will be used
	local viewlist = false -- View only lists
	local view_one = false -- View only one device
	local viewthis -- view only "this" device
	local interval = default_interval -- wait interval
	if args ~= "" then
		local cut_args = strsplit(args, "%s")
		for i = 1, #cut_args do
			if cut_args[i] == "k" then
				sibyte = "KB/s"
			elseif cut_args[i] == "m" then
				sibyte = "MB/s"
			elseif cut_args[i] == "g" then
				sibyte = "GB/s"
			elseif cut_args[i] == "list" then
				viewlist = true
			else
				view_one = true
				viewthis = cut_args[i]	
			end
		end
	end

-- if viewlist is on, print only device list then return
	if viewlist then
		result = "Disk List\n\n"
		for i=1, #allow_disk["dev"] do
			result = result..allow_disk["dev"][i].." ("..allow_disk["label"][i]..")\n"
		end
		send_msg(client, result, ok_cb, false)
		return
	end

-- get raw values two times
	local devlist = {} -- device list
	local rspeed_raw = {}
	rspeed_raw[1] = {}
	rspeed_raw[2] = {}
	local wspeed_raw = {}
	wspeed_raw[1] = {}
	wspeed_raw[2] = {}


	for n = 1, 2 do
		local rawstr = run_shell("cat /proc/diskstats | awk \'{print $3\":\"$6\":\"$10}\'")
		local rawline = strsplit(rawstr, "\n") -- cut raw strings into lines

		local cursor = 1 -- valid list
		-- rawvalue[1] : device name, rawvalue[2] : sectors read since boot, rawvalues[3] : sectors wrote since boot
		for i=1, #rawline do -- devlist에 dev_conf에 있는 값만 넣는다
			local rawvalue = strsplit(rawline[i], ":") -- cut all values into pieces
			if find_list(allow_disk["dev"], rawvalue[1]) ~= false then 
				devlist[cursor] = rawvalue[1]
				rspeed_raw[n][cursor] = rawvalue[2]
				wspeed_raw[n][cursor] = rawvalue[3]
				cursor = cursor + 1
			end	
		end

		if n == 1 then
			sleep(interval)
		end
	end
	
-- devlist
-- ["sda1"], ["492118"], ["94288"]
-- ["sda5"], ["4316922"], ["80"]

-- validate 'viewthis' 
	if view_one then
		if find_list(allow_disk["dev"], viewthis) == false then
			send_msg(client, "disk \'"..viewthis.."\' is forbidden or not exist.\nType \"help diskio\" to get manual.", ok_cb, false)
			return
		end
	end

-- calculated speed
	local rspeed = {} -- calculated read speed
	local wspeed = {} -- calculated write speed
	for i=1, #devlist do
		if sibyte == "KB/s" then -- raw values are 0.5KB/s
			rspeed[i] = math.floor((rspeed_raw[2][i] - rspeed_raw[1][i]) / (2 * interval))
			wspeed[i] = math.floor((wspeed_raw[2][i] - wspeed_raw[1][i]) / (2 * interval))
		elseif sibyte == "MB/s" then
			rspeed[i] = math.floor((rspeed_raw[2][i] - rspeed_raw[1][i]) / 2048 * 10) / (10 * interval)
			wspeed[i] = math.floor((wspeed_raw[2][i] - wspeed_raw[1][i]) / 2048 * 10) / (10 * interval)
		elseif sibyte == "GB/s" then
			rspeed[i] = math.floor((rspeed_raw[2][i] - rspeed_raw[1][i]) / (1024 * 2048) * 10) / (10 * interval)
			wspeed[i] = math.floor((wspeed_raw[2][i] - wspeed_raw[1][i]) / (1024 * 2048) * 10) / (10 * interval)
		end
	end

-- Generate result string's header
	
	result = "Disk IO\n\n"
-- Generate result string body
	if view_one then
		local cursor = find_list(devlist, viewthis)
		result = result..viewthis.." ("..allow_disk["label"][cursor]..")\nRead = "..rspeed[cursor]..sibyte.."\nWrite = "..wspeed[cursor]..sibyte
	elseif viewlist then
		for i=1, #devlist do
			result = result..devlist[i].."\n"
		end
	else
		for i=1, #devlist do
			result = result..devlist[i].." ("..allow_disk["label"][i]..")\nRead = "..rspeed[i]..sibyte.."\nWrite = "..wspeed[i]..sibyte.."\n\n"
		end
	end

	send_msg(client, result, ok_cb, false)
	return
end


function call_netio (args) -- 리팩토링 필요
	add_bclog("netio "..args)

-- parse arguments
	local sibyte = "KB/s" -- what si will be used
	local viewlist = false -- View only lists
	local view_one = false -- View only one device
	local viewthis -- view only "this" device
	local interval = default_interval -- wait interval
	if args ~= "" then
		local cut_args = strsplit(args, "%s")
		for i = 1, #cut_args do
			if cut_args[i] == "k" then
				sibyte = "KB/s"
			elseif cut_args[i] == "m" then
				sibyte = "MB/s"
			elseif cut_args[i] == "g" then
				sibyte = "GB/s"
			elseif cut_args[i] == "list" then
				viewlist = true
			else
				view_one = true
				viewthis = cut_args[i]	
			end
		end
	end

--[[
Inter-|:Receive:
face:|bytes:packets	// multicast|bytes 때문에 byte 대신 packets가 10번째로 온다
eth0::0:0
lo::250304:250304
wlan0::61309958:5541809
--]]

-- New Code
	-- get raw values two times
	local devlist = {} -- device list
	local rspeed_raw = {}
	rspeed_raw[1] = {}
	rspeed_raw[2] = {}
	local wspeed_raw = {}
	wspeed_raw[1] = {}
	wspeed_raw[2] = {}

	for n = 1, 2 do
		local rawstr = run_shell("cat /proc/net/dev | awk \'{print $1\":\"$2\":\"$10}\'") --  | awk '{print $2":"$10}'
		local rawline = strsplit(rawstr, "\n") -- cut raw strings into lines

		local cursor = 1 
		-- rawvalue[1] : device name, rawvalue[2] : bytes read since boot, rawvalues[3] : bytes wrote since boot
		for i=3, #rawline do -- devlist에 allow_net에 있는 값만 넣는다
			local rawvalue = strsplit(rawline[i], ":") -- cut all values into pieces
			if find_list(allow_net["dev"], rawvalue[1]) ~= false then -- found allowed dev, such as [eth0, wlan0]
				devlist[cursor] = rawvalue[1]
				rspeed_raw[n][cursor] = rawvalue[2]
				wspeed_raw[n][cursor] = rawvalue[3]
				cursor = cursor + 1
			end
		end

		if n == 1 then
			sleep(interval)
		end
	end

	-- Generate result string's header
	local result
	if viewlist then
		result = "Network Interface List\n\n"
	else
		result = "Network IO Usage\n\n"
	end

	-- add sum value
	i = #devlist + 1
	for n=1, 2 do
		rspeed_raw[n][i] = 0
		wspeed_raw[n][i] = 0
		for k=1, #devlist do
			rspeed_raw[n][i] = rspeed_raw[n][i] + rspeed_raw[n][k]
			wspeed_raw[n][i] = wspeed_raw[n][i] + wspeed_raw[n][k]
		end
	end
	devlist[i] = "all"

	-- devlist
-- ["eth0"], ["9535"], ["8240"]
-- ["wlan0"], ["61309958"], ["5541809"]
-- ["all"], ["61319493"], ["5550049"]

-- Validate 'viewthis' 
	if view_one then
		if find_list(allow_net["dev"], viewthis) == false and viewthis ~= "all" then
			send_msg(client, "Network interface \'"..viewthis.."\' is forbidden or not exist.\nType \"help netio\" for usage.", ok_cb, false)
			return
		end
	end

-- calculate speed
	local rspeed = {} -- calculated read speed
	local wspeed = {} -- calculated write speed
	for i=1, #devlist do
		if sibyte == "KB/s" then -- raw values are Bytes
			rspeed[i] = math.floor((rspeed_raw[2][i] - rspeed_raw[1][i]) / 1024 * 10) / (10 * interval) -- 10으로 나눴다가 10으로 합치는 건, 3.5KB/s 식으로 뽑아내려는것
			wspeed[i] = math.floor((wspeed_raw[2][i] - wspeed_raw[1][i]) / 1024 * 10) / (10 * interval)
		elseif sibyte == "MB/s" then
			rspeed[i] = math.floor((rspeed_raw[2][i] - rspeed_raw[1][i]) / (1024 * 1024) * 10) / (10 * interval)
			wspeed[i] = math.floor((wspeed_raw[2][i] - wspeed_raw[1][i]) / (1024 * 1024) * 10) / (10 * interval)
		elseif sibyte == "GB/s" then
			rspeed[i] = math.floor((rspeed_raw[2][i] - rspeed_raw[1][i]) / (1024 * 1024 * 1024) * 10) / (10 * interval)
			wspeed[i] = math.floor((wspeed_raw[2][i] - wspeed_raw[1][i]) / (1024 * 1024 * 1024) * 10) / (10 * interval)
		end
	end

	-- Generate result string body
	if view_one then
		local cursor = find_list(devlist, viewthis)
		result = result..viewthis.."\nReceive = "..rspeed[cursor]..sibyte.."\nTransmit = "..wspeed[cursor]..sibyte
	elseif viewlist then
		for i=1, #devlist do
			result = result..devlist[i].."\n"
		end
	else
		for i=1, #devlist do
			result = result..devlist[i].."\nReceive = "..rspeed[i]..sibyte.."\nTransmit = "..wspeed[i]..sibyte.."\n\n"
		end
	end

	send_msg(client, result, ok_cb, false)
	return
end


function call_users (args)
	add_bclog("users "..args)

	local verbose = false -- if verbose is true, then it shows list of logged in users
	if args ~= "" then -- If it has arguments
		local cut_args = strsplit(args, "%s")
		for i=1, #cut_args do
			if cut_args[i] == "v" then
				verbose = true
			else
				send_msg(client, "Wrong argument \'"..args.."\'.\nType \"help users\" to get manual", ok_cb, false)
				return
			end
		end
	end

	local rawstr = run_shell("who | awk \'{print $1\" : \"$2\", \"$3\", \"$4\" \"$5}\'")
	-- "joveler  pts/0        2014-11-08 18:12 (39.7.19.50)"
	local rawtable = strsplit(rawstr, "\n") -- 몇 줄, 즉 몇 명이 로그인했는가를 알기 위해 분할
	local users = #rawtable
	local userstr = "users are"
	if users == 1 then -- 1명이면 user, 2명 이상이면 users
		userstr = "user is"
	end
	-- "1 user is logged in"
	local result = users.." "..userstr.." logged in"

-- Verbose mode : list logged in users
	if verbose then
		result = result.."\n\nList of users\n"..rawstr
	end

	send_msg(client, result, ok_cb, false)
	return
end


function call_uptime (args)
	add_bclog("uptime "..args)
-- 부팅된 시각을 받아옴
	local btline = run_shell("cat /proc/stat | grep --color=never btime")
	-- btime 1415103776
	local btime_raw = getarg(btline) -- UNIX TIME을 받아왔다.
	-- 1415103776

	local rtime_raw = os.time() - btime_raw	-- 현재 시간에서 부팅 시각을 뺀다
 
 	-- 구동시간을 일, 시간, 월, 분, 초로 쪼갠다
	local rdate = math.floor(rtime_raw / (60 * 60 * 24))
	local rhour = math.floor(rtime_raw / (60 * 60)) % 24
	local rmin = math.floor(rtime_raw / 60) % 60
	local rsec = rtime_raw % 60
	local rtime = "Server Uptime\n"..rdate.."day / "..rhour.."h "..rmin.."m "..rsec.."s"
	send_msg(client, rtime, ok_cb, false)
	return
end


function call_lastboot (args)
	add_bclog("lastboot "..args)
-- 부팅된 시각을 받아옴
	local btline = run_shell("cat /proc/stat | grep --color=never btime")
	-- btime 1415103776
	local btime_raw = getarg(btline) -- UNIX TIME을 받아왔다.
	-- 1415103776
	local btime = os.date("%Y.%m.%d / %H:%M:%S", btime_raw) -- UNIX TIME을 일반 형태로 바꿈
	-- 2014.11.04 / 21:22:56
	send_msg(client, "Last boot time\n"..btime, ok_cb, false)
	return
end


function call_lastlogin (args)
	add_bclog("lastlogin "..args)
	local lognum = 5 -- 기본값은 5번이다
	local errorstr = ""
	if args ~= "" then -- 인자가 들어왔다면
		lognum = tonumber(args)
		if lognum == nil then -- 인자가 숫자로 들어오지 않았다
			errorstr = "Invalid argument : "..args.."\n"
			lognum = 5
		elseif lognum > 50 then -- 인자 수가 50을 넘어간다 (52를 넘어가면 전송이 안 됨)
			errorstr = "Requests must be under 50.\n"
			lognum = 50
		end
	end
	local result = run_shell("last -"..lognum)
	send_msg(client, errorstr.."Printing recent "..lognum.." login logs.\n\n"..result, ok_cb, false)
	return
end


function call_bclog (args)
	local cut_args = strsplit(args, "%s") -- 인자를 잘라낸다

	local lognum = 5;
	local verbose = false;
	for i = 1, #cut_args, 1 do
		if cut_args[i] == "v" then -- 자세한 로그 출력
			verbose = true;
		elseif tonumber(cut_args[i]) ~= nil then -- 숫자
			lognum = tonumber(cut_args[i])
			if lognum > 50 then -- 인자 수가 50을 넘어간다 (52를 넘어가면 전송이 안 됨)
				errorstr = "Requests must be under 50.\n"
				lognum = 50
			end
		else
			send_msg(client, "Wrong argument \'"..args.."\'.\nType \"help bclog\" to get manual", ok_cb, false)
			return
		end
	end

	local bclogfp = ""
	if not verbose then -- 일반 로그
		bclogfp = io.open(beacon_dir .."/log/bclog.txt", "r")
	else -- 자세한 로그
		bclogfp = io.open(beacon_dir .."/log/bclog_verbose.txt", "r")
	end

	io.input(bclogfp)
	local bclograw = io.read("*all") -- 파일 전부 다 읽어오기
	io.close(bclogfp)

	local bclog = strsplit(bclograw, "\n") -- 한 줄씩 잘라낸다
	-- 5개밖에 없는데 10개를 보여줄수는 없다
	if #bclog - lognum <= 0 then
		lognum = #bclog
	end

	local result = "JovelBeacon log archive\n\nPrinting recent "..lognum.." logs\n\n"
	for i = #bclog-lognum+1, #bclog, 1 do
		result = result..bclog[i].."\n"
	end
	
	send_msg(client, result, ok_cb, false)
	add_bclog("bclog "..args)
	return
end


function call_help (args)
	add_bclog("help "..args)

	local help_file
	if args == "" then -- 인자가 없다
		help_file = beacon_dir.."/help/"..lang.."/help.txt"
	elseif args == "all" then
		help_file = beacon_dir.."/help/"..lang.."/help_verbose.txt"
	else -- 나머지 
		help_file = beacon_dir.."/help/"..lang.."/"..args..".txt"
	end

	if scanfile(help_file) then -- 명령어 도움말 txt가 존재한다
		send_text(client, help_file, ok_cb, false)
	else -- 명령어 도움말 txt가 존재하지 않는다
		sent_msg(client, "Requested manual of "..args.." does not exist!", ok_cb, false)
	end
	return
end
