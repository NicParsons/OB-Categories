--OB Categories
Myriad Tables Lib's make table command takes an initially selected rows parameter
but it is a list of integers representing the index of the row to be selected
whereas the input we have will be a list of integers representing the account ID to be selected
so we'll need to look at which row contains that account ID and return the index of that row
*)
this is a really dumb, inefficient and non-scalable way of solving this problem
but for now it's all I got so let's see how it goes and come up with a better idea if and when we can
*)
basically use the displayAccounts handler
but return a record 
and if the selected category has no child categories, then that's the one that gets returned
but as the user won't know whether or not a category he/she is selecting has child categories, it will have to be a prompt after the fact
e.g. do you want to select/return this category or cancel/go back/create subcategory
if it does have child categories, then display those
*)
if parentCategoryID is missing value then we only want accounts whose parent is null
*)
we want the name for each row where the id of that row does not appear at all in the parent column i.e. does not appear in any row in the parent column
*)

• function to delete categories
• selecting a category will display any child categories and a button to "Choose " & categoryName and another button to add a subcategory, if supported

*)