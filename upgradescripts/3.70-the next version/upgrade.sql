﻿--upgrade scripts from nopCommerce 3.70 to next version

--new locale resources
declare @resources xml
--a resource will be deleted if its value is empty
set @resources='
<Language>
  <LocaleResource Name="Admin.Configuration.Settings.Forums.NotifyAboutPrivateMessages.Hint">
    <Value>Indicates whether a customer should be notified by email about new private messages.</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Configuration.Settings.ShoppingCart.AllowCartItemEditing.Hint">
    <Value>Check to allow customers to edit items already placed in the cart or wishlist. It could be useful when your products have attributes or any other fields entered by a customer.</Value>
  </LocaleResource>
  <LocaleResource Name="ShoppingCart.AddToWishlist.Update">
    <Value>Update</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Catalog.Products.ProductAttributes.Attributes.Values.Fields.Picture.Hint">
    <Value>Choose a picture associated to this attribute value. This picture will replace the main product image when this product attribute value is clicked (selected)</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Catalog.Products.ProductAttributes.Attributes.Values.Fields.ImageSquaresPicture">
    <Value>Square picture</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Catalog.Products.ProductAttributes.Attributes.Values.Fields.ImageSquaresPicture.Hint">
    <Value>Upload a picture to be used with the image squares attribute control</Value>
  </LocaleResource>
  <LocaleResource Name="ActivityLog.AddNewTopic">
    <Value>Added a new topic (''{0}'')</Value>
  </LocaleResource>
  <LocaleResource Name="ActivityLog.EditTopic">
    <Value>Edited a topic (''{0}'')</Value>
  </LocaleResource>
  <LocaleResource Name="ActivityLog.DeleteTopic">
    <Value>Deleted a topic (''{0}'')</Value>
  </LocaleResource>
  <LocaleResource Name="ActivityLog.DeleteOrder">
    <Value>Deleted an order (ID = {0})</Value>
  </LocaleResource>
  <LocaleResource Name="ActivityLog.EditOrder">
    <Value>Edited an order (ID = {0}). See order notes for details</Value>
  </LocaleResource>
    <LocaleResource Name="Plugins.DiscountRules.HasAllProducts.Fields.Products">
    <Value>Restricted products [and quantity range]</Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.DiscountRules.HasOneProduct.Fields.Products">
    <Value>Restricted products [and quantity range]</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Configuration.Settings.RewardPoints.PageSize">
    <Value>Page size</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Configuration.Settings.RewardPoints.PageSize.Hint">
    <Value>Page size is for history of reward points on my account page</Value>
  </LocaleResource>
</Language>
'

CREATE TABLE #LocaleStringResourceTmp
	(
		[ResourceName] [nvarchar](200) NOT NULL,
		[ResourceValue] [nvarchar](max) NOT NULL
	)

INSERT INTO #LocaleStringResourceTmp (ResourceName, ResourceValue)
SELECT	nref.value('@Name', 'nvarchar(200)'), nref.value('Value[1]', 'nvarchar(MAX)')
FROM	@resources.nodes('//Language/LocaleResource') AS R(nref)

--do it for each existing language
DECLARE @ExistingLanguageID int
DECLARE cur_existinglanguage CURSOR FOR
SELECT [ID]
FROM [Language]
OPEN cur_existinglanguage
FETCH NEXT FROM cur_existinglanguage INTO @ExistingLanguageID
WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @ResourceName nvarchar(200)
	DECLARE @ResourceValue nvarchar(MAX)
	DECLARE cur_localeresource CURSOR FOR
	SELECT ResourceName, ResourceValue
	FROM #LocaleStringResourceTmp
	OPEN cur_localeresource
	FETCH NEXT FROM cur_localeresource INTO @ResourceName, @ResourceValue
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (EXISTS (SELECT 1 FROM [LocaleStringResource] WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName))
		BEGIN
			UPDATE [LocaleStringResource]
			SET [ResourceValue]=@ResourceValue
			WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName
		END
		ELSE 
		BEGIN
			INSERT INTO [LocaleStringResource]
			(
				[LanguageId],
				[ResourceName],
				[ResourceValue]
			)
			VALUES
			(
				@ExistingLanguageID,
				@ResourceName,
				@ResourceValue
			)
		END
		
		IF (@ResourceValue is null or @ResourceValue = '')
		BEGIN
			DELETE [LocaleStringResource]
			WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName
		END
		
		FETCH NEXT FROM cur_localeresource INTO @ResourceName, @ResourceValue
	END
	CLOSE cur_localeresource
	DEALLOCATE cur_localeresource


	--fetch next language identifier
	FETCH NEXT FROM cur_existinglanguage INTO @ExistingLanguageID
END
CLOSE cur_existinglanguage
DEALLOCATE cur_existinglanguage

DROP TABLE #LocaleStringResourceTmp
GO



--new column
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=object_id('[ProductAttributeValue]') and NAME='ImageSquaresPictureId')
BEGIN
	ALTER TABLE [ProductAttributeValue]
	ADD [ImageSquaresPictureId] int NULL
END
GO

UPDATE [ProductAttributeValue]
SET [ImageSquaresPictureId] = 0
WHERE [ImageSquaresPictureId] IS NULL
GO

ALTER TABLE [ProductAttributeValue] ALTER COLUMN [ImageSquaresPictureId] int NOT NULL
GO


--new setting
IF NOT EXISTS (SELECT 1 FROM [Setting] WHERE [name] = N'mediasettings.imagesquarepicturesize')
BEGIN
	INSERT [Setting] ([Name], [Value], [StoreId])
	VALUES (N'mediasettings.imagesquarepicturesize', N'32', 0)
END
GO

--new activity types
IF NOT EXISTS (SELECT 1 FROM [ActivityLogType] WHERE [SystemKeyword] = N'AddNewTopic')
BEGIN
	INSERT [ActivityLogType] ([SystemKeyword], [Name], [Enabled])
	VALUES (N'AddNewTopic', N'Add a new topic', N'true')
END
GO

IF NOT EXISTS (SELECT 1 FROM [ActivityLogType] WHERE [SystemKeyword] = N'DeleteTopic')
BEGIN
	INSERT [ActivityLogType] ([SystemKeyword], [Name], [Enabled])
	VALUES (N'DeleteTopic', N'Delete a topic', N'true')
END
GO

IF NOT EXISTS (SELECT 1 FROM [ActivityLogType] WHERE [SystemKeyword] = N'EditTopic')
BEGIN
	INSERT [ActivityLogType] ([SystemKeyword], [Name], [Enabled])
	VALUES (N'EditTopic', N'Edit a topic', N'true')
END
GO

IF NOT EXISTS (SELECT 1 FROM [ActivityLogType] WHERE [SystemKeyword] = N'DeleteOrder')
BEGIN
	INSERT [ActivityLogType] ([SystemKeyword], [Name], [Enabled])
	VALUES (N'DeleteOrder', N'Delete an order', N'true')
END
GO

IF NOT EXISTS (SELECT 1 FROM [ActivityLogType] WHERE [SystemKeyword] = N'EditOrder')
BEGIN
	INSERT [ActivityLogType] ([SystemKeyword], [Name], [Enabled])
	VALUES (N'EditOrder', N'Edit an order', N'true')
END
GO

--new setting
IF NOT EXISTS (SELECT 1 FROM [Setting] WHERE [name] = N'rewardpointssettings.pagesize')
BEGIN
	INSERT [Setting] ([Name], [Value], [StoreId])
	VALUES (N'rewardpointssettings.pagesize', N'10', 0)
END
GO