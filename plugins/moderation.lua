do

local function callback(extra, success, result)
	vardump(success)
end

local function is_spromoted(chat_id, user_id)
  local hash =  'sprom:'..chat_id..':'..user_id
  local spromoted = redis:get(hash)
  return spromoted or false
end

local function spromote(receiver, user_id, username)
  local chat_id = string.gsub(receiver, '.+#id', '')
  local data = load_data(_config.moderation.data)
  if not data[tostring(chat_id)] then
    return send_large_msg(receiver, 'Group is not added.')
  end
  if data[tostring(chat_id)]['moderators'][tostring(user_id)] then
    if is_spromoted(chat_id, user_id) then
      return send_large_msg(receiver, 'هوه مدير مشرفين بلفعل')
    end
    local hash =  'sprom:'..chat_id..':'..user_id
  redis:set(hash, true)
  send_large_msg(receiver, 'User '..username..' ['..user_id..'] تم جعلة مدير المشرفين بلمجموعة')
  return
  else
    data[tostring(chat_id)]['moderators'][tostring(user_id)] = string.gsub(username, '@', '')
    save_data(_config.moderation.data, data)
    local hash =  'sprom:'..chat_id..':'..user_id
    redis:set(hash, true)
    send_large_msg(receiver, ' '..username..' تم جعلة مدير المشرفين بلمجموعة')
    return
  end
end

local function sdemote(receiver, user_id, username)
  local chat_id = string.gsub(receiver, '.+#id', '')
  if not is_spromoted(chat_id, user_id) then
    return send_large_msg(receiver, 'غير اداري')
  end
  local data = load_data(_config.moderation.data)
  data[chat_id]['moderators'][tostring(user_id)] = nil
  save_data(_config.moderation.data, data)
  local hash =  'sprom:'..chat_id..':'..user_id
  redis:del(hash)
  send_large_msg(receiver, 'User '..username..' ['..user_id..'] تم تنزيلة من ادارة المشرفين')
end

local function check_member(extra, success, result)
  local data = extra.data
  for k,v in pairs(result.members) do
    if v.id ~= our_id then
      data[tostring(extra.msg.to.id)] = {
        moderators = {[tostring(v.id)] = v.username},
        settings = {
          set_name = string.gsub(extra.msg.to.print_name, '_', ' '),
          lock_bots = 'no',
          lock_name = 'no',
          lock_photo = 'no',
          lock_member = 'no',
          anti_flood = 'no',
          welcome = 'no',
          sticker = 'ok',
          }
       }
      save_data(_config.moderation.data, data)
      return send_large_msg(extra.receiver, ' تم جعلة مدير مشرفين في المجموعة.')
    end
  end
end

local function automodadd(msg)
  local data = load_data(_config.moderation.data)
  if msg.action.type == 'channel_created' or msg.action.type == 'chat_created' then
    local receiver = get_receiver(msg)
    channel_info(receiver, check_member,{receiver=receiver, data=data, msg=msg})
  else
    if data[tostring(msg.to.id)] then
      return 'Group is already added.'
    end
    if msg.from.username then
      username = msg.from.username
    else
      username = msg.from.print_name
    end
    -- create data array in moderation.json
    data[tostring(msg.to.id)] = {
      moderators ={[tostring(msg.from.id)] = username},
      settings = {
        set_name = string.gsub(msg.to.print_name, '_', ' '),
        lock_bots = 'no',
        lock_name = 'no',
        lock_photo = 'no',
        lock_member = 'no',
        anti_flood = 'no',
        welcome = 'no',
        sticker = 'ok',
        }
      }
    save_data(_config.moderation.data, data)
    return 'Group has been added, and @'..username..' has been admin for this group.'
  end
end

local function modrem(msg)
  if not is_admin(msg) then
    return "You're not admin"
  end
  local data = load_data(_config.moderation.data)
  local receiver = get_receiver(msg)
  if not data[tostring(msg.to.id)] then
    return 'Group is not added.'
  end

  data[tostring(msg.to.id)] = nil
  save_data(_config.moderation.data, data)

  return 'Group has been removed'
end

local function promote(receiver, username, user_id)
  local data = load_data(_config.moderation.data)
  local group = string.gsub(receiver, '.+#id', '')
  if not data[group] then
    return send_large_msg(receiver, 'Group is not added.')
  end
  if data[group]['moderators'][tostring(user_id)] then
    return send_large_msg(receiver, username..' مساعد🛠 مشرف سابق بلمجموعة.')
    end
    data[group]['moderators'][tostring(user_id)] = string.gsub(username, '@', '')
    save_data(_config.moderation.data, data)
    return send_large_msg(receiver, username..' تم جعلة مساعد لمشرفين بلمجموعة ☑️.')
end

local function demote(receiver, username, user_id)
  local data = load_data(_config.moderation.data)
  local group = string.gsub(receiver, '.+#id', '')
  if not data[group] then
    return send_large_msg(receiver, 'Group is not added.')
  end
  if not data[group]['moderators'][tostring(user_id)] then
    return send_large_msg(receiver, string.gsub(username, '@', '')..' هاذا العضو ليس  (مساعد أو مشرف) بلمجموعة 🍃☑️.')
  end
  data[group]['moderators'][tostring(user_id)] = nil
  save_data(_config.moderation.data, data)
  return send_large_msg(receiver, '@'..username..' هاذا العضو تم تنزيلة من  (مساعد) لمجموعة 🍃☑️.')
end

local function upmanager(receiver, username, user_id)
  channel_set_admin(receiver, 'user#id'..user_id, callback, false)
  return send_large_msg(receiver, username.. ' تم جعلة ادمن مجموعة خارقة')
end

local function inmanager(receiver, username, user_id)
  channel_set_unadmin(receiver, 'user#id'..user_id, callback, false)
  return send_large_msg(receiver,  username..' تم تنزيلة من ادمن المجموعة الخارقة')
end

local function admin_promote(receiver, username, user_id)  
  local data = load_data(_config.moderation.data)
  if not data['admins'] then
    data['admins'] = {}
    save_data(_config.moderation.data, data)
  end

  if data['admins'][tostring(user_id)] then
    return send_large_msg(receiver, '#'..username..' is already as vip gold⚜.')
  end
  
  data['admins'][tostring(user_id)] = string.gsub(username, '@', '')
  save_data(_config.moderation.data, data)
  return send_large_msg(receiver, '#'..username..' now he is a vip gold⚜ member')
end

local function admin_demote(receiver, username, user_id)
    local data = load_data(_config.moderation.data)
  if not data['admins'] then
    data['admins'] = {}
    save_data(_config.moderation.data, data)
  end

  if not data['admins'][tostring(user_id)] then
    return send_large_msg(receiver, '#'..username..' is not Vip⚜')
  end

  data['admins'][tostring(user_id)] = nil
  save_data(_config.moderation.data, data)

  return send_large_msg(receiver, 'VIP @'..username..' removed from Vip⚜')
end

local function username_id(cb_extra, success, result)
   local get_cmd = cb_extra.get_cmd
   local receiver = cb_extra.receiver
   local member = cb_extra.member
   local text = ' @'..member..' ⚠️ لا يمكن العثور على هاذا المستخدم في المجموعة '
   for k,v in pairs(result.members) do
      vusername = v.username
      if vusername == member then
        username = member
        user_id = v.peer_id
        if get_cmd == 'add' then
            return promote(receiver, username, user_id)
        elseif get_cmd == 'del' then
          if is_spromoted(string.gsub(receiver,'.+#id', ''), user_id) then
            return send_large_msg(receiver, 'Can\'t demoted')
          end
          return demote(receiver, username, user_id)
        elseif get_cmd == 'vipgold' then
          if user_id == our_id then
            return
          end
          return admin_promote(receiver, username, user_id)
        elseif get_cmd == 'del' then
          if user_id == our_id then
            return
          end
          return admin_demote(receiver, username, user_id)
        elseif get_cmd == 'sadd' then
          return spromote(receiver, user_id, username)
        elseif get_cmd == 'sdel' then
          return sdemote(receiver, user_id, username)
        end
      end
   end
   send_large_msg(receiver, text)
end

local function channel_username_id(cb_extra, success, result)
   local get_cmd = cb_extra.get_cmd
   local receiver = cb_extra.receiver
   local member = cb_extra.member
   local text = ' @'..member..' ⚠️ لا يمكن العثور على هاذا المستخدم في المجموعة '
   for k,v in pairs(result) do
      vusername = v.username
      if vusername == member then
        username = member
        user_id = v.peer_id
        if get_cmd == 'add' then
          return promote(receiver, username, user_id)
        elseif get_cmd == 'del' then
          if is_spromoted(string.gsub(receiver,'.+#id', ''), user_id) then
            return send_large_msg(receiver, 'Can\'t del')
          end
          return demote(receiver, username, user_id)
        elseif get_cmd == 'vipgold' then
          if user_id == our_id then
            return
          end
          return admin_promote(receiver, username, user_id)
        elseif get_cmd == 'unvipgold' then
          if user_id == our_id then
            return
          end
          return admin_demote(receiver, username, user_id)
        elseif get_cmd == 'sadd' then
          return spromote(receiver, user_id, username)
        elseif get_cmd == 'sdel' then
          return sdemote(receiver, user_id, username)
        elseif get_cmd == 'addsuper' then
          return upmanager(receiver, username, user_id)
        elseif get_cmd == 'delsuper' then
          return inmanager(receiver, username, user_id)
        end
      end
   end
   send_large_msg(receiver, text)
end

local function get_msg_callback(extra, success, result)
  if success ~= 1 then return end
  local get_cmd = extra.get_cmd
  local receiver = extra.receiver
  local user_id = result.from.peer_id
  local chat_id = result.to.id
  if result.from.username then
    username = '@'..result.from.username
  else
    username = string.gsub(result.from.print_name, '_', ' ')
  end
  if get_cmd == 'sadd' then
    if user_id == our_id then
      return nil
    end
    return spromote(receiver, user_id, username)
  end
  if get_cmd == 'sdel' then
    if user_id == our_id then
      return nil
    end
    return sdemote(receiver, user_id, username)
  end
  if get_cmd == 'add' then
    if user_id == our_id then
      return nil
    end
    return promote(receiver, username, user_id)
  end
  if get_cmd == 'del' then
    if user_id == our_id then
      return nil
    end
    if is_spromoted(chat_id, user_id) then
      return send_large_msg(receiver, 'Can\'t demote leader')
    end
    return demote(receiver, username, user_id)
  end
  if get_cmd == 'addsuper' then
    return upmanager(receiver, username, user_id)
  end
  if get_cmd == 'delsuper' then
    return inmanager(receiver, username, user_id)
  end
end

local function modlist(msg)
  local data = load_data(_config.moderation.data)
  if not data[tostring(msg.to.id)] then
    return 'Group is not added.'
  end
  -- determine if table is empty
  if next(data[tostring(msg.to.id)]['moderators']) == nil then --fix way
    return 'No moderator in this group.'
  end
  local message = 'مشرفيّ المجموعة : \n👥🆔ايدي لمجموعة - ' .. string.gsub(msg.from.id, '_', ' ') .. ' : \n\n'
  for k,v in pairs(data[tostring(msg.to.id)]['moderators']) do
    if is_spromoted(msg.to.id, k) then
      message = message .. '• @'..v..' (' ..k.. ') 🏧مشرف \n'
    else
      message = message .. '• @'..v..' (' ..k.. ') 👷🏽مساعد \n'
    end
  end

  return message
end


local function admin_list(msg)
    local data = load_data(_config.moderation.data)
  if not data['admins'] then
    data['admins'] = {}
    save_data(_config.moderation.data, data)
  end
  if next(data['admins']) == nil then --fix way
    return 'لا يوجد مدراء ViP في هاذا المجموعة  💡'
  end
  local message = '⚜ list vip member ⚜ : welcome my sudo : '..msg.from.first_name.."\n\n"
  for k,v in pairs(data['admins']) do
    message = message .. '⚜ ' .. v ..' ('..k..') \n'
  end
  return message
end

function run(msg, matches)
  if is_channel_msg(msg) then 
    local get_cmd = matches[1]
    local receiver = get_receiver(msg)
    
    if matches[1] == 'add' then
      if not is_momod(msg) then
        return
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'del' then
      if not is_momod(msg) then
        return "Only admins group can del"
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.gsub(matches[2], "@", "") == msg.from.username then
        return "You can't del yourself"
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'sadd' then
      if not is_admin(msg) then
        return "هاذا الامر متاح للـ (العضوية الذهبية⚜) فقط.☑️"
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'sdel' then
      if not is_admin(msg) then
        return "هاذا الامر متاح للـ (العضوية الذهبية⚜) فقط.☑️"
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.match(matches[2], '^%d+$') then
        return sdemote(receiver, matches[2], matches[2])
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'admin' then
      return modlist(msg)
    end
    
    
    if matches[1] == 'addsuper' then
      if not is_admin(msg) then
        if not is_spromoted(msg.to.id, msg.from.id) then
          return "هاذا الامر متاح للـ (العضوية الذهبية⚜) فقط.☑️"
        end
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.match(matches[2], '^%d+$') then
        return upmanager(receiver, matches[2], matches[2])
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'delsuper' then
      if not is_admin(msg) then
        if not is_spromoted(msg.to.id, msg.from.id) then
          return "هاذا الامر متاح للـ (العضوية الذهبية⚜) فقط.☑️"
        end
      end
      if not matches[2] and msg.reply_id then
        get_message(msg.reply_id, get_msg_callback, {get_cmd=get_cmd, receiver=receiver})
        return
      end
      if not matches[2] then
        return
      end
      if string.match(matches[2], '^%d+$') then
        return sdemote(receiver, matches[2], matches[2])
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'vipgold' then
      if not is_sudo(msg) then
        return ""
      end
      local member = string.gsub(matches[2], "@", "")
      channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
    end
    
    if matches[1] == 'unvipgold' then
      if not is_sudo(msg) then
        return ""
      end
      if string.match(matches[2], '^%d+$') then
        admin_demote(receiver, matches[2], matches[2])
      else
        local member = string.gsub(matches[2], "@", "")
        channel_get_users(receiver, channel_username_id, {get_cmd= get_cmd, receiver=receiver, member=member})
      end
    end
    
    if matches[1] == 'listvip' then
      if not is_sudo(msg) then
        return ""
      end
      return admin_list(msg)
    end
    
    if matches[1] == 'chat_add_user' and msg.action.user.id == our_id then
      channel_kick_user(receiver, 'user#id'..our_id, ok_cb, true)
    end
  else
    return
  end
end

return {
  description = "Moderation plugin", 
  usage = {
      user = {
          "admin : List of moderators",
          },
      moderator = {
          "add <username> : Promote user as moderator by username",
          "add (on reply) : Promote user as moderator by reply",
          "del <username> : Demote user from moderator",
          "del (on reply) : demote user from moderator by reply",
          },
      admin = {
          "sadd <username> : Promote user as moderator leader by username",
          "sadd (on reply) : Promote user as moderator leader by reply",
          "sdel <username> : Demote user from being moderator leader by username",
          "sdel (on reply) : Demote user from being moderator leader by reply",
          },
      sudo = {
          "pro <username> : Promote user as admin (must be done from a group)",
          "dem <username> : Demote user from admin (must be done from a group)",
          "dem <id> : Demote user from admin (must be done from a group)",
          },
      },
  patterns = {
    "^(sadd) @(.*)$",
    "^(sadd)$",
    "^(sdel) @(.*)$",
    "^(sdel)$",
    "^(add) @(.*)$",
    "^(add)$",
    "^(del) @(.*)$",
    "^(del)$",
    "^(admin)$",
    
    "^/(sadd) @(.*)$",
    "^/(sadd)$",
    "^/(sdel) @(.*)$",
    "^/(sdel)$",
    "^/(add) @(.*)$",
    "^/(add)$",
    "^/(del) @(.*)$",
    "^/(del)$",
    "^/(addsuper) @(.*)$",
    "^/(addsuper)",
    "^/(delsuper) @(.*)$",
    "^/(delsuper)",
    "^/(admin)$",
    "^/(vipgold) @(.*)$", -- sudoers only
    "^/(unvipgold) @(.*)$", -- sudoers only
    "^/(listvip)$",
    "^!!tgservice (chat_add_user)$",
    "^!!tgservice (chat_created)$",
  }, 
  run = run,
}

end
