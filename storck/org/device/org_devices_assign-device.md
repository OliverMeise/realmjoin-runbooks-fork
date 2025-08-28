## Assign Device Script

This script assigns a device to a specific location and purpose by updating its extension attributes in Entra ID.

### Purpose
Ensures devices receive the correct policies in Intune by setting location and purpose attributes.

### Usage
Run the script with the following parameters:

- `purpose`: Purpose of the device (e.g., OfficeDevice, SpecialDevice)
- `location`: Device location (e.g., Berlin, Chicago)
- `device`: Device serial number
- `purposeType`: (Optional) Purpose type if device is a special device
- `CallerName`: Name of the caller (for auditing)

### Required Microsoft Graph Permissions
- Device.Read.All
- Device.ReadWrite.All (for extensionAttribute modifications)

Role: Cloud device administrator
