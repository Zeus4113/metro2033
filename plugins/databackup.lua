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
end
