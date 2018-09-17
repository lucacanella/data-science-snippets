#----------- Open refine -----------
# @author: Luca Canella
#
# Jython ref link: http://www.jython.org/docs/index.html
#

# Map: (Python/Jython)
d = dict({ 1: "A", 2: "B", 3: "C", 4: "D" }) #create a map (dictionary)
return d[cells["type"]["value"]] #return mapped value

# Regex: (Python/Jython)
import re
g = re.search(ur'<REGEX>', value)
return g

# Regex 2: (Python/Jython)
import re
rege = ur'(<regex_group>)' #regex string
va = row["cells"]["description"]["value"] #get a column in this row
g = re.search(rege, va) #search for regex in cell
return g and len(g.group(1)) > 0 or 0 #return 1 if matched, hence group1 exists and is non empty, or return 0.

# Regex 3: (Python/Jython)
import re
rex = re.compile("<regex_for_substitution>")
return rex.sub("<substitution_value>", value)

# Json: (Python/Jython)
import json
obj = json.loads(value) # parse json
return obj and obj["field"] or "" #return single field or empty string

# Datetime: (Python/Jython)
from datetime import datetime #import datetime
val = row["cells"]["update_date"]["value"] #take value from update_date cell
dt = datetime.strptime(val, "%Y-%m-%d %H:%M:%S") #parse from format "%Y-%m-%d %H:%M:%S"
return dt.strftime("%Y-%m-%d") #write to format "%Y-%m-%d"
#as an alternative use dt.isoformat() to print as iso format 2018-01-24T16:52:06Z

#parse multiple values within a cell (encoded as csv), and filter them out depending a value within another cell (Python/Jython)
ref_value = cells["<column_name>"]["value"] #get a reference value from another cell
values_l = value.split("<delimiter>") #split values within this cell
valuesOk = list() #this will be the final list of values (filtered)
for i in values_l: #for each value encoded in the current cell...
  if i != ref_value: #if the current value is different from the reference value...
    valuesOk.append(i) #...append the value to the final list
return "<delimiter>".join(valuesOk) #re-encode values and return
#This procedure filters out values from a csv field when single values are equal to another value in the record.

# List/CSV clean: (Python/Jython)
# split string by delimiter (','), remove empty values and strip trailing whitespace, then join again.
lstV = filter(None, value.split(',')) #split and remove null values
clean = [x.strip(' \t') for x in lstV] #remove trailing whitespace (spaces and tabs)
return ','.join(clean) #join again

# First letter uppercase: (Python/Jython)
return value[0].upper() + value[1:]


