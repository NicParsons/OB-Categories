--OB Categories
if parentCategoryID is missing value then we only want accounts whose id is divisible by 1000 with no remainder
otherwise we need to get accounts whose id is within the range beginning with the first subcategory number and ending with the last subcategory number and if divided by the x value would leave a remainder of 0
*)

• function to choose category which returns the name and ID of the chosen category
• selecting a category will display any child categories and a button to "Choose " & categoryName and another button to add a subcategory, if supported
• function to return all childless categories i.e. categories that do not have any child/subcategories. Useful e.g. in finance app to select relevant account for a transaction.
• how to get the ID of a category from its name (assuming unique category names)
• escape category names before adding to db
• possibly enforce unique category names

*)