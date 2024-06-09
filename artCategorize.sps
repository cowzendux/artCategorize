* Encoding: UTF-8.
* Python function to create artificial categories from a continuous variable
* Written by Jamie DeCoster

* The function takes three parameters. 
* The first parameter is the name of the original continuous variable.
* The second parameter is the number of categories you want to create.
* The third is an optional parameter indicating the name of the category variable

* If your data has ties, some of the groups will have more cases than
* others depending on how many ties there were at the cut points.

* Sometimes you get more even groups when you include the cutpoint in
* the lower group, and sometimes you get more even groups when you include
* the cutpoint in the upper group. This function tries both and uses whichever
* method gives more even groups. The value labels of the categorical variable
* will tell you exactly how the cutpoints were handled.

set printback=off.
begin program python3.
def artCategorize(invar, catnum, outvar = None):
    #######
    # Obtain cutpoints
    #######
    cmd = """FREQUENCIES VARIABLES=%s
      /FORMAT=NOTABLE
      /NTILES=%s
      /ORDER=ANALYSIS.""" %(invar, catnum)
    handle,failcode=spssaux.CreateXMLOutput(
        cmd,
        omsid="Frequencies",
        subtype="Statistics",
        visible=False)
    result=spssaux.GetValuesFromXMLWorkspace(
        handle,
        tableSubtype="Statistics",
        cellAttrib="text")
    cutlist = []
    cutcount = 1
    while (cutcount < len(result) - 1):
        cutcount = cutcount + 1
        cutlist.append(result[cutcount])

    #########
    # Create new artificially categorized variable
    #########
    # Always a question as to whether cutpoints go into upper or lower category
    # Trying both and going with whichever gives more even groups

    # Define cutpoint variables
    submitstring = "numeric cat6294029_ac cat6294029_acl cat6294029_acu (f8.0)."
    spss.Submit(submitstring)

    # Putting cutpoint into lower category
    catname = "cat6294029_acl"
    submitstring = """RECODE %s
(Lowest thru %s=1)
""" %(invar, cutlist[0])
    for t in range(len(cutlist)-1):
        submitstring = submitstring + """(%s thru %s=%s)
""" %(str(cutlist[t]), str(cutlist[t+1]), str(t+2))
    submitstring = submitstring + """(%s thru Highest=%s) INTO %s.
execute.""" %(str(cutlist[len(cutlist)-1]), str(len(cutlist)+1), catname)
    spss.Submit(submitstring)
    
    # Putting cutpoint into upper category
    catname = "cat6294029_acu"
    submitstring = """RECODE %s""" %(invar)
    submitstring = submitstring + """
(%s thru Highest=%s)
""" %(str(cutlist[len(cutlist)-1]), str(len(cutlist)+1))

    for t in range(len(cutlist)-1):
        submitstring = submitstring + """(%s thru %s=%s)
""" %(str(cutlist[t]), str(cutlist[t+1]), str(t+2))
    submitstring = submitstring + """(Lowest thru %s=1)  INTO %s.
execute.""" %(cutlist[0], catname)
    spss.Submit(submitstring)
    
    # Calculating the sum of squares of the % in each group
    # Smaller ss of the % = more even categories

    # Exclude missing values
    submitstring = """USE ALL.
COMPUTE filter_$=(not missing(%s)).
FILTER BY filter_$.
EXECUTE.""" %(invar)

    # Get percentages
    catvars = ["cat6294029_acl", "cat6294029_acu"]
    sumsofsquares = []
    for var in catvars:
        cmd = """FREQUENCIES VARIABLES=%s
/ORDER=ANALYSIS.""" %(var)
        handle,failcode=spssaux.CreateXMLOutput(
            cmd,
            omsid="Frequencies",
            subtype="Frequencies",
            visible=False)
        result=spssaux.GetValuesFromXMLWorkspace(
            handle,
            tableSubtype="Frequencies",
            colCategory = "Percent",
            cellAttrib="text")
 
        # Mean is always 100/number of categories
        meanperc = 100/catnum

        # Dropping last number (always 100)
        result = result[:len(result)-1]

        # Calculate sum of squares
        ss = 0
        for i in result:
            ss = ss + (float(i)-meanperc)**2
        sumsofsquares.append(ss)

    ######
    # Choose the better categorization
    ######
    catname = "cat6294029_ac"
    if (sumsofsquares[0] > sumsofsquares[1]):
        bestname = "cat6294029_acu"
    else:
        bestname = "cat6294029_acl"

    submitstring = """compute %s = %s.
variable labels %s 'Artificial categorization of %s'.""" %(catname, bestname, catname, invar)
    spss.Submit(submitstring)   

    # Assign value labels
    if (sumsofsquares[0] > sumsofsquares[1]):
        submitstring = """value labels %s
1 '%s < %s'""" %(catname, invar, cutlist[0])
        for t in range(len(cutlist)-1):
            submitstring = submitstring + """
%s '%s <= %s < %s'""" %(str(t+2), str(cutlist[t]), invar, str(cutlist[t+1]))
        submitstring = submitstring + """
%s '%s >= %s'.   
""" %(str(len(cutlist)+1), invar, str(cutlist[len(cutlist)-1]))
        spss.Submit(submitstring)
    else:
        submitstring = """value labels %s
1 '%s <= %s'""" %(catname, invar, cutlist[0])
        for t in range(len(cutlist)-1):
            submitstring = submitstring + """
%s '%s < %s <= %s'""" %(str(t+2), str(cutlist[t]), invar, str(cutlist[t+1]))
        submitstring = submitstring + """
%s '%s > %s'.   
""" %(str(len(cutlist)+1), invar, str(cutlist[len(cutlist)-1]))
        spss.Submit(submitstring)

    ######
    # Assign SPSS variable name
    ######
    if (outvar == None):
        finalName = invar[0:4] + "_ac"
    else:
        finalName = outvar
    submitstring = "rename variables (cat6294029_ac = {0}).".format(finalName)
    spss.Submit(submitstring)

    ####
    # Clean up
    ####
    submitstring = """execute.
delete variables %s %s.""" %(catvars[0], catvars[1])
    spss.Submit(submitstring)
end program python3.
set printback=on.

********
* Version History
********
* 2012-08-03 Created
* 2014-11-30 Corrected value labels
* 2023-01-31 Removed noJunk
*    Added outvar argument
*    Renamed variable to invar
* 2023-06-24 Converted to Python3
