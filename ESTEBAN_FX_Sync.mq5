//+------------------------------------------------------------------+
//|                                          ESTEBAN_FX_Sync.mq5     |
//|                 Versión mejorada - Compatible con nuevas claves  |
//+------------------------------------------------------------------+
#property copyright "ESTEBAN FX"
#property version   "1.10"
#property strict

input string   SupabaseURL   = "https://mnlolmyxvnjwycbusnky.supabase.co";
input string   SupabaseKey   = "sb_publishable_Xf_wFAH_REGOvr8M0yjLVQ_dYmO7NOT";
input int      UpdateSeconds = 4;

datetime lastUpdate = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   Print("ESTEBAN FX Sync v1.10 iniciado");
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
}

//+------------------------------------------------------------------+
void OnTimer()
{
   if(TimeCurrent() - lastUpdate >= UpdateSeconds)
   {
      SyncPositions();
      lastUpdate = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
void OnTrade()
{
   SyncPositions();
   lastUpdate = TimeCurrent();
}

//+------------------------------------------------------------------+
void SyncPositions()
{
   DeleteAll();

   int total = PositionsTotal();
   if(total == 0)
   {
      Print("No hay operaciones abiertas");
      return;
   }

   int enviadas = 0;
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      string symbol     = PositionGetString(POSITION_SYMBOL);
      long   type       = PositionGetInteger(POSITION_TYPE);
      double volume     = PositionGetDouble(POSITION_VOLUME);
      double openPrice  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl         = PositionGetDouble(POSITION_SL);
      double tp         = PositionGetDouble(POSITION_TP);
      double current    = PositionGetDouble(POSITION_PRICE_CURRENT);
      double profit     = PositionGetDouble(POSITION_PROFIT);
      double swap       = PositionGetDouble(POSITION_SWAP);
      long magic        = PositionGetInteger(POSITION_MAGIC);

      string typeStr = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

      string json = "{";
      json += "\"ticket\":" + IntegerToString(ticket) + ",";
      json += "\"symbol\":\"" + symbol + "\",";
      json += "\"type\":\"" + typeStr + "\",";
      json += "\"volume\":" + DoubleToString(volume, 2) + ",";
      json += "\"open_price\":" + DoubleToString(openPrice, digits) + ",";
      json += "\"sl\":" + DoubleToString(sl, digits) + ",";
      json += "\"tp\":" + DoubleToString(tp, digits) + ",";
      json += "\"current_price\":" + DoubleToString(current, digits) + ",";
      json += "\"profit\":" + DoubleToString(profit, 2) + ",";
      json += "\"swap\":" + DoubleToString(swap, 2) + ",";
      json += "\"magic\":" + IntegerToString(magic);
      json += "}";

      if(SendPosition(json))
         enviadas++;
   }

   Print("Posiciones sincronizadas: ", enviadas, " de ", total);
}

//+------------------------------------------------------------------+
bool SendPosition(string json)
{
   string url = SupabaseURL + "/rest/v1/open_positions";
   
   string headers = "Content-Type: application/json\r\n";
   headers += "apikey: " + SupabaseKey + "\r\n";
   headers += "Authorization: Bearer " + SupabaseKey + "\r\n";
   headers += "Prefer: return=minimal\r\n";

   char post[], result[];
   string responseHeaders;
   StringToCharArray(json, post, 0, WHOLE_ARRAY, CP_UTF8);

   int res = WebRequest("POST", url, headers, 8000, post, result, responseHeaders);

   if(res == 201 || res == 200)
      return true;
   else
   {
      string response = CharArrayToString(result);
      Print("Error al enviar. Código: ", res, " | ", response);
      return false;
   }
}

//+------------------------------------------------------------------+
void DeleteAll()
{
   string url = SupabaseURL + "/rest/v1/open_positions?ticket=gt.0";
   
   string headers = "Content-Type: application/json\r\n";
   headers += "apikey: " + SupabaseKey + "\r\n";
   headers += "Authorization: Bearer " + SupabaseKey + "\r\n";
   headers += "Prefer: return=minimal\r\n";

   char post[], result[];
   string responseHeaders;
   WebRequest("DELETE", url, headers, 5000, post, result, responseHeaders);
}
//+------------------------------------------------------------------+
