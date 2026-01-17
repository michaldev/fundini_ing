function run(ctx)
  ctx.log("ING CSV importer start")

  local content = ctx.file and ctx.file.content or ""
  if content:gsub("%s+", "") == "" then
    return { transactions = {} }
  end

  local transactions = {}

  local function parse_number(v)
    if v == nil then return nil end
    local s = tostring(v):gsub("%s+", ""):gsub(",", ".")
    if s == "" then return nil end
    return tonumber(s)
  end

  local function parse_datetime(v)
    if v == nil then return nil end
    local d, m, y, hh, mm, ss =
      tostring(v):match("(%d%d)%-(%d%d)%-(%d%d%d%d)%s+(%d%d):(%d%d):(%d%d)")
    if not d then return nil end
    return string.format("%s-%s-%sT%s:%s:%sZ", y, m, d, hh, mm, ss)
  end

  local function split(line)
    local t = {}
    for part in line:gmatch("([^;]+)") do
      table.insert(t, part)
    end
    return t
  end

  for line in content:gmatch("[^\r\n]+") do
    local cols = split(line)

    if #cols >= 9 then
      local trade_datetime = parse_datetime(cols[1])
      local instrument_name = cols[3]
      local side_raw = cols[4]
      local units = parse_number(cols[5])
      local price = parse_number(cols[6])
      local fee = parse_number(cols[8])
      local total = parse_number(cols[9])

      if trade_datetime and instrument_name and units and price then
        local side =
          side_raw == "Kupno" and "buy" or
          side_raw == "Sprzedaż" and "sell" or nil

        if side then
          table.insert(transactions, {
            ticker = "",
            trade_datetime = trade_datetime,
            side = side,
            units = units,

            instrument_currency = "PLN",
            price_instrument = price,
            fx_rate = nil,

            price_portfolio = price,
            total_portfolio = total,
            fee_portfolio = fee,
            tax_portfolio = 0,

            note = cols[2] or nil,

            import_name = instrument_name
          })
        end
      end
    end
  end

  ctx.log("Transactions created: " .. tostring(#transactions))

  return {
    transactions = transactions
  }
end
