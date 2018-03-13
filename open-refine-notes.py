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
