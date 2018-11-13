#----------- Open refine -----------
# @author: Luca Canella
#
# Jython ref link: http://www.jython.org/docs/index.html
#


#######################################
# Map: 
# Map values (ie. convert keys into labels)
# (Python/Jython)
d = dict({ 1: "A", 2: "B", 3: "C", 4: "D" }) #create a map (dictionary)
return d[cells["type"]["value"]] #return mapped value


#######################################
# Regex - search: 
# Search pattern
# (Python/Jython)
import re
g = re.search(ur'<REGEX>', value)
return g != None


#######################################
# Regex 2 - pattern extraction:
# Search pattern on another column and export a group
# (Python/Jython)
import re
rege = ur'(<regex_group>)' #regex string
va = row["cells"]["description"]["value"] #get a column in this row
g = re.search(rege, va) #search for regex in cell
return g and len(g.group(1)) > 0 or 0 #return 1 if matched, hence group1 exists and is non empty, or return 0.


#######################################
# Regex 3 - substitution:
# Substitution
# (Python/Jython)
import re
rex = re.compile("<regex_for_substitution>")
return rex.sub("<substitution_value>", value)


#######################################
# Json:
# Parse json value and export a single field
# (Python/Jython)
import json
obj = json.loads(value) # parse json
return obj and obj["field"] or "" #return single field or empty string


#######################################
# Datetime: 
# parse date string and format again with another format 
# (Python/Jython)
from datetime import datetime #import datetime
val = row["cells"]["update_date"]["value"] #take string value from "update_date" cell
dt = datetime.strptime(val, "%Y-%m-%d %H:%M:%S") #parse from format "%Y-%m-%d %H:%M:%S"
return dt.strftime("%Y-%m-%d") #write to format "%Y-%m-%d"
#as an alternative use dt.isoformat() to print as iso format 2018-01-24T16:52:06Z


#######################################
# List/CSV: 
# parse multiple values within a cell (encoded as csv), and filter them out depending a value within another cell 
#(Python/Jython)
ref_value = cells["<column_name>"]["value"] #get a reference value from another cell
values_l = value.split("<delimiter>") #split values within this cell
valuesOk = list() #this will be the final list of values (filtered)
for i in values_l: #for each value encoded in the current cell...
  if i != ref_value: #if the current value is different from the reference value...
    valuesOk.append(i) #...append the value to the final list
return "<delimiter>".join(valuesOk) #re-encode values and return
#This procedure filters out values from a csv field when single values are equal to another value in the record.


#######################################
# List/CSV/Duplicates: 
# parse multiple values within a cell (encoded as csv), remove duplicates, rejoin
#(Python/Jython)
delimiter = "<delimiter>"
values_l = value.split(delimiter) #split values within this cell
valuesOk = set(values_l) #this will be the final set of values: since it's a set it doesn't contain dups
return delimiter.join(valuesOk)


#######################################
# List/CSV clean: 
# split string by delimiter (','), remove empty values and strip trailing whitespace, then join again.
# (Python/Jython)
if value != None and len(value) > 0:
  lstV = filter(None, value.split(',')) #split and remove null values
  clean = [x.strip(' \t') for x in lstV] #remove trailing whitespace (spaces and tabs)
  return ','.join(clean) #join again
else:
  return None


#######################################
# Text:
# First letter uppercase 
# (Python/Jython)
return value[0].upper() + value[1:]


#######################################
# HTML:
# Parse HTML with custom parser to strip unsupported tags or map map them to supported version.
# (Python/Jython)

#Imports
from HTMLParser import HTMLParser

# Definition of a custom html parser
class MyHTMLParser(HTMLParser):
  supported_tags = [ "b", "i" ] # list of supported tags
  result = [] # the result
  #Handles start tags
  def handle_starttag(self, tag, attrs):
    if tag in self.supported_tags:
      self.result.append("&lt;"+tag+"&gt;")
    if tag == "br": #convert different br sintax to a common version
      self.result.append("&lt;br&gt;")
    if tag == "em": #convert em tags to i
      self.result.append("&lt;i&gt;")
    if tag == "strong": #convert strong tags to b
      self.result.append("&lt;b&gt;")
  #Handles end tags
  def handle_endtag(self, tag):
    if tag in self.supported_tags:
      self.result.append("&lt;/"+tag+"&gt;")
    if tag == "em":
      self.result.append("&lt;/i&gt;")
    if tag == "strong":
      self.result.append("&lt;/b&gt;")
  #Handles tags data (content)
  def handle_data(self, data):
    s_data = data.replace("&lt;br&gt;&lt;br&gt;", "&lt;br&gt;") #remove duplicate br tags
    self.result.append(s_data)
  #Returns the result
  def get_res(self):
    return ''.join(self.result) #join results into a single result string

parser = MyHTMLParser() # create parser instance
parser.feed(value) #feed html string to parser
parser.close() #close the parser
return parser.get_res() #get parsed results


#######################################
# Hashing/MD5:
# Create a base64 encoded md5 hash (ie. to use as key), using different record properties
# (Python/Jython)

import base64
import md5

m = md5.new() # create new md5 object
m.update(cells["field1"]["value"]) #add "field1" value for digest
m.update(cells["field2"]["value"]) #add "field2" value for digest
m.update(cells["field3"]["value"]) #add "field3" value for digest


#######################################
# Hashing/SHA256:
# Digest 3 times and create hex output of a salted string
# (Python/Jython)

import hashlib
mainValue = cells["celltohash"]["value"]
salt1 = '<salt1>'
salt2 = '<salt2>'
keystr = salt1 + mainValue + salt2
shaIter1 = hashlib.sha256(keystr).hexdigest()
shaIter2 = hashlib.sha256(shaIter1 ).hexdigest()
shaIter3 = hashlib.sha256(shaIter2 ).hexdigest()
return shaIter3


### Warning: md5 may raise a "UnicodeEncodeError" if some 
### unicode characters are found in the fields for digest.
### Please watch for errors (handle by Facet by Error).

#digest and base64 encode
return base64.b64encode(m.digest())


#######################################
# Web/check urls:
# Checks urls response
# (Python/Jython)

import urllib2, base64

request = urllib2.Request(value)
base64string = base64.b64encode('%s:%s' % ('_user_', '_password_'))
request.add_header("Authorization", "Basic %s" % base64string)
req = urllib2.urlopen(request)
if req:
    return req.getcode()
    #return req.read()
else:
    return None


#######################################
# Web/Download image:
# Download files (images)
# (Python/Jython)

import urllib2, urlparse, os

imgUrl = value #set image url here
localbasedir = './tmp/' #set here local base directory
headers = {} #additional headers here

if imgUrl != None and len(imgUrl) > 0:
    
    uparsed = urlparse.urlparse(imgUrl) #extract basename
    fname = os.path.basename(uparsed.path)
    localFname = os.path.realpath(os.path.join(localbasedir, fname))
    
    imgRequest = urllib2.Request(imgUrl, headers=headers) #read image from url
    imgData = urllib2.urlopen(imgRequest).read()
	 
    output = open(localFname,'wb') #write file locally
    output.write(imgData)
    output.close()
    
    return localFname
else:
    return ""


#######################################
# Web/Check response status:
# Make a request to a single url and output response status.
# (Python/Jython)

import urllib2, urlparse, os

resUrl = value #set url here
headers = {} #additional headers here

if resUrl != None and len(resUrl) > 0:
    resRequest = urllib2.Request(resUrl, headers=headers) #make url request
    res = urllib2.urlopen(resRequest)
    res.close()
    return res.getcode()
else:
    return ""


#######################################
# Cross/Join:
# Get by key all values across rows on another project, then join them in a new column.
# (GREL)

# cross(string projectName, string columnName) -> Gets all rows that have the same value for "columnName" from another project.
# forNonBlank(expression o, variable v, expression eNonBlank, expression eBlank) -> handles rows, whether they are blank (cross hasn't returned a reference) or not.
forEach(cell.cross("<Project name>", "<Key Field>"), r, forNonBlank(r.cells["<Column to merge>"].value,v,v,"")).join("|")


#######################################
# HTML/Validate:
# Grossly validate HTML structure identifying unclosed tags.
# The procedure returns a comma separated list of tags that aren't matching.
# When an empty string is returned the html structure should be ok.
# (Python/Jython)

#Imports
from HTMLParser import HTMLParser

cell_value = cells["Content"]["value"]
# Definition of a custom html parser
class MyHTMLParser(HTMLParser):
  open_tags = []
  errors = []
  #Handles start tags
  def handle_starttag(self, tag, attrs):
    self.open_tags.append(tag)
  #Handles end tags
  def handle_endtag(self, tag):
    last_closed = self.open_tags.pop()
    if last_closed != tag:
      self.errors.append(tag)
  #Handles tags data (ignores content)
  def handle_data(self, data):
    pass
  #Returns wether an error has occurred or not
  def get_res(self):
    return u",".join(self.errors)


parser = MyHTMLParser() # create parser instance
parser.feed(cell_value) #feed html string to parser
parser.close() #close the parser
return parser.get_res() #get parsed results


#####################################
# HTML/Validate v2:
# Grossly validates HTML structure by matching starting and closing tags.
# If an error is found the parser returns a string with the structure of the HTML (tags without content for debug purposes).
# When an empty string is returned the html structure should be ok.
# (Python/Jython)
from HTMLParser import HTMLParser

cell_val = cells["Content"]["value"]

# Definition of a custom html parser
class MyHTMLParser(HTMLParser):
	errors = 0
	tagstack = []
	structr = []
	depth = 0
	#Handles start tags
	def handle_starttag(self, tag, attrs):
		self.tagstack.append(tag)
		d = self.depth
		if len(self.structr) > 0 and ("<"+tag+">") != self.structr[-1]:
			tabs = "\r\n"
		else:
			tabs = ""
		while d > 0:
			tabs = tabs + "\t"
			d -= 1
		self.structr.append(tabs + "<"+tag+">")
		self.depth += 1
	#Handles end tags
	def handle_endtag(self, tag):
		last_tag = self.tagstack.pop()
		if len(tag) > 0 and last_tag != tag:
			self.errors += 1
		self.structr.append("</"+tag+">")
		self.depth -= 1
	#Ignores tag content
	def handle_data(self, data):
		pass
	#Returns the result
	def get_res(self):
		if self.errors > 0:
			return str(self.errors)+" errors\r\n"+( "".join(self.structr) )
		else:
			return ""

parser = MyHTMLParser() # create parser instance
parser.feed(cell_val) #feed html string to parser
parser.close() #close the parser
return parser.get_res() #get structure if there are errors


#####################################
# Text/GUID/Validate:
# Validates GUID sintax.
# (Python/Jython)
import re
return re.search("^[{(]?[0-9A-F]{8}[-]?([0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$", value, flags=re.IGNORECASE) != None

#####################################
# Text/Email/Validate:
# Validates Email sintax.
# WARNING: Could not match valid emails, or match invalid ones; please use at your own risk.
# (Python/Jython)
import re
return re.search("^([a-zA-Z0-9])([a-zA-Z0-9-_\+\.]*)@([a-zA-Z0-9])([a-zA-Z0-9-_\+\.]*)([a-zA-Z0-9])(\.)([a-zA-Z]{2,4})$", value) != None
