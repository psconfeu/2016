This archive contains the PowerPoint deck and examples
from the talk I gave on using the Lucene.NET full text search 
engine with PowerShell. The directory contains two examples
which are very similar. One sample indexs all of the pages in
the PowerShell help then let's you interactively query the
index. The second example is similar but indexes the content
of the system event log. Both of the examples are written for
PowerShell version 5 and will not run as is on earlier versions
of PowerShell (although it shouldn't be too hard to make the
necessary modifications.)

No module is included because, frankly, the Lucene API is so
simple that adding a module only made things more complicated.

These examples are provided as with no implied warrantee or guarantees of
correctness (but I did try them out them :-)

NOTE: This archive contains the single Lucene .dll required to
run the examples. In general it is better to go to the Apache
Lucene.Net project to make sure you have the most up-to-date 
of the Lucene.NET code.

The main project page is: http://lucenenet.apache.org/

Documentation for the Lucene query language is available at
http://lucene.apache.org/core/3_5_0/queryparsersyntax.html
This is a very simple query language and should be easy to
understand and learn. The examples include some sample queries
for each of their respective data sets.

Regards,
Bruce Payette
