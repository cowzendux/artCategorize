#artCategorize

SPSS Python Extension function to create categories by splitting a continuous variable

This function can be used to create median splits or other forms of artificial categorization based on a continuous variable. You can specify how many groups you want, and the program will do its best to create that many groups with approximately the same number of cases in each group. If your data has ties, some of the groups will have more cases than others depending on how many ties there were at the cut points. In this case, you sometimes get more even groups when you include the cutpoint in the lower group, and sometimes get more even groups when you include the cutpoint in the upper group. This function tries both and uses whichever method gives more even groups. The value labels of the categorical variable will tell you exactly how the cutpoints were handled. The name of the categorized variable will have the first 4 letters/characters of the original continuous variable followed by "_ac".

##Usage
**artCategorize(variable, catnum)**
* "variable" is a string variable providing the name of the continuous variable that will form the basis of the categorization. This argument is required.
* "catnum" is the number of levels you want in your artificial categorization. This argument is required.

**Example
**artCategorize("age", 4)**
* This would create a variable named "age_ac" that would have 4 different levels, corresponding to 4 different age groups. These groups will be chosen in a way to make them as even as possible.
