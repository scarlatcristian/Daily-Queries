USE ReportServer; 
GO

SELECT 
    s.SubscriptionID,
    c.Name AS ReportName,
    c.Path AS ReportPath,
    s.Description AS SubscriptionDescription,
    s.LastStatus,
    s.EventType,
    s.DeliveryExtension,
    s.LastRunTime,
    u.UserName AS Owner,
    s.ModifiedDate
FROM Subscriptions s
JOIN Catalog c ON s.Report_OID = c.ItemID
JOIN Users u ON s.OwnerID = u.UserID
ORDER BY c.Path, c.Name;
