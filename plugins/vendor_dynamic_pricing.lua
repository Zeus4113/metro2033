local PLUGIN = PLUGIN

PLUGIN.name        = "Vendor Dynamic Pricing"
PLUGIN.author      = "metro2033"
PLUGIN.description = "Scales vendor buy prices based on stock level: low stock = higher price, high stock = lower price."

ix.config.Add("vendorPriceMax", 1.5, "Price multiplier applied at 0% stock (e.g. 2.0 = double price).", nil, {
    data = {min = 1.0, max = 10.0, decimals = 2},
    category = PLUGIN.name,
})

ix.config.Add("vendorPriceMin", 0.75, "Price multiplier applied at 100% stock (e.g. 0.5 = half price).", nil, {
    data = {min = 0.1, max = 1.0, decimals = 2},
    category = PLUGIN.name,
})

hook.Add("OnEntityCreated", "metroVendorDynamicPricing", function(ent)
    timer.Simple(0, function()
        if not IsValid(ent) or ent:GetClass() ~= "ix_vendor" then return end

        function ent:GetPrice(uniqueID, selling)
            local price = ix.item.list[uniqueID] and self.items[uniqueID] and
                self.items[uniqueID][VENDOR_PRICE] or
                (ix.item.list[uniqueID] and ix.item.list[uniqueID].price or 0)

            local data = self.items and self.items[uniqueID]
            local maxStock = data and data[VENDOR_MAXSTOCK]

            if not maxStock or maxStock <= 0 then
                if selling then return math.Round(price * (self.scale or 0.5)) end
                return price
            end

            local stock = data[VENDOR_STOCK] or 0
            local p = math.Clamp(stock / maxStock, 0, 1)

            local priceMax = ix.config.Get("vendorPriceMax", 2.0)
            local priceMin = ix.config.Get("vendorPriceMin", 0.5)

            -- Piecewise linear: priceMax at 0% -> 1.0 at 50% -> priceMin at 100%
            local multiplier
            if p <= 0.5 then
                multiplier = priceMax + (1 - priceMax) * 2 * p
            else
                multiplier = 1 + (priceMin - 1) * 2 * (p - 0.5)
            end

            if selling then
                return math.max(1, math.Round(price * multiplier * (self.scale or 0.5)))
            end

            return math.max(1, math.Round(price * multiplier))
        end
    end)
end)
