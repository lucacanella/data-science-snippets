#----------- Open refine -----------
# @author: Luca Canella
#
# Jython ref link: http://www.jython.org/docs/index.html

# Map: (Python/Jython)
d = dict({ 1: "A", 2: "B", 3: "C", 4: "D" })
return d[cells["type"]["value"]]

# Regex: (Python/Jython)
import re
g = re.search(ur'<REGEX>', value)
return g

# Regex 2: (Python/Jython)
import re
rege = ur'(<regex_group>)'
va = row["cells"]["description"]["value"]
g = re.search(rege, va)
return g and len(g.group(1)) > 0 or 0

# Json: (Python/Jython)
import json
obj = json.loads(value)
return obj and obj["field"] or ""

# Datetime: (Python/Jython)
from datetime import datetime #import datetime
val = row["cells"]["update_date"]["value"] #take value from update_date cell
dt = datetime.strptime(val, "%Y-%m-%d %H:%M:%S") #parse from format "%Y-%m-%d %H:%M:%S"
return dt.strftime("%Y-%m-%d") #write to format "%Y-%m-%d"