
select r.name,c.Description, c.*
  FROM [ReportServer].[dbo].[Subscriptions] c
  LEFT JOIN [ReportServer].[dbo].[Catalog] r  ON c.[Report_OID] = r.ItemID
  LEFT JOIN [ReportServer].[dbo].[Users] u ON c.[OwnerID] = u.UserID
  where 1=1
  --and r.name like 'CMDB_Data' --report name
  and c.description LIKE '%Weekly_report%' -- subscription description
  --and c.SubscriptionID='' -- subscription id