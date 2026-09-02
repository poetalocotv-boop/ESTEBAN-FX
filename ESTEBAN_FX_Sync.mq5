//+------------------------------------------------------------------+
//|                                          ESTEBAN_FX_Sync.mq5     |
//|                        Sincroniza operaciones abiertas a Supabase|
//|                        Compatible con Exness MT5                 |
//+------------------------------------------------------------------+
#property copyright "ESTEBAN FX"
#property version   "1.00"
#property strict

input string   SupabaseURL   = "https://mnlolmyxvnjwycbusnky.supabase.co";  // Project URL (sin /rest/v1)
input string   SupabaseKey   = "sb_publishable_Xf_wFAH_REGOvr8M0yjLVQ_dYmO7NOT"; // anon key
input int      UpdateSeconds = 3;     // Cada cuántos segundos actualiza
input bool     ClearOldData  = true;  // Borrar posiciones cerradas

datetime lastUpdate = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   Print("ESTEBAN FX Sync iniciado");
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
   // Actualiza inmediatamente cuando hay cambios en operaciones
   SyncPositions();
   lastUpdate = TimeCurrent();
}

//+------------------------------------------------------------------+
void SyncPositions()
{
   string json = "[";
   int total = PositionsTotal();
   
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
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      long magic        = PositionGetInteger(POSITION_MAGIC);
      
      string typeStr = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
      
      if(i > 0) json += ",";
      
      json += "{";
      json += "\"ticket\":" + IntegerToString(ticket) + ",";
      json += "\"symbol\":\"" + symbol + "\",";
      json += "\"type\":\"" + typeStr + "\",";
      json += "\"volume\":" + DoubleToString(volume, 2) + ",";
      json += "\"open_price\":" + DoubleToString(openPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + ",";
      json += "\"sl\":" + DoubleToString(sl, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + ",";
      json += "\"tp\":" + DoubleToString(tp, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + ",";
      json += "\"current_price\":" + DoubleToString(current, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + ",";
      json += "\"profit\":" + DoubleToString(profit, 2) + ",";
      json += "\"swap\":" + DoubleToString(swap, 2) + ",";
      json += "\"open_time\":\"" + TimeToString(openTime, TIME_DATE|TIME_SECONDS) + "\",";
      json += "\"magic\":" + IntegerToString(magic);
      json += "}";
   }
   json += "]";
   
   // Primero borramos todo (método simple y efectivo)
   if(ClearOldData)
   {
      DeleteAllPositions();
   }
   
   // Si no hay posiciones, solo borramos y salimos
   if(total == 0)
   {
      Print("No hay operaciones abiertas");
      return;
   }
   
   // Enviamos las posiciones nuevas
   string url = SupabaseURL + "/rest/v1/open_positions";
   string headers = "Content-Type: application/json\r\n";
   headers += "apikey: " + SupabaseKey + "\r\n";
   headers += "Authorization: Bearer " + SupabaseKey + "\r\n";
   headers += "Prefer: return=minimal\r\n";
   
   char post[], result[];
   string responseHeaders;
   StringToCharArray(json, post, 0, WHOLE_ARRAY, CP_UTF8);
   
   int res = WebRequest("POST", url, headers, 5000, post, result, responseHeaders);
   
   if(res == 201 || res == 200)
   {
      Print("Posiciones sincronizadas correctamente (", total, ")");
   }
   else
   {
      string response = CharArrayToString(result);
      Print("Error al sincronizar. Código: ", res, " | Respuesta: ", response);
   }
}

//+------------------------------------------------------------------+
void DeleteAllPositions()
{
   string url = SupabaseURL + "/rest/v1/open_positions?ticket=gt.0";
   string headers = "Content-Type: application/json\r\n";
   headers += "apikey: " + SupabaseKey + "\r\n";
   headers += "Authorization: Bearer " + SupabaseKey + "\r\n";
   headers += "Prefer: return=minimal\r\n";
   
   char post[], result[];
   string responseHeaders;
   
   // DELETE request
   int res = WebRequest("DELETE", url, headers, 5000, post, result, responseHeaders);
   
   if(res == 200 || res == 204)
   {
      // OK
   }
   else
   {
      Print("Error al limpiar posiciones antiguas. Código: ", res);
   }
}
//+------------------------------------------------------------------+
