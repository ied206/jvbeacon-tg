--[[

	JovelBeacon Configuration File

--]]


---- administrators
-- You should put your own phone number (must, used for auth) and own telegram id number (recommended).
-- Your Telegram Id number can be found by running JovelBeacon not in daemon mode, and throw a message to bot.
-- Bot will print your telegram id number as "UserID"

--[[
Name    : 	[YourTelegramNickname]
Phone   : 	[YourPhoneNumber]
UserID  : 	[YourTelegramIdNumber]
Msg Num : 	[AccumulatedMsgs]
to.Name : 	[Bot's Id]
auth    : 	OK"
--]]
auth_alert	= {} -- "12345678"
auth_check	= {} -- ["82012345678"] = true


---- default wait interval (second)
default_interval = 1


---- languages
--lang = "ko" -- Not Implemented
lang = "en"

---- machine's environment
-- set your own environment
machine_env = "test"
-- machine_env = "server"
-- machine_env = "user"

allow_disk = {}
allow_net = {}
if machine_env == "test" then
	allow_disk["dev"]	= {"sdb2", "sdb2" ,"sda4"}
	allow_disk["label"]	= {"root", "home", "NTFS"}
	allow_disk["mnt"]	= {"/", "/home" ,"/mnt/ntfs"}
	allow_net["dev"]	= {"eth0", "wlan0"}
elseif machine_env == "server" then
	allow_disk["dev"]	= {"sda1", "sda3"}
	allow_disk["label"]	= {"root", "var"}
	allow_disk["mnt"]	= {"/", "/var"}
	allow_net["dev"]	= {"eth0"}
elseif machine_env == "user" then
	allow_disk["dev"]	= {}
	allow_disk["label"]	= {}
	allow_disk["mnt"]	= {}
	allow_net["dev"]	= {}
end

