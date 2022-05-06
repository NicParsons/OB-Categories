-- <script library>true</script library>
--OB Categories
--	Created by: Nicholas Parsons
--	Created on: 5/10/20, v2 on 18 July 2021
--
--	Copyright © 2020 Nicholas Parsons, All Rights Reserved
--

use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "SQLite Lib2"
use script "Myriad Tables Lib"
use OBUtility : script "OB Utilities"
use OBData : script "OB Data"

property name : "OB Categories v2"
property id : "com.OpenBooksApp.OBCategories"
property version : "2.0"
property primaryBaseForAccountCategoryIDs : 10000000
property categoryMod : 100

on displayCategories for thisDB given tableName:tableName as text : "accounts", title:defaultTitle as text : "Categories", prompt:thePrompt as text : "Select a category.", editableColumns:editableColumns as list : {1}, columnHeader:columnHeader as text : "Category", initialPosition:initialPosition : missing value
	try
		doOBLog of OBUtility for "displayCategories handler called from OB Categories library" given logType:"debug"
		set headerRow to {columnHeader, "ID"}
		set columnFormats to {text, missing value}
		set parentCategoryID to missing value
		repeat
			try
				repeat
					doOBLog of OBUtility for "displaying accounts with the parent account " & parentCategoryID given logType:"debug"
					try -- because the following line will throw an error if there are no and can be no subcategories of this parent category
						set tableData to getAccounts from thisDB given parentCategoryID:parentCategoryID, tableName:tableName
					on error errorMessage number 1000 -- this parent category can have no subcategories
						doOBLog of OBUtility for errorMessage & " Error number 1000" given logType:"error"
						display alert errorMessage
						set parentCategoryID to parentCategory for parentCategoryID given db:thisDB, tableName:tableName
						set tableData to getAccounts from thisDB given parentCategoryID:parentCategoryID, tableName:tableName
					end try
					if parentCategoryID is missing value then
						set itsTitle to defaultTitle
						set cancelButtonName to "Done"
					else
						set itsTitle to defaultTitle & ": " & (categoryName for parentCategoryID given db:thisDB)
						set cancelButtonName to "Back"
					end if -- parentCategoryID is missing value
					set theTable to make new table with data tableData with title itsTitle with prompt thePrompt column headings headerRow row template columnFormats editable columns editableColumns with empty selection allowed
					modify table theTable OK button name "Select" cancel button name cancelButtonName extra button name "Add" initial position initialPosition
					
					try
						set theResult to display table theTable with extended results
					on error number -128
						if parentCategoryID is missing value then
							doOBLog of OBUtility for "user cancelled" given logType:"debug"
							error number -128
						else
							set parentCategoryID to parentCategory for parentCategoryID given db:thisDB, tableName:tableName
							exit repeat
						end if -- parentCategoryID is missing value
					end try
					
					set initialPosition to final position of theResult
					
					if button number of theResult is 2 then -- user chose add
						doOBLog of OBUtility for "user chose to add new category" given logType:"debug"
						try
							promptUserForNewCategoryName for tableName given db:thisDB, parentCategoryID:parentCategoryID
						on error errorMessage number errorNumber
							doOBLog of OBUtility for errorMessage & " Error number " & errorNumber given logType:"error"
							display alert "Sorry, we were unable to add your new category" message errorMessage
						end try
						-- go back to the main menu
						
					else if button number of theResult is 1 then
						-- #todo: process any edits to the category names
						-- display the subcategories for the selected category
						if values selected of theResult is {} then
							display alert "Nothing was selected"
						else -- a category was selected
							doOBLog of OBUtility for "user chose " & the first item of the first item of values selected of theResult given logType:"debug"
							set parentCategoryID to the last item of the first item of values selected of theResult
						end if -- no category was selected
					end if -- button selected
				end repeat
			on error number -128
				exit repeat
			end try
		end repeat
	on error errorMessage number errorNumber
		doOBLog of OBUtility for errorMessage & " Error number " & errorNumber given logType:"error"
		error errorMessage number errorNumber
	end try
	return initialPosition
end displayCategories

on chooseChildCategory from thisDB given tableName:tableName as text : "accounts", prompt:thePrompt as text : "Choose an account.", title:thisTitle as text : "Choose Account", OKButtonName:OKButtonName as text : "Choose", cancelButtonName:cancelButtonName as text : "Cancel", backButton:backButton as boolean : false, backButtonName:backButtonName as text : "Back", stepCount:theStep as integer : 0, initiallySelectedRows:initiallySelectedRows as list : {}, initialPosition:initialPosition : missing value, newAccountsAllowed:newAccountsAllowed as boolean : false, sortMethod:sortMethod as text : "name asc", hiddenAccounts:hiddenAccounts as boolean : true
	doOBLog of OBUtility for "chooseChildCategory handler called from OB Categories library" given logType:"debug"
	set functionResult to {accountID:missing value, accountName:missing value, stepCount:theStep, userCancelled:false, userChoseBack:false, finalPosition:initialPosition}
	set theData to getChildAccounts from thisDB given tableName:tableName, hiddenAccounts:hiddenAccounts, sortMethod:sortMethod
	if initiallySelectedRows is not {} then set initiallySelectedRows to convertInitiallySelectedRows from initiallySelectedRows given tableData:theData
	if newAccountsAllowed then set the end of theData to {"Add new", missing value}
	set headerRow to {"Account", "ID"}
	set columnFormats to {text, missing value}
	repeat -- until user makes valid selection
		set theTable to make new table with data theData with title thisTitle with prompt thePrompt column headings headerRow row template columnFormats initially selected rows initiallySelectedRows with double click means OK
		modify table theTable OK button name OKButtonName cancel button name cancelButtonName initial position initialPosition
		if backButton then modify table theTable extra button name backButtonName
		
		try
			set theResult to display table theTable with extended results
			set finalPosition of functionResult to final position of theResult
			if button number of theResult is 1 then
				set accountName of functionResult to the first item of the first item of values selected of theResult
				set accountID of functionResult to the last item of the first item of values selected of theResult
				set stepCount of functionResult to (stepCount of functionResult) + 1
				doOBLog of OBUtility for "user chose " & accountName of functionResult given logType:"debug"
				if accountID of functionResult is missing value then -- user chose to add new
					set theResult to addNewCategory to thisDB given tableName:tableName, initialPosition:finalPosition of functionResult
					if userCancelled of theResult then
						set userChoseBack of functionResult to true
						set stepCount of functionResult to (stepCount of functionResult) - 1
					else -- user added a new category
						set accountName of functionResult to accountName of theResult
						set accountID of functionResult to accountID of theResult
						exit repeat
					end if -- user added a new category
				else -- user made valid selection
					exit repeat
				end if -- user chose to add new
			else if button number of theResult is 2 then
				doOBLog of OBUtility for "user chose back" given logType:"debug"
				set userChoseBack of functionResult to true
				set stepCount of functionResult to (stepCount of functionResult) - 1
				exit repeat
			end if
		on error number -128
			doOBLog of OBUtility for "user cancelled" given logType:"debug"
			set userCancelled of functionResult to true
			exit repeat
		end try
	end repeat
	return functionResult
end chooseChildCategory

on chooseParentCategory from thisDB given tableName:tableName as text : "accounts", prompt:thePrompt as text : "Choose an account.", title:thisTitle as text : "Choose Account", OKButtonName:OKButtonName as text : "Choose", cancelButtonName:cancelButtonName as text : "Cancel", backButton:backButton as boolean : false, backButtonName:backButtonName as text : "Back", stepCount:theStep as integer : 0, initiallySelectedRows:initiallySelectedRows as list : {}, initialPosition:initialPosition : missing value, hiddenAccounts:hiddenAccounts as boolean : true
	set parentCategoryID to missing value
	(*
basically use the displayAccounts handler
but return a record 
and if the selected category has no child categories, then that's the one that gets returned
but as the user won't know whether or not a category he/she is selecting has child categories, it will have to be a prompt after the fact
e.g. do you want to select/return this category or cancel/go back/create subcategory
if it does have child categories, then display those
*)
	try
		doOBLog of OBUtility for "displaying list of parent categories for the user to choose" given logType:"debug"
		set functionResult to {accountID:missing value, accountName:missing value, stepCount:theStep, userCancelled:false, userChoseBack:false, finalPosition:initialPosition}
		set theData to getParentAccounts from thisDB given tableName:tableName, hiddenAccounts:hiddenAccounts
		if initiallySelectedRows is not {} then set initiallySelectedRows to convertInitiallySelectedRows from initiallySelectedRows given tableData:theData
		set headerRow to {"Account", "ID"}
		set columnFormats to {text, missing value}
		set theTable to make new table with data theData with title thisTitle with prompt thePrompt column headings headerRow row template columnFormats initially selected rows initiallySelectedRows with double click means OK
		modify table theTable OK button name OKButtonName cancel button name cancelButtonName initial position initialPosition
		if backButton then modify table theTable extra button name backButtonName
		
		set theResult to display table theTable with extended results
		if button number of theResult is 1 then
			set accountName of functionResult to the first item of the first item of values selected of theResult
			set accountID of functionResult to the last item of the first item of values selected of theResult
			set stepCount of functionResult to (stepCount of functionResult) + 1
			doOBLog of OBUtility for "user chose " & accountName of functionResult given logType:"debug"
		else if button number of theResult is 2 then
			doOBLog of OBUtility for "user chose back" given logType:"debug"
			set userChoseBack of functionResult to true
			set stepCount of functionResult to (stepCount of functionResult) - 1
		end if
		set finalPosition of functionResult to final position of theResult
	on error errorMessage number errorNumber
		if errorNumber is -128 then
			doOBLog of OBUtility for "user cancelled" given logType:"debug"
			set userCancelled of functionResult to true
		else
			error errorMessage & " (thrown in the chooseParentCategory handler of OB Categories v2)" number errorNumber
		end if
	end try
	return functionResult
end chooseParentCategory

on makeCategoriesTable for thisDB given tableName:tableName as text : "accounts"
	doOBLog of OBUtility for "making new table for " & tableName given logType:"debug"
	tell OBData to makeTable(thisDB, tableName, "id integer primary key not null, name text not null, parent integer references " & tableName & "(ID), hidden integer not null default 0")
end makeCategoriesTable

on listAllCategoryNames from thisTableName : "accounts" given db:thisDB, tableFormatting:tableFormatting as boolean : false, hiddenAccounts:hiddenAccounts as boolean : true
	doOBLog of OBUtility for "getting list of all category names" given logType:"debug"
	if hiddenAccounts then
		set theNames to query db thisDB sql string "select distinct name from " & thisTableName & " order by name asc"
	else
		set theNames to query db thisDB sql string "select distinct name from " & thisTableName & " where hidden = 0 order by name asc"
	end if
	-- that will have returned a list of lists
	-- so theNames will be a list containing 0 or more lists each of which will contain one string item being the name
	if not tableFormatting and theNames is not {} then
		set theNames to extract column 1 from theNames
		doOBLog of OBUtility for "converted the list of accounts/categories/names into a single list" given logType:"debug"
	end if
	return theNames
end listAllCategoryNames

on getAccounts from thisDB given parentCategoryID:parentCategoryID : missing value, tableName:tableName as text : "accounts"
	(*
contrary to the function's name, this handler only returns the immediate children of the given parent account
it returns the name and id for each account in table form
*)
	doOBLog of OBUtility for "getting list of categories from " & tableName & " table where the parent category ID is " & parentCategoryID given logType:"debug"
	(*
	there are two possible methods of doing this
	one using the parent column, which is a simple sql query
	and the other using maths to do a slightly more complicated sql query
the second method will throw an error in the event that you try to get subcategories of an account that is already at the lowest level permitted
whereas the first method will probably just return missing value in such a situation
so for now I'll use the second maths method, but will keep the simpler method below commented out in case I want to deploy it later
*)
	(*
	if parentCategoryID is missing value then we only want accounts whose id is divisible by one-tenth of the primaryBaseForAccountCategoryIDs with no remainder
	otherwise we need to get accounts whose id is within the range beginning with the first subcategory number and ending with the last subcategory number and if divided by the x value would leave a remainder of 0
	*)
	if parentCategoryID is missing value then
		set theMod to primaryBaseForAccountCategoryIDs / 10
		set theData to query db thisDB sql string "select name, ID from " & tableName & " where ID %" & theMod & " = 0"
	else
		set {startValue, endValue, x} to returnIDRange for parentCategoryID given db:thisDB
		set theData to query db thisDB sql string "select name, ID from " & tableName & " where ID between " & startValue & " and " & endValue & " and ID % " & x & " = 0"
	end if
	-- this is the simpler method using the parent column
	(*
	if parentCategoryID is missing value then we only want accounts whose parent is null
	*)
	(*
		if parentCategoryID is missing value then
			set theData to query db thisDB sql string "select name, id from " & tableName & " where parent is null order by name asc"
		else
			set theData to query db thisDB sql string "select name, id from " & tableName & " where parent = " & parentCategoryID & " order by name asc"
		end if
	*)
	if theData is {} then set theData to {{}}
	return theData
end getAccounts

on getChildAccounts from thisDB given tableName:tableName as text : "accounts", sortMethod:sortMethod as text : "name asc", hiddenAccounts:hiddenAccounts as boolean : true
	doOBLog of OBUtility for "getting table data for all child accounts in the table " & tableName given logType:"debug"
	if sortMethod is not "" then set sortMethod to " order by " & sortMethod
	if hiddenAccounts then
		set theData to query db thisDB sql string "select name, id from " & tableName & " where id not in (select parent from " & tableName & " where parent is not null)" & sortMethod
	else
		set theData to query db thisDB sql string "select name, id from " & tableName & " where id not in (select parent from " & tableName & " where parent is not null) and hidden = 0" & sortMethod
	end if
	if theData is {} then set theData to {{}}
	return theData
end getChildAccounts

on getParentAccounts from thisDB given tableName:tableName as text : "accounts", hiddenAccounts:hiddenAccounts as boolean : true
	try
		doOBLog of OBUtility for "getting a table of all the parent accounts/categories" given logType:"debug"
		if hiddenAccounts then
			set theData to query db thisDB sql string "select name, ID from " & tableName & " where ID in (select distinct parent from " & tableName & ") order by ID asc"
		else
			set theData to query db thisDB sql string "select name, ID from " & tableName & " where ID in (select distinct parent from " & tableName & ") and hidden = 0 order by ID asc"
		end if
		if theData is {} then set theData to {{}}
	on error errorMessage number errorNumber
		error errorMessage & " (thrown in the getParentAccounts handler of OB Categories v2)" number errorNumber
	end try
	return theData
end getParentAccounts

on listChildCategoryNames from thisTableName : "accounts" given db:thisDB, tableFormatting:tableFormatting as boolean : false, sortMethod:sortString as string : "name asc", parentCategoryID:parentCategoryID as integer : missing value, hiddenAccounts:hiddenAccounts as boolean : true
	doOBLog of OBUtility for "getting list of names of all categories that do not have children" given logType:"debug"
	if hiddenAccounts then
		set hiddenAccountCondition to ""
	else
		set hiddenAccountCondition to " and hidden = 0"
	end if
	if parentCategoryID is missing value then
		-- we want the name for each row where the id of that row does not appear at all in the parent column i.e. does not appear in any row in the parent column
		set theNames to query db thisDB sql string "select distinct name from " & thisTableName & " where ID not in (select parent from " & thisTableName & " where parent is not null)" & hiddenAccountCondition & " order by " & sortString
	else -- we want the name for each row where its ID begins with the parentCategoryID and its id does not appear at all in the parent column
		set parentCategoryID to item 1 of (removeTrailingZeros from parentCategoryID)
		set theNames to query db thisDB sql string "select distinct name from " & thisTableName & " where cast(ID as string) like '" & (parentCategoryID as string) & "%' and ID not in (select parent from " & thisTableName & " where parent is not null)" & hiddenAccountCondition & " order by " & sortString
	end if
	if theNames is {} then
		doOBLog of OBUtility for "no child account/categories found" given logType:"debug"
	else if not tableFormatting then
		set theNames to extract column 1 from theNames
		doOBLog of OBUtility for "converted the list of accounts/categories/names into a single list" given logType:"debug"
	end if
	return theNames
end listChildCategoryNames

on listDescendantCategoryIDs of thisParentID given db:thisDB, tableName:tableName as text : "accounts", hiddenAccounts:hiddenAccounts as boolean : true
	try
		doOBLog of OBUtility for "getting a list of IDs for all descendant categories of account " & thisParentID given logType:"debug"
		set thisParentID to item 1 of (removeTrailingZeros from thisParentID)
		if hiddenAccounts then
			set theList to query db thisDB sql string "select ID from " & tableName & " where cast(ID as string) like '" & (thisParentID as string) & "%'"
		else
			set theList to query db thisDB sql string "select ID from " & tableName & " where cast(ID as string) like '" & (thisParentID as string) & "%' and hidden = 0"
		end if
		if theList is not {} then set theList to extract column 1 from theList
	on error errorMessage number errorNumber
		error errorMessage & " (thrown in the listDescendantCategoryIDs handler of OB Categories v2)" number errorNumber
	end try
	return theList
end listDescendantCategoryIDs

on listParentIDs from thisTableName given db:thisDB, hiddenAccounts:hiddenAccounts as boolean : true
	doOBLog of OBUtility for "getting list of all the IDs from the parent column of the " & thisTableName & " table" given logType:"debug"
	if hiddenAccounts then
		set theIDs to query db thisDB sql string "select distinct parent from " & thisTableName & " order by parent desc"
	else
		set theIDs to query db thisDB sql string "select distinct parent from " & thisTableName & " where hidden = 0 order by parent desc"
	end if
	if theIDs is not {} then set theIDs to extract column 1 from theIDs
	return theIDs
end listParentIDs

on addNewCategory to thisDB given tableName:tableName as text, initialPosition:initialPosition
	try
		set functionResult to {accountID:missing value, accountName:missing value, userCancelled:false, finalPosition:initialPosition}
		doOBLog of OBUtility for "adding a new category" given logType:"debug"
		set theResult to chooseParentCategory from thisDB given tableName:tableName, prompt:"Choose a parent category for your new account.", title:"New Account", initialPosition:initialPosition
		if userCancelled of theResult then error number -128
		set parentID to accountID of theResult
		set finalPosition of functionResult to finalPosition of theResult
		set theResult to promptUserForNewCategoryName for tableName given db:thisDB, parentCategoryID:parentID
		if theResult is missing value then error number -128
		set accountID of functionResult to accountID of theResult
		set accountName of functionResult to accountName of theResult
	on error errorMessage number errorNumber
		if errorNumber is -128 then
			set userCancelled of functionResult to true
		else
			error errorMessage & " (thrown in the addNewCategory handler of OB Categories v2)" number errorNumber
		end if
	end try
	return functionResult
end addNewCategory

on promptUserForNewCategoryName for thisTableName as text : "accounts" given db:thisDB, parentCategoryID:parentCategoryID
	try
		doOBLog of OBUtility for "prompting user to add a new category to " & thisTableName & " where the parent category ID is " & parentCategoryID given logType:"debug"
		set theResult to returnOBValue of OBUtility without backButton given prompt:"Enter the new category name.", title:"New Category"
		if userCancelled of theResult then return missing value
		set itsName to valueReturned of theResult
		set itsNewPK to addCategory to thisDB for thisTableName given parentCategoryID:parentCategoryID, itsName:itsName
	on error errorMessage number errorNumber
		error errorMessage & " (thrown in the promptUserForNewCategoryName handler of OB Categories v2)" number errorNumber
	end try
	return {accountName:itsName, accountID:itsNewPK}
end promptUserForNewCategoryName

on addCategory to thisDB for thisTableName as text : "accounts" given parentCategoryID:parentCategoryID, itsName:itsName as text, forcedUniqueness:forcedUniqueness as boolean : true, accountHidden:accountHidden as boolean : false
	doOBLog of OBUtility for "adding a new category called " & itsName & " to the " & thisTableName & " table with a parent category ID of " & parentCategoryID given logType:"debug"
	-- test to see if itsName is unique 
	if forcedUniqueness then
		set itsUnique to nameIsUnique for thisDB given nameToTest:itsName, tableName:thisTableName
		if itsUnique then
			doOBLog of OBUtility for "the name is unique" given logType:"debug"
		else
			error "There is already an account/category with the name “" & itsName & "”." number 1000
		end if -- it's unique
	end if -- forcedUniqueness
	-- we don't need to escape the string here because the insertRecord handler already escapes it
	set itsPK to newPK for thisDB given parentCategoryID:parentCategoryID, tableName:thisTableName
	if accountHidden then
		tell OBData to insertRecord for {itsPK, itsName, parentCategoryID, accountHidden} to thisTableName given db:thisDB, columns:"ID, name, parent, hidden"
	else
		tell OBData to insertRecord for {itsPK, itsName, parentCategoryID} to thisTableName given db:thisDB, columns:"ID, name, parent"
	end if
	return itsPK
end addCategory

on deleteCategory for thisAccountID from thisDB given tableName:thisTableName as text : "accounts"
	try
		doOBLog of OBUtility for "deleting account " & thisAccountID & " from " & thisTableName given logType:"debug"
		tell OBData to deleteRow from thisTableName given db:thisDB, PKName:"ID", PKID:thisAccountID
	on error errorMessage number errorNumber
		error errorMessage & " (thrown in the deleteCategory handler of OB Categories)" number errorNumber
	end try
end deleteCategory

on changeCategoryName of thisAccountID to newCategoryName as text given db:thisDB, tableName:thisTableName as text : "accounts", forcedUniqueness:forcedUniqueness as boolean : true
	try
		doOBLog of OBUtility for "changing the name of account " & thisAccountID & " to " & newCategoryName given logType:"debug"
		-- test to see if itsName is unique 
		if forcedUniqueness then
			set itsUnique to nameIsUnique for thisDB given nameToTest:newCategoryName, tableName:thisTableName
			if itsUnique then
				doOBLog of OBUtility for "the name is unique" given logType:"debug"
			else
				error "There is already an account/category with the name “" & newCategoryName & "”." number 1000
			end if -- it's unique
		end if -- forcedUniqueness
		tell OBData to updateTable for thisDB given tableName:thisTableName, PKName:"ID", PKID:thisAccountID, fieldName:"name", newValue:newCategoryName
	on error errorMessage number errorNumber
		error errorMessage & " (thrown in the changeCategoryName handler of OB Categories v2)" number errorNumber
	end try
end changeCategoryName

on nameIsUnique for thisDB given nameToTest:nameToTest, tableName:tableName as text : "accounts"
	doOBLog of OBUtility for "testing to see if the database already contains an account/category in the " & tableName & " table with the name " & nameToTest given logType:"debug"
	set nameToTest to escapeStringForSQL(nameToTest)
	set theResult to query db thisDB sql string "select * from " & tableName & " where name = '" & nameToTest & "'"
	return theResult is {}
end nameIsUnique

on categoryName for thisID given db:thisDB, tableName:tableName as text : "accounts"
	doOBLog of OBUtility for "getting the name of the category whose ID is " & thisID given logType:"debug"
	if thisID is missing value then error "No ID supplied. Can't get an account name whenif no ID is supplied." number 1000
	set theName to query db thisDB sql string "select name from " & tableName & " where id = " & thisID
	if theName is {} then error "Could not find an account that had an ID of " & thisID & "." number 1000
	set theName to the first item of the first item of theName
	doOBLog of OBUtility for "it’s " & theName given logType:"debug"
	return theName
end categoryName

on categoryID for thisName given db:thisDB, tableName:tableName as text : "accounts"
	doOBLog of OBUtility for "getting the ID of the account/category whose name is " & thisName given logType:"debug"
	set escapedName to escapeStringForSQL(thisName)
	set theID to query db thisDB sql string "select id from " & tableName & " where name = '" & escapedName & "'"
	if theID is {} then error "Could not find an account that had a name of " & thisName & "." number 1000
	return the first item of the first item of theID
end categoryID

on thereAreChildren of thisAccountID given db:thisDB, tableName:tableName as text : "accounts"
	try
		doOBLog of OBUtility for "testing to see if account " & thisAccountID & " has children" given logType:"debug"
		set listOfParentIDs to query db thisDB sql string "select parent from " & tableName
		if listOfParentIDs is not {} then set listOfParentIDs to extract column 1 from listOfParentIDs
	on error errorMessage number errorNumber
		error errorMessage & " (thrown in the thereAreChildren handler of OB Categories v2)" number errorNumber
	end try
	return listOfParentIDs contains thisAccountID
end thereAreChildren

on parentCategory for parentCategoryID given db:thisDB, tableName:tableName as text : "accounts"
	doOBLog of OBUtility for "getting the parent account/category for the account/category with the ID of " & parentCategoryID & " in the " & tableName & " table" given logType:"debug"
	set theID to query db thisDB sql string "select parent from " & tableName & " where id = " & parentCategoryID
	if theID is {} then
		set theID to missing value
	else
		set theID to the first item of the first item of theID
	end if
	return theID
end parentCategory

on firstSubcategoryID for thisID
	doOBLog of OBUtility for "getting the first subcategory ID for the parent category with ID of " & thisID given logType:"debug"
	set {subCategoryID, x} to removeTrailingZeros from thisID
	if x = 1 then error "Unable to create a subcategory for ID " & thisID & ". It would exceed the number of levels of subcategories supported." number 1000
	set subCategoryID to (subCategoryID * categoryMod) + 1
	set subCategoryID to (subCategoryID * x) / categoryMod
	doOBLog of OBUtility for "the subcategory ID is " & (subCategoryID as integer) given logType:"debug"
	return subCategoryID as integer
end firstSubcategoryID

on returnIDRange for thisParentCategoryID given db:thisDB
	doOBLog of OBUtility for "getting the range of IDs for account category " & thisParentCategoryID given logType:"debug"
	try -- because the following line might throw an error if there can be no subcategories for this parentCategoryID
		set startValue to firstSubcategoryID for thisParentCategoryID
	on error number 1000
		error "account “" & (categoryName for thisParentCategoryID given db:thisDB) & "” can have no subcategory accounts as subcategories at this level are not supported." number 1000
	end try
	try
		set {whoCares, x} to removeTrailingZeros from startValue
		set endValue to startValue + (categoryMod * x) - (2 * x)
		doOBLog of OBUtility for "the end value is " & endValue given logType:"debug"
	on error errorMessage number errorNumber
		error errorMessage & " (thrown in the returnIDRange handler of OB Categories)" number errorNumber
	end try
	return {startValue, endValue, x}
end returnIDRange

on nextIDAtSameLevel for thisID
	doOBLog of OBUtility for "getting the next ID at the same level as " & thisID given logType:"debug"
	set {newID, x} to removeTrailingZeros from thisID
	if (newID as text) ends with "99" then error "Unable to create another account category at this level. It would exceed the number of accounts supported at this level." number 1000
	set newID to newID + 1
	set newID to newID * x
	doOBLog of OBUtility for "the next ID in the specified category will be " & newID given logType:"debug"
	return newID
end nextIDAtSameLevel

on newPK for thisDB given parentCategoryID:parentCategoryID, tableName:tableName as text : "accounts"
	doOBLog of OBUtility for "deriving a new category primary key ID in the " & tableName & " table where the parent category ID is " & parentCategoryID given logType:"debug"
	-- first check whether there are any primary keys in the specified  category
	-- and, if there are, get the largest one
	if parentCategoryID is missing value then
		-- there's no parent and the category is the top level category
		set theMod to primaryBaseForAccountCategoryIDs / 10
		set thePK to query db thisDB sql string "select max(ID) from " & tableName & " where ID %" & theMod & " = 0"
		-- query on previous line will return {{missing value}} if there are no matching accounts
		set thePK to the first item of the first item of thePK
		if thePK is missing value then set thePK to 0
		doOBLog of OBUtility for "the largest primary key within the specified category is " & thePK given logType:"debug"
		set theNewPK to nextIDAtSameLevel for thePK
	else -- where creating a subcategory
		-- check to see whether there are any primary keys in this subcategory range and, if there are, get the largest
		set {startValue, endValue, x} to returnIDRange for parentCategoryID given db:thisDB
		set thePK to query db thisDB sql string "select max(ID) from " & tableName & " where ID between " & startValue & " and " & endValue & " and ID % " & x & " = 0"
		set thePK to the first item of the first item of thePK
		doOBLog of OBUtility for "the largest ID in the given range was " & thePK given logType:"debug"
		if thePK is missing value then -- this will be the first ID/subcategory in this category
			set theNewPK to startValue
		else -- some subcategories already exist and we want to get the next available ID within this subcategory range
			set theNewPK to nextIDAtSameLevel for thePK
		end if -- subcategories already exist
	end if -- there's no parent category
	doOBLog of OBUtility for "the new PK will be " & theNewPK given logType:"debug"
	return theNewPK
end newPK

on removeTrailingZeros from n
	doOBLog of OBUtility for "removing trailing zeros for " & n given logType:"debug"
	set x to 1 -- to track how many zeros are removed from n
	repeat while (n mod (x * categoryMod)) = 0 and (x * categoryMod) ≤ primaryBaseForAccountCategoryIDs
		set x to x * categoryMod
	end repeat
	-- the first item is the number with zeros removed, the second item is the number of zeros removed
	return {(n / x) as integer, x}
end removeTrailingZeros

on escapeStringForSQL(thisString)
	doOBLog of OBUtility for "escaping the given string for valid sql compatability (string concealed for security)" given logType:"debug"
	set escapedString to ""
	repeat with theCharacter in characters of thisString
		set theCharacter to theCharacter as text
		if theCharacter is "'" then
			set escapedString to escapedString & "'" & theCharacter
		else
			set escapedString to escapedString & theCharacter
		end if
	end repeat
	return escapedString
end escapeStringForSQL

on convertInitiallySelectedRows from thisList given tableData:tableData
	(*
Myriad Tables Lib's make table command takes an initially selected rows parameter
but it is a list of integers representing the index of the row to be selected
whereas the input we have will be a list of integers representing the account ID to be selected
so we'll need to look at which row contains that account ID and return the index of that row
*)
	(*
this is a really dumb, inefficient and non-scalable way of solving this problem
but for now it's all I got so let's see how it goes and come up with a better idea if and when we can
*)
	doOBLog of OBUtility for "converting list of account IDs into a list of indexes" given logType:"debug"
	set initiallySelectedRows to {}
	repeat with i from 1 to count of tableData
		-- tableData is a list of list where the second item (i.e. column 2) in each list item (i.e. row) is the account ID
		if thisList contains item 2 of item i of tableData then set the end of initiallySelectedRows to i
	end repeat
	return initiallySelectedRows
end convertInitiallySelectedRows

(* #todo:

• function to delete categories
• selecting a category will display any child categories and a button to "Choose " & categoryName and another button to add a subcategory, if supported

*)