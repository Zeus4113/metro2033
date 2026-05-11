local PLUGIN = PLUGIN
PLUGIN.name = "Data Backup"
PLUGIN.author = "server"
PLUGIN.description = "Exports a JSON snapshot of all DB tables. Run 'ix_backup' from the server console."

if SERVER then
    concommand.Add("ix_backup", function(ply)
        if IsValid(ply) then return end

        local out = {}

        local function WriteBackup()
            local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
            local filename = "helix/metro2033/backup_" .. timestamp .. ".txt"
            file.Write(filename, util.TableToJSON(out, true))
            print("[Backup] Saved to data/" .. filename)
            print("[Backup] Players: " .. #out.players .. "  Characters: " .. #out.characters .. "  Inventories: " .. #out.inventories .. "  Items: " .. #out.items)
        end

        local q1 = mysql:Select("ix_players")
        q1:Callback(function(r1)
            out.players = r1 or {}

            local q2 = mysql:Select("ix_characters")
            q2:Callback(function(r2)
                out.characters = r2 or {}

                local q3 = mysql:Select("ix_inventories")
                q3:Callback(function(r3)
                    out.inventories = r3 or {}

                    local q4 = mysql:Select("ix_items")
                    q4:Callback(function(r4)
                        out.items = r4 or {}
                        WriteBackup()
                    end)
                    q4:Execute()
                end)
                q3:Execute()
            end)
            q2:Execute()
        end)
        q1:Execute()

        print("[Backup] Running... check console for completion.")
    end)

    -- ix_restore [filename]
    -- Omit filename to use the most recent backup.
    -- Add "list" as filename to see available backups.
    concommand.Add("ix_restore", function(ply, _, args)
        if IsValid(ply) then return end

        local filename = args[1]

        if filename == "list" then
            local found = file.Find("helix/metro2033/backup_*.txt", "DATA")
            if not found or #found == 0 then
                print("[Restore] No backup files found.")
            else
                table.sort(found)
                for _, f in ipairs(found) do
                    print("[Restore]  " .. f)
                end
            end
            return
        end

        if not filename then
            local found = file.Find("helix/metro2033/backup_*.txt", "DATA")
            if not found or #found == 0 then
                print("[Restore] No backup files found. Run ix_backup first.")
                return
            end
            table.sort(found)
            filename = found[#found]
            print("[Restore] No file specified — using latest: " .. filename)
        end

        if not filename:find("/", 1, true) then
            filename = "helix/metro2033/" .. filename
        end

        local raw = file.Read(filename, "DATA")
        if not raw then
            print("[Restore] Could not read data/" .. filename)
            return
        end

        local backup = util.JSONToTable(raw)
        if not backup or not backup.players then
            print("[Restore] Invalid or corrupt backup file.")
            return
        end

        print("[Restore] Source: data/" .. filename)
        print("[Restore] Players: " .. #backup.players .. "  Characters: " .. #backup.characters .. "  Inventories: " .. #backup.inventories .. "  Items: " .. #backup.items)
        print("[Restore] WARNING: All current data will be replaced. Starting in 5 seconds — restart now to cancel.")

        timer.Simple(5, function()
            -- Build and fire INSERT queries for every row in a table.
            -- Calls cb once all rows are done. Skips gracefully if table is empty.
            local function InsertRows(tblName, rows, cb)
                if not rows or #rows == 0 then cb() return end
                local done = 0
                for _, row in ipairs(rows) do
                    local cols, vals = {}, {}
                    for k, v in pairs(row) do
                        cols[#cols + 1] = "`" .. k .. "`"
                        if isnumber(v) then
                            vals[#vals + 1] = tostring(v)
                        else
                            vals[#vals + 1] = "'" .. mysql:Escape(tostring(v)) .. "'"
                        end
                    end
                    local q = mysql:Query("INSERT INTO `" .. tblName .. "` (" .. table.concat(cols, ",") .. ") VALUES (" .. table.concat(vals, ",") .. ")")
                    q:Callback(function()
                        done = done + 1
                        if done == #rows then cb() end
                    end)
                    q:Execute()
                end
            end

            -- Clear in reverse-dependency order, then re-insert in forward order.
            local q1 = mysql:Query("DELETE FROM `ix_items`")
            q1:Callback(function()
                local q2 = mysql:Query("DELETE FROM `ix_inventories`")
                q2:Callback(function()
                    local q3 = mysql:Query("DELETE FROM `ix_characters`")
                    q3:Callback(function()
                        local q4 = mysql:Query("DELETE FROM `ix_players`")
                        q4:Callback(function()
                            InsertRows("ix_players", backup.players, function()
                                InsertRows("ix_characters", backup.characters, function()
                                    InsertRows("ix_inventories", backup.inventories, function()
                                        InsertRows("ix_items", backup.items, function()
                                            print("[Restore] Complete! Restart the server.")
                                        end)
                                    end)
                                end)
                            end)
                        end)
                        q4:Execute()
                    end)
                    q3:Execute()
                end)
                q2:Execute()
            end)
            q1:Execute()
        end)
    end)
end
