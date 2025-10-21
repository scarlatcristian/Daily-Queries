---------------------------------------------FIND REPORT ID-------------------------------------------


select r.name, c.*

  FROM [ReportServer].[dbo].[Subscriptions] c

  LEFT JOIN [ReportServer].[dbo].[Catalog] r  ON c.[Report_OID] = r.ItemID

  LEFT JOIN [ReportServer].[dbo].[Users] u ON c.[OwnerID] = u.UserID

  where r.name like 'Facturatievoorstel Vlaamse Overheid - PO'
  ORDER BY Description