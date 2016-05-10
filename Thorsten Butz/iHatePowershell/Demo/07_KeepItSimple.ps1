$number07 = {
  'KEEP IT SIMPLE'  
}

# Array syntax
Get-Process | Where-Object { $_.WS -gt 40MB} | Sort-Object -Property WS -Descending 
ps | ?  { $_.WS -gt 40MB }  | sort WS -des 

# PSv3: PSITEM
Get-Process | where { $PSITEM.WS -gt 40MB } | sort WS -Descending 

# PSv3: Simplified syntax
Get-Process | where WS -gt 40MB | sort WS -Descending 
ps | ?  WS -gt 40MB  | sort WS -des 

# Multiple conditions
Get-Process | Where-Object { $_.WS -gt 40MB -and $_.Handles -gt 500 } | Sort-Object -Property WS, Handles -Descending

# This WON'T work:
# ps | ?  WS -gt 40MB  -and Handles -gt 500 | sort WS,Handles -des 
